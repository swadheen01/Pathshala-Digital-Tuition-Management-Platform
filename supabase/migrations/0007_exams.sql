-- Pathshala — Exams migration
-- Run after 0001–0006

-- ========================================
-- exams (spec §2.7)
-- ========================================
create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  title text not null,
  max_marks numeric(6, 2) not null check (max_marks > 0),
  exam_date date,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

-- ========================================
-- exam_scores (spec §2.7)
-- ========================================
create table if not exists public.exam_scores (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  marks_obtained numeric(6, 2) not null check (marks_obtained >= 0),
  created_at timestamptz not null default now(),
  unique (exam_id, student_id)
);

-- ========================================
-- Row Level Security
-- ========================================
alter table public.exams enable row level security;
alter table public.exam_scores enable row level security;

create policy "exams_all_teacher"
  on public.exams for all
  using (exists (select 1 from public.rooms r where r.id = exams.room_id and r.teacher_id = auth.uid()))
  with check (exists (select 1 from public.rooms r where r.id = exams.room_id and r.teacher_id = auth.uid()));

create policy "exams_select_room_student"
  on public.exams for select
  using (
    exists (select 1 from public.room_members rm where rm.room_id = exams.room_id and rm.student_id = auth.uid())
  );

create policy "exam_scores_all_teacher"
  on public.exam_scores for all
  using (
    exists (
      select 1 from public.exams e
      join public.rooms r on r.id = e.room_id
      where e.id = exam_scores.exam_id and r.teacher_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.exams e
      join public.rooms r on r.id = e.room_id
      where e.id = exam_scores.exam_id and r.teacher_id = auth.uid()
    )
  );

create policy "exam_scores_select_own_student"
  on public.exam_scores for select
  using (auth.uid() = student_id);

-- ========================================
-- leaderboard RPC: only meaningful when room.leaderboard_enabled = true.
-- The Flutter service checks that flag before calling this so students
-- never see rankings the teacher has hidden (spec §2.7).
-- ========================================
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
    es.student_id,
    p.full_name as student_name,
    sum(es.marks_obtained) as total_marks_obtained,
    sum(e.max_marks) as total_max_marks
  from public.exam_scores es
  join public.exams e on e.id = es.exam_id
  join public.profiles p on p.id = es.student_id
  where e.room_id = p_room_id
  group by es.student_id, p.full_name
  order by sum(es.marks_obtained) / sum(e.max_marks) desc;
$$;
