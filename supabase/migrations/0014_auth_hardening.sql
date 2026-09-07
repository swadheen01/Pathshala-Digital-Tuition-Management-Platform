-- Pathshala — Auth hardening
--
-- Fixes the "every signup becomes a student" and "teacher account not
-- reachable" problems at the database layer, and makes the first-login
-- profile bootstrap resilient for OAuth (Google) users who arrive with
-- no `role` in their metadata.
--
-- Safe to run more than once.

-- ---------------------------------------------------------------------------
-- 1. Make sure the completion flag exists (idempotent with 0013).
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists profile_completed boolean not null default false;

-- ---------------------------------------------------------------------------
-- 2. Robust new-user bootstrap trigger.
--    - Pulls a display name from any of the common metadata keys Google /
--      email signup provide (`full_name`, `name`), falling back to the local
--      part of the email so `full_name` is never an empty string.
--    - Honours an explicit teacher/student choice passed in metadata; every
--      other value (including none, i.e. Google) falls back to 'student' but
--      leaves `profile_completed = false` so the app forces role selection.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  resolved_name text;
  resolved_role user_role;
begin
  resolved_name := coalesce(
    nullif(meta->>'full_name', ''),
    nullif(meta->>'name', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Pathshala user'
  );

  resolved_role := case
    when meta->>'role' in ('teacher', 'student') then (meta->>'role')::user_role
    else 'student'::user_role
  end;

  insert into public.profiles (id, full_name, role, email, phone, profile_completed)
  values (
    new.id,
    resolved_name,
    resolved_role,
    new.email,
    new.phone,
    false
  )
  on conflict (id) do update
    set email = excluded.email,
        -- keep a name we already have; only fill a blank one
        full_name = case
          when coalesce(nullif(public.profiles.full_name, ''), '') = ''
            then excluded.full_name
          else public.profiles.full_name
        end;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 3. Lightweight RPC the app calls from the role-selection screen so a
--    freshly-created (Google) user can persist their chosen role before the
--    full profile form. Runs as the caller; RLS `profiles_update_own` still
--    applies, and we hard-scope it to auth.uid() regardless.
-- ---------------------------------------------------------------------------
create or replace function public.set_my_role(new_role user_role)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if new_role not in ('teacher', 'student') then
    raise exception 'role % is not self-selectable', new_role;
  end if;

  update public.profiles
     set role = new_role
   where id = auth.uid();

  if not found then
    insert into public.profiles (id, full_name, role, profile_completed)
    values (auth.uid(), 'Pathshala user', new_role, false);
  end if;
end;
$$;

revoke all on function public.set_my_role(user_role) from public;
grant execute on function public.set_my_role(user_role) to authenticated;
