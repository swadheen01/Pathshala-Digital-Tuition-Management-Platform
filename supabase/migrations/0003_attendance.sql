-- Pathshala — Attendance migration
-- Run after 0001_init.sql and 0002_rooms.sql

-- ========================================
-- attendance: one row per student per room per date (spec §2.3)
-- ========================================
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  present boolean not null,
  marked_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (room_id, student_id, date)
);

create index if not exists idx_attendance_room_date
  on public.attendance (room_id, date);

-- ========================================
-- Enforce: date's weekday must be in the room's class_days (spec §2.5)
-- Postgres date-to-weekday: extract(isodow) gives 1=Mon..7=Sun, but our
-- app uses 1=Sun..7=Sat (matches room_model.dart / Dart's convention
-- loosely) — convert explicitly to avoid off-by-one bugs.
-- ========================================
create or replace function public.check_attendance_class_day()
returns trigger as $$
declare
  v_class_days smallint[];
  v_weekday smallint; -- 1=Sun..7=Sat
begin
  select class_days into v_class_days from public.rooms where id = new.room_id;

  -- extract(dow) in Postgres returns 0=Sun..6=Sat; shift to 1..7.
  v_weekday := extract(dow from new.date)::smallint + 1;

  if not (v_weekday = any(v_class_days)) then
    raise exception 'Attendance date % is not a configured class day for this room', new.date;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger attendance_check_class_day
  before insert or update on public.attendance
  for each row execute function public.check_attendance_class_day();

-- ========================================
-- Row Level Security
-- ========================================
alter table public.attendance enable row level security;

-- Teachers manage attendance for rooms they own.
create policy "attendance_all_teacher"
  on public.attendance for all
  using (
    exists (
      select 1 from public.rooms r
      where r.id = attendance.room_id and r.teacher_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.rooms r
      where r.id = attendance.room_id and r.teacher_id = auth.uid()
    )
  );

-- Students can read their own attendance rows.
create policy "attendance_select_own_student"
  on public.attendance for select
  using (auth.uid() = student_id);

-- ========================================
-- attendance_summary RPC: percentage per student in a room (spec §2.3)
-- ========================================
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
    a.student_id,
    p.full_name as student_name,
    count(*) as total_days,
    count(*) filter (where a.present) as present_days
  from public.attendance a
  join public.profiles p on p.id = a.student_id
  where a.room_id = p_room_id
  group by a.student_id, p.full_name;
$$;
