-- Fix recursive RLS policies between rooms and room_members.
--
-- rooms_select_member_student reads room_members, while the nested rooms
-- relationship query causes room_members policies to read rooms again.
-- SECURITY DEFINER helpers perform these membership checks without re-entering
-- either table's RLS policies.

create or replace function public.is_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.room_members
    where room_id = p_room_id
      and student_id = auth.uid()
  );
$$;

create or replace function public.is_room_teacher(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.rooms
    where id = p_room_id
      and teacher_id = auth.uid()
  );
$$;

create or replace function public.is_parent_of_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.parent_links
    where student_id = p_student_id
      and parent_id = auth.uid()
  );
$$;

create or replace function public.is_parent_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.room_members rm
    join public.parent_links pl on pl.student_id = rm.student_id
    where rm.room_id = p_room_id
      and pl.parent_id = auth.uid()
  );
$$;

revoke all on function public.is_room_member(uuid) from public;
revoke all on function public.is_room_teacher(uuid) from public;
revoke all on function public.is_parent_of_student(uuid) from public;
revoke all on function public.is_parent_room_member(uuid) from public;
grant execute on function public.is_room_member(uuid) to authenticated;
grant execute on function public.is_room_teacher(uuid) to authenticated;
grant execute on function public.is_parent_of_student(uuid) to authenticated;
grant execute on function public.is_parent_room_member(uuid) to authenticated;

drop policy if exists "rooms_select_member_student" on public.rooms;
create policy "rooms_select_member_student"
  on public.rooms for select
  using (public.is_room_member(id));

drop policy if exists "room_members_select_teacher" on public.room_members;
create policy "room_members_select_teacher"
  on public.room_members for select
  using (public.is_room_teacher(room_id));

drop policy if exists "room_members_delete_teacher" on public.room_members;
create policy "room_members_delete_teacher"
  on public.room_members for delete
  using (public.is_room_teacher(room_id));

drop policy if exists "room_members_select_parent" on public.room_members;
create policy "room_members_select_parent"
  on public.room_members for select
  using (public.is_parent_of_student(student_id));

drop policy if exists "rooms_select_parent" on public.rooms;
create policy "rooms_select_parent"
  on public.rooms for select
  using (public.is_parent_room_member(id));
