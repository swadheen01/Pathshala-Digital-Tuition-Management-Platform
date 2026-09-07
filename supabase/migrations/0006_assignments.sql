-- Pathshala — Assignments migration
-- Run after 0001–0005

-- ========================================
-- assignments (spec §2.6)
-- ========================================
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  title text not null,
  description text,
  due_date timestamptz not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_assignments_room
  on public.assignments (room_id, due_date);

-- ========================================
-- submissions (spec §2.6: text, file, or image)
-- ========================================
create type submission_type as enum ('text', 'file', 'image');

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  type submission_type not null default 'text',
  text_content text,
  file_url text,
  grade text,
  feedback text,
  submitted_at timestamptz not null default now(),
  graded_at timestamptz,
  unique (assignment_id, student_id) -- one submission per student per assignment
);

-- ========================================
-- Row Level Security
-- ========================================
alter table public.assignments enable row level security;
alter table public.submissions enable row level security;

-- Assignments: teacher manages their own room's assignments; students
-- in the room can read them.
create policy "assignments_all_teacher"
  on public.assignments for all
  using (
    exists (select 1 from public.rooms r where r.id = assignments.room_id and r.teacher_id = auth.uid())
  )
  with check (
    exists (select 1 from public.rooms r where r.id = assignments.room_id and r.teacher_id = auth.uid())
  );

create policy "assignments_select_room_student"
  on public.assignments for select
  using (
    exists (
      select 1 from public.room_members rm
      where rm.room_id = assignments.room_id and rm.student_id = auth.uid()
    )
  );

-- Submissions: student manages their own; teacher can read/grade
-- submissions for assignments in rooms they own.
create policy "submissions_all_own_student"
  on public.submissions for all
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

create policy "submissions_select_teacher"
  on public.submissions for select
  using (
    exists (
      select 1 from public.assignments a
      join public.rooms r on r.id = a.room_id
      where a.id = submissions.assignment_id and r.teacher_id = auth.uid()
    )
  );

-- Teacher can update grade/feedback only (not the student's actual answer).
-- Enforced at the application layer by only ever sending {grade, feedback,
-- graded_at} in the update payload from assignment_service.dart.
create policy "submissions_update_teacher_grading"
  on public.submissions for update
  using (
    exists (
      select 1 from public.assignments a
      join public.rooms r on r.id = a.room_id
      where a.id = submissions.assignment_id and r.teacher_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.assignments a
      join public.rooms r on r.id = a.room_id
      where a.id = submissions.assignment_id and r.teacher_id = auth.uid()
    )
  );
