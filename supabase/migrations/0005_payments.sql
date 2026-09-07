-- Pathshala — Payments migration
-- Run after 0001–0004

-- Monthly fee is per-student-per-room (teacher may charge differently
-- per student), so it lives on room_members rather than rooms.
alter table public.room_members
  add column if not exists monthly_fee numeric(10, 2) not null default 0;

-- ========================================
-- payments (spec §2.4 — teacher-only feature)
-- ========================================
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(10, 2) not null check (amount > 0),
  paid_on date not null,
  for_month text, -- e.g. '2026-07'
  note text,
  recorded_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_payments_room_student
  on public.payments (room_id, student_id);

-- ========================================
-- Row Level Security — teacher-only, per spec §2.4
-- ========================================
alter table public.payments enable row level security;

create policy "payments_all_teacher"
  on public.payments for all
  using (
    exists (select 1 from public.rooms r where r.id = payments.room_id and r.teacher_id = auth.uid())
  )
  with check (
    exists (select 1 from public.rooms r where r.id = payments.room_id and r.teacher_id = auth.uid())
  );

-- Parents (spec §2.8) and students can view payments for accountability,
-- but cannot insert/update/delete (read-only, enforced by using-only policy).
create policy "payments_select_own_student"
  on public.payments for select
  using (auth.uid() = student_id);

-- NOTE: A "parents can view their linked child's payments" policy will
-- be added in the Parent-access migration (once parent_links exists),
-- since Postgres requires the referenced table to exist at
-- CREATE POLICY time.

-- ========================================
-- dues_summary RPC (spec §2.4)
-- ========================================
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
    rm.student_id,
    p.full_name as student_name,
    rm.monthly_fee,
    coalesce(sum(pay.amount), 0) as total_paid,
    greatest(
      1,
      (extract(year from age(now(), rm.joined_at)) * 12 +
       extract(month from age(now(), rm.joined_at)))::int
    ) as months_since_joining
  from public.room_members rm
  join public.profiles p on p.id = rm.student_id
  left join public.payments pay on pay.student_id = rm.student_id and pay.room_id = rm.room_id
  where rm.room_id = p_room_id
  group by rm.student_id, p.full_name, rm.monthly_fee, rm.joined_at;
$$;
