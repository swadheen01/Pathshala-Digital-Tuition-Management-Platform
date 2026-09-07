-- Pathshala — Messaging & Polls migration
-- Run after 0001–0003

-- ========================================
-- messages (spec §2.2)
-- ========================================
create type message_type as enum ('text', 'image', 'poll');

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  type message_type not null default 'text',
  text text,
  image_url text,
  poll_id uuid, -- set when type = 'poll'; FK added after polls table exists
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_room_created
  on public.messages (room_id, created_at);

-- ========================================
-- polls (spec §2.2)
-- ========================================
create table if not exists public.polls (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  question text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.poll_options (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  label text not null
);

create table if not exists public.poll_votes (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  option_id uuid not null references public.poll_options(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (poll_id, student_id) -- one vote per student per poll (§2.2, §3)
);

alter table public.messages
  add constraint messages_poll_id_fkey
  foreign key (poll_id) references public.polls(id) on delete set null;

-- ========================================
-- Row Level Security
-- ========================================
alter table public.messages enable row level security;
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;

-- Anyone in the room (teacher or member student) can read messages.
create policy "messages_select_room_member"
  on public.messages for select
  using (
    exists (select 1 from public.rooms r where r.id = messages.room_id and r.teacher_id = auth.uid())
    or exists (select 1 from public.room_members rm where rm.room_id = messages.room_id and rm.student_id = auth.uid())
  );

-- Teacher can always post. Student can post only if chat_enabled on the room (§2.2).
create policy "messages_insert_teacher"
  on public.messages for insert
  with check (
    exists (select 1 from public.rooms r where r.id = messages.room_id and r.teacher_id = auth.uid())
  );

create policy "messages_insert_student_if_chat_enabled"
  on public.messages for insert
  with check (
    exists (
      select 1 from public.rooms r
      join public.room_members rm on rm.room_id = r.id
      where r.id = messages.room_id
        and rm.student_id = auth.uid()
        and r.chat_enabled = true
    )
  );

-- Polls: same read access as messages; only teacher can create.
create policy "polls_select_room_member"
  on public.polls for select
  using (
    exists (select 1 from public.rooms r where r.id = polls.room_id and r.teacher_id = auth.uid())
    or exists (select 1 from public.room_members rm where rm.room_id = polls.room_id and rm.student_id = auth.uid())
  );

create policy "polls_insert_teacher"
  on public.polls for insert
  with check (
    exists (select 1 from public.rooms r where r.id = polls.room_id and r.teacher_id = auth.uid())
  );

create policy "poll_options_select_room_member"
  on public.poll_options for select
  using (
    exists (
      select 1 from public.polls p
      join public.rooms r on r.id = p.room_id
      where p.id = poll_options.poll_id and r.teacher_id = auth.uid()
    )
    or exists (
      select 1 from public.polls p
      join public.room_members rm on rm.room_id = p.room_id
      where p.id = poll_options.poll_id and rm.student_id = auth.uid()
    )
  );

create policy "poll_options_insert_teacher"
  on public.poll_options for insert
  with check (
    exists (
      select 1 from public.polls p
      join public.rooms r on r.id = p.room_id
      where p.id = poll_options.poll_id and r.teacher_id = auth.uid()
    )
  );

-- Students vote once; teachers can read all votes for their room's polls.
create policy "poll_votes_insert_student"
  on public.poll_votes for insert
  with check (auth.uid() = student_id);

create policy "poll_votes_select_room_member"
  on public.poll_votes for select
  using (
    exists (
      select 1 from public.polls p
      join public.rooms r on r.id = p.room_id
      where p.id = poll_votes.poll_id and r.teacher_id = auth.uid()
    )
    or auth.uid() = student_id
  );

-- ========================================
-- Vote counts per option, computed on read (avoids a stale counter column)
-- ========================================
create or replace view public.poll_options_with_counts as
select
  po.*,
  (select count(*) from public.poll_votes pv where pv.option_id = po.id) as vote_count
from public.poll_options po;
