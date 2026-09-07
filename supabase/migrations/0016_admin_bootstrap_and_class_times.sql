-- Pathshala — bootstrap admin + class start/end times + home-screen RPCs
--
-- Safe to run more than once.

-- ===========================================================================
-- 1. Bootstrap administrator
--    contactwith.swadheen@gmail.com is always an admin. Applied to any
--    existing row now, and enforced for future signups via the trigger.
-- ===========================================================================
create or replace function public.is_bootstrap_admin(p_email text)
returns boolean
language sql
immutable
as $$
  select lower(coalesce(p_email, '')) = 'contactwith.swadheen@gmail.com';
$$;

update public.profiles
   set role = 'admin', profile_completed = true
 where public.is_bootstrap_admin(email);

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
  is_admin boolean := public.is_bootstrap_admin(new.email);
begin
  resolved_name := coalesce(
    nullif(meta->>'full_name', ''),
    nullif(meta->>'name', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Pathshala user'
  );

  resolved_role := case
    when is_admin then 'admin'::user_role
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
    is_admin -- admins skip onboarding; everyone else completes it
  )
  on conflict (id) do update
    set email = excluded.email,
        role = case when is_admin then 'admin'::user_role else public.profiles.role end,
        profile_completed = public.profiles.profile_completed or is_admin,
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

-- Keep an existing signed-in admin locked to the admin role even if the
-- app ever tries to downgrade them.
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
  if exists (
    select 1 from public.profiles
    where id = auth.uid() and public.is_bootstrap_admin(email)
  ) then
    return; -- no-op: the bootstrap admin cannot change their own role
  end if;
  if new_role not in ('teacher', 'student') then
    raise exception 'role % is not self-selectable', new_role;
  end if;

  update public.profiles set role = new_role where id = auth.uid();
  if not found then
    insert into public.profiles (id, full_name, role, profile_completed)
    values (auth.uid(), 'Pathshala user', new_role, false);
  end if;
end;
$$;
revoke all on function public.set_my_role(user_role) from public;
grant execute on function public.set_my_role(user_role) to authenticated;

-- ===========================================================================
-- 2. Class start / end times (spec §2.5 — "which class is on now / next")
-- ===========================================================================
alter table public.rooms
  add column if not exists class_start_time time,
  add column if not exists class_end_time time;

-- ===========================================================================
-- 3. Home-screen aggregates
-- ===========================================================================

-- Student: attendance % per room they're in.
create or replace function public.get_my_room_attendance()
returns table (
  room_id uuid,
  room_name text,
  subject text,
  present bigint,
  total bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    r.id,
    r.name,
    r.subject,
    count(a.id) filter (where a.present) as present,
    count(a.id) as total
  from public.room_members rm
  join public.rooms r on r.id = rm.room_id
  left join public.attendance a
    on a.room_id = rm.room_id and a.student_id = rm.ref_id
  where rm.student_id = auth.uid()
  group by r.id, r.name, r.subject
  order by r.name;
$$;
revoke all on function public.get_my_room_attendance() from public;
grant execute on function public.get_my_room_attendance() to authenticated;

-- Teacher: one payment snapshot across every room they own.
--   paid_up      – students with nothing outstanding
--   due          – students with an outstanding balance under 2 months
--   overdue      – students 2+ months behind
--   collected_30 – amount received in the last 30 days
create or replace function public.get_teacher_payment_overview()
returns table (
  student_count bigint,
  paid_up bigint,
  due bigint,
  overdue bigint,
  outstanding numeric,
  collected_30 numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with mine as (
    select id from public.rooms where teacher_id = auth.uid()
  ),
  per_student as (
    select
      rm.ref_id,
      rm.monthly_fee,
      greatest(1, (extract(year from age(now(), rm.joined_at)) * 12 +
        extract(month from age(now(), rm.joined_at)))::int) as months,
      coalesce(sum(pay.amount), 0) as paid
    from public.room_members rm
    left join public.payments pay
      on pay.student_id = rm.ref_id and pay.room_id = rm.room_id
    where rm.room_id in (select id from mine)
    group by rm.ref_id, rm.monthly_fee, rm.joined_at
  )
  select
    count(*) as student_count,
    count(*) filter (where monthly_fee = 0 or paid >= monthly_fee * months) as paid_up,
    count(*) filter (
      where monthly_fee > 0 and paid < monthly_fee * months
        and (monthly_fee * months - paid) < monthly_fee * 2
    ) as due,
    count(*) filter (
      where monthly_fee > 0 and (monthly_fee * months - paid) >= monthly_fee * 2
    ) as overdue,
    coalesce(sum(greatest(monthly_fee * months - paid, 0)), 0) as outstanding,
    (
      select coalesce(sum(p.amount), 0) from public.payments p
      where p.room_id in (select id from mine)
        and p.paid_on >= (current_date - interval '30 days')
    ) as collected_30
  from per_student;
$$;
revoke all on function public.get_teacher_payment_overview() from public;
grant execute on function public.get_teacher_payment_overview() to authenticated;
