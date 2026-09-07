-- Pathshala — Name-only roster students + join-and-claim flow
--
-- WHAT THIS ADDS
-- 1. A teacher can add a student to a room by name alone (no phone / no
--    account). Those rows live in `room_members` with `student_id IS NULL`.
-- 2. Attendance / payments / exam scores work for those students too: the
--    `student_id` column on those three tables is repurposed to hold a
--    member "ref id" = COALESCE(room_members.student_id, room_members.id).
--    For a real user that's still their profile id (nothing changes); for a
--    name-only student it's the roster row's id.
-- 3. When a student joins by code and their typed name matches an unclaimed
--    roster row, they can request to be linked to it. The teacher approves,
--    which sets `student_id` on that roster row and moves any history over.
--
-- Safe to run more than once.

-- ===========================================================================
-- 1. room_members: allow name-only entries
-- ===========================================================================
alter table public.room_members
  add column if not exists full_name text,
  add column if not exists phone text,
  add column if not exists email text;

alter table public.room_members
  alter column student_id drop not null;

-- Stable per-member identity used by attendance / payments / exam_scores.
alter table public.room_members
  add column if not exists ref_id uuid
  generated always as (coalesce(student_id, id)) stored;

-- ref_id is unique *within a room* (a real student may sit in several
-- rooms, so it is NOT globally unique).
create unique index if not exists idx_room_members_room_ref
  on public.room_members (room_id, ref_id);

-- Helper: does the current user teach this room? (SECURITY DEFINER so it
-- can be used inside room_members policies without RLS recursion.)
create or replace function public.teaches_room(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rooms
    where id = p_room_id and teacher_id = auth.uid()
  );
$$;
revoke all on function public.teaches_room(uuid) from public;
grant execute on function public.teaches_room(uuid) to authenticated;

-- Teachers can now add / edit roster rows directly (previously only the
-- join_room SECURITY DEFINER function could insert).
drop policy if exists "room_members_insert_teacher" on public.room_members;
create policy "room_members_insert_teacher"
  on public.room_members for insert
  with check (public.teaches_room(room_id));

drop policy if exists "room_members_update_teacher" on public.room_members;
create policy "room_members_update_teacher"
  on public.room_members for update
  using (public.teaches_room(room_id))
  with check (public.teaches_room(room_id));

-- ===========================================================================
-- 2. Repoint attendance / payments / exam_scores off the profiles FK so a
--    roster-row ref id (not present in profiles) is a valid subject.
--    The columns and their names stay the same — only the FK is dropped.
-- ===========================================================================
alter table public.attendance   drop constraint if exists attendance_student_id_fkey;
alter table public.payments     drop constraint if exists payments_student_id_fkey;
alter table public.exam_scores  drop constraint if exists exam_scores_student_id_fkey;

-- ===========================================================================
-- 3. Summary RPCs — resolve names via room_members, include every roster
--    member (even with zero records), and key on ref_id.
-- ===========================================================================
create or replace function public.get_attendance_summary(p_room_id uuid)
returns table (
  student_id uuid,
  student_name text,
  total_days bigint,
  present_days bigint
)
language sql
stable
as $$
  select
    rm.ref_id as student_id,
    coalesce(nullif(p.full_name, ''), rm.full_name, 'Unknown') as student_name,
    count(a.id) as total_days,
    count(a.id) filter (where a.present) as present_days
  from public.room_members rm
  left join public.profiles p on p.id = rm.student_id
  left join public.attendance a
    on a.room_id = rm.room_id and a.student_id = rm.ref_id
  where rm.room_id = p_room_id
  group by rm.ref_id, coalesce(nullif(p.full_name, ''), rm.full_name, 'Unknown');
$$;

create or replace function public.get_dues_summary(p_room_id uuid)
returns table (
  student_id uuid,
  student_name text,
  monthly_fee numeric,
  total_paid numeric,
  months_since_joining int
)
language sql
stable
as $$
  select
    rm.ref_id as student_id,
    coalesce(nullif(p.full_name, ''), rm.full_name, 'Unknown') as student_name,
    rm.monthly_fee,
    coalesce(sum(pay.amount), 0) as total_paid,
    greatest(
      1,
      (extract(year from age(now(), rm.joined_at)) * 12 +
       extract(month from age(now(), rm.joined_at)))::int
    ) as months_since_joining
  from public.room_members rm
  left join public.profiles p on p.id = rm.student_id
  left join public.payments pay
    on pay.student_id = rm.ref_id and pay.room_id = rm.room_id
  where rm.room_id = p_room_id
  group by rm.ref_id, coalesce(nullif(p.full_name, ''), rm.full_name, 'Unknown'),
           rm.monthly_fee, rm.joined_at;
$$;

create or replace function public.get_leaderboard(p_room_id uuid)
returns table (
  student_id uuid,
  student_name text,
  total_marks_obtained numeric,
  total_max_marks numeric
)
language sql
stable
as $$
  select
    rm.ref_id as student_id,
    coalesce(nullif(p.full_name, ''), rm.full_name, 'Unknown') as student_name,
    sum(es.marks_obtained) as total_marks_obtained,
    sum(e.max_marks) as total_max_marks
  from public.exam_scores es
  join public.exams e on e.id = es.exam_id
  join public.room_members rm on rm.ref_id = es.student_id and rm.room_id = e.room_id
  left join public.profiles p on p.id = rm.student_id
  where e.room_id = p_room_id
  group by rm.ref_id, coalesce(nullif(p.full_name, ''), rm.full_name, 'Unknown')
  having sum(e.max_marks) > 0
  order by sum(es.marks_obtained) / sum(e.max_marks) desc;
$$;

-- ===========================================================================
-- 4. Join requests (claim an unclaimed roster row)
-- ===========================================================================
create table if not exists public.room_join_requests (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  member_id uuid not null references public.room_members(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique (room_id, requester_id)
);

alter table public.room_join_requests enable row level security;

drop policy if exists "rjr_select_requester" on public.room_join_requests;
create policy "rjr_select_requester"
  on public.room_join_requests for select
  using (requester_id = auth.uid());

drop policy if exists "rjr_select_teacher" on public.room_join_requests;
create policy "rjr_select_teacher"
  on public.room_join_requests for select
  using (public.teaches_room(room_id));

drop policy if exists "rjr_insert_requester" on public.room_join_requests;
create policy "rjr_insert_requester"
  on public.room_join_requests for insert
  with check (requester_id = auth.uid());

drop policy if exists "rjr_update_teacher" on public.room_join_requests;
create policy "rjr_update_teacher"
  on public.room_join_requests for update
  using (public.teaches_room(room_id))
  with check (public.teaches_room(room_id));

-- ---------------------------------------------------------------------------
-- 4a. Look up a room by code + list the names still unclaimed, so the
--     join screen can offer "is one of these you?".
-- ---------------------------------------------------------------------------
create or replace function public.find_room_by_code(p_join_code text)
returns table (
  room_id uuid,
  name text,
  subject text,
  unclaimed_names text[]
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
    coalesce(
      array_agg(rm.full_name order by rm.full_name)
        filter (where rm.student_id is null and coalesce(rm.full_name, '') <> ''),
      '{}'
    ) as unclaimed_names
  from public.rooms r
  left join public.room_members rm on rm.room_id = r.id
  where r.join_code = upper(trim(p_join_code))
  group by r.id, r.name, r.subject;
$$;
revoke all on function public.find_room_by_code(text) from public;
grant execute on function public.find_room_by_code(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 4b. Student requests to be linked to a named roster row.
-- ---------------------------------------------------------------------------
create or replace function public.request_room_claim(
  p_join_code text,
  p_full_name text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room public.rooms;
  v_member_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select * into v_room from public.rooms
  where join_code = upper(trim(p_join_code));
  if v_room.id is null then
    raise exception 'Invalid join code';
  end if;

  if exists (
    select 1 from public.room_members
    where room_id = v_room.id and student_id = auth.uid()
  ) then
    raise exception 'You are already in this room';
  end if;

  select id into v_member_id
  from public.room_members
  where room_id = v_room.id
    and student_id is null
    and lower(trim(full_name)) = lower(trim(p_full_name))
  order by joined_at
  limit 1;

  if v_member_id is null then
    raise exception 'No unclaimed student named "%" in this room', p_full_name;
  end if;

  insert into public.room_join_requests (room_id, requester_id, member_id, status)
  values (v_room.id, auth.uid(), v_member_id, 'pending')
  on conflict (room_id, requester_id) do update
    set member_id = excluded.member_id,
        status = 'pending',
        created_at = now(),
        resolved_at = null;

  return v_room.name;
end;
$$;
revoke all on function public.request_room_claim(text, text) from public;
grant execute on function public.request_room_claim(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 4c. Teacher-side: list pending requests with names attached.
-- ---------------------------------------------------------------------------
create or replace function public.get_room_join_requests(p_room_id uuid)
returns table (
  id uuid,
  requester_id uuid,
  requester_name text,
  requester_email text,
  member_id uuid,
  member_name text,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    jr.id,
    jr.requester_id,
    coalesce(rp.full_name, 'Unknown') as requester_name,
    rp.email as requester_email,
    jr.member_id,
    rm.full_name as member_name,
    jr.status,
    jr.created_at
  from public.room_join_requests jr
  join public.room_members rm on rm.id = jr.member_id
  left join public.profiles rp on rp.id = jr.requester_id
  where jr.room_id = p_room_id
    and public.teaches_room(p_room_id)
  order by
    case jr.status when 'pending' then 0 else 1 end,
    jr.created_at desc;
$$;
revoke all on function public.get_room_join_requests(uuid) from public;
grant execute on function public.get_room_join_requests(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4d. Approve: link the roster row to the requester and carry history over.
-- ---------------------------------------------------------------------------
create or replace function public.approve_room_claim(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req public.room_join_requests;
  v_member public.room_members;
  v_old_ref uuid;
begin
  select * into v_req from public.room_join_requests where id = p_request_id;
  if v_req.id is null then
    raise exception 'Request not found';
  end if;
  if not public.teaches_room(v_req.room_id) then
    raise exception 'Not your room';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Request already %', v_req.status;
  end if;

  select * into v_member from public.room_members where id = v_req.member_id;
  if v_member.student_id is not null then
    raise exception 'That student row is already linked to an account';
  end if;

  if exists (
    select 1 from public.room_members
    where room_id = v_req.room_id and student_id = v_req.requester_id
  ) then
    raise exception 'This student already has an account in the room';
  end if;

  v_old_ref := v_member.id; -- ref_id before linking

  update public.room_members
     set student_id = v_req.requester_id
   where id = v_member.id;

  -- Move any history recorded against the placeholder onto the real user.
  update public.attendance
     set student_id = v_req.requester_id
   where student_id = v_old_ref and room_id = v_req.room_id;

  update public.payments
     set student_id = v_req.requester_id
   where student_id = v_old_ref and room_id = v_req.room_id;

  update public.exam_scores
     set student_id = v_req.requester_id
   where student_id = v_old_ref
     and exam_id in (select id from public.exams where room_id = v_req.room_id);

  update public.room_join_requests
     set status = 'approved', resolved_at = now()
   where id = p_request_id;

  -- Any other pending requests for the same now-claimed row are moot.
  update public.room_join_requests
     set status = 'rejected', resolved_at = now()
   where member_id = v_member.id and status = 'pending' and id <> p_request_id;
end;
$$;
revoke all on function public.approve_room_claim(uuid) from public;
grant execute on function public.approve_room_claim(uuid) to authenticated;

create or replace function public.reject_room_claim(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room uuid;
begin
  select room_id into v_room from public.room_join_requests where id = p_request_id;
  if v_room is null then
    raise exception 'Request not found';
  end if;
  if not public.teaches_room(v_room) then
    raise exception 'Not your room';
  end if;

  update public.room_join_requests
     set status = 'rejected', resolved_at = now()
   where id = p_request_id;
end;
$$;
revoke all on function public.reject_room_claim(uuid) from public;
grant execute on function public.reject_room_claim(uuid) to authenticated;
