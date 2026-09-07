-- Track whether a user has completed the one-time role/profile setup.

alter table public.profiles
  add column if not exists profile_completed boolean not null default false;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    case
      when new.raw_user_meta_data->>'role' in ('teacher', 'student')
        then (new.raw_user_meta_data->>'role')::user_role
      else 'student'::user_role
    end,
    new.email,
    new.phone
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
