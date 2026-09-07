-- Pathshala — Rooms migration
-- Run after 0001_init.sql

-- ========================================
-- rooms: created by teachers (spec §2.1)
-- ========================================
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  subject text,
  description text,
  join_code text not null unique,        -- students use this to join (§2.1)
  chat_enabled boolean not null default false,       -- §2.2
  leaderboard_enabled boolean not null default false, -- §2.7
  class_days smallint[] not null default '{}',       -- 1=Sun..7=Sat (§2.5)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger rooms_set_updated_at
  before update on public.rooms
  for each row execute function public.set_updated_at();

-- ========================================
-- room_members: students who joined a room (spec §2.1)
-- ========================================
create table if not exists public.room_members (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  roll_number text,
  joined_at timestamptz not null default now(),
  unique (room_id, student_id)
);

-- ========================================
-- Row Level Security
-- ========================================
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;

-- Teachers manage their own rooms.
create policy "rooms_select_own_teacher"
  on public.rooms for select
  using (auth.uid() = teacher_id);

create policy "rooms_insert_teacher"
  on public.rooms for insert
  with check (auth.uid() = teacher_id);

create policy "rooms_update_own_teacher"
  on public.rooms for update
  using (auth.uid() = teacher_id)
  with check (auth.uid() = teacher_id);

create policy "rooms_delete_own_teacher"
  on public.rooms for delete
  using (auth.uid() = teacher_id);

-- Students can see rooms they are a member of.
create policy "rooms_select_member_student"
  on public.rooms for select
  using (
    exists (
      select 1 from public.room_members rm
      where rm.room_id = rooms.id and rm.student_id = auth.uid()
    )
  );

-- Any authenticated user can look up a room by join_code in order to
-- join it (join flow needs to read name/id before membership exists).
-- Kept narrow: only non-sensitive columns are useful here, but Postgres
-- RLS is row-level not column-level, so restrict via a dedicated RPC
-- instead of a broad policy. See join_room() function below.

-- room_members: students see their own memberships; teachers see
-- memberships for rooms they own.
create policy "room_members_select_own_student"
  on public.room_members for select
  using (auth.uid() = student_id);

create policy "room_members_select_teacher"
  on public.room_members for select
  using (
    exists (
      select 1 from public.rooms r
      where r.id = room_members.room_id and r.teacher_id = auth.uid()
    )
  );

create policy "room_members_delete_teacher"
  on public.room_members for delete
  using (
    exists (
      select 1 from public.rooms r
      where r.id = room_members.room_id and r.teacher_id = auth.uid()
    )
  );

-- ========================================
-- join_room RPC: looks up a room by code and inserts membership
-- atomically, without exposing a broad "anyone can read any room" policy.
-- ========================================
create or replace function public.join_room(p_join_code text, p_roll_number text default null)
returns public.rooms
language plpgsql
security definer
as $$
declare
  v_room public.rooms;
begin
  select * into v_room from public.rooms where join_code = p_join_code;

  if v_room.id is null then
    raise exception 'Invalid join code';
  end if;

  insert into public.room_members (room_id, student_id, roll_number)
  values (v_room.id, auth.uid(), p_roll_number)
  on conflict (room_id, student_id) do nothing;

  return v_room;
end;
$$;
