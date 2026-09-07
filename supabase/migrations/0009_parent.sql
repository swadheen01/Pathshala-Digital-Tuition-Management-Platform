-- Pathshala — Parent Access migration
-- Run after 0001–0008

-- ========================================
-- parent_links: teacher grants a parent read-only access to a student
-- (spec §2.8)
-- ========================================
create table if not exists public.parent_links (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  granted_by uuid not null references public.profiles(id), -- the teacher
  created_at timestamptz not null default now(),
  unique (parent_id, student_id)
);

alter table public.parent_links enable row level security;

-- Teachers grant/revoke links for students in their own rooms.
create policy "parent_links_all_teacher"
  on public.parent_links for all
  using (
    exists (
      select 1 from public.room_members rm
      join public.rooms r on r.id = rm.room_id
      where rm.student_id = parent_links.student_id and r.teacher_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.room_members rm
      join public.rooms r on r.id = rm.room_id
      where rm.student_id = parent_links.student_id and r.teacher_id = auth.uid()
    )
  );

-- Parents see only their own links (to discover which children they're linked to).
create policy "parent_links_select_own_parent"
  on public.parent_links for select
  using (auth.uid() = parent_id);

-- ========================================
-- Extend read access to parents for their linked child's data.
-- Reuses the same tables as the student/teacher views — a parent is
-- just another read-only lens on the same rows (spec §2.8: attendance,
-- dues/payments, performance — no editing rights).
-- ========================================

create policy "attendance_select_parent"
  on public.attendance for select
  using (
    exists (
      select 1 from public.parent_links pl
      where pl.student_id = attendance.student_id and pl.parent_id = auth.uid()
    )
  );

create policy "payments_select_parent"
  on public.payments for select
  using (
    exists (
      select 1 from public.parent_links pl
      where pl.student_id = payments.student_id and pl.parent_id = auth.uid()
    )
  );

create policy "exam_scores_select_parent"
  on public.exam_scores for select
  using (
    exists (
      select 1 from public.parent_links pl
      where pl.student_id = exam_scores.student_id and pl.parent_id = auth.uid()
    )
  );

-- Parents also need to see which rooms their linked child belongs to,
-- so the parent dashboard can list "which room" before drilling into
-- attendance/payments/performance for that room (spec §2.8).
create policy "room_members_select_parent"
  on public.room_members for select
  using (
    exists (
      select 1 from public.parent_links pl
      where pl.student_id = room_members.student_id and pl.parent_id = auth.uid()
    )
  );

create policy "rooms_select_parent"
  on public.rooms for select
  using (
    exists (
      select 1 from public.room_members rm
      join public.parent_links pl on pl.student_id = rm.student_id
      where rm.room_id = rooms.id and pl.parent_id = auth.uid()
    )
  );
