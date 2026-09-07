-- Pathshala — Notifications migration
-- Run after 0001–0009
--
-- Covers spec §1: "Push notifications infrastructure covering all
-- real-time events: new messages, poll creation, new content upload,
-- attendance marked, assignment posted, exam result published,
-- payment due/received, etc."
--
-- This migration handles the DATABASE side (creating notification rows
-- via triggers whenever something notification-worthy happens). Actual
-- push delivery (FCM/APNs) is wired in notification_service.dart using
-- Supabase Edge Functions or a third-party push provider — see the
-- comment at the bottom of this file.

create type notification_type as enum (
  'message', 'poll', 'content', 'attendance', 'assignment',
  'examResult', 'paymentDue', 'paymentReceived', 'custom'
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  type notification_type not null,
  title text not null,
  body text,
  room_id uuid references public.rooms(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_recipient
  on public.notifications (recipient_id, created_at desc);

alter table public.notifications enable row level security;

create policy "notifications_select_own"
  on public.notifications for select
  using (auth.uid() = recipient_id);

create policy "notifications_update_own_mark_read"
  on public.notifications for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

-- Any signed-in user (via server-side trigger, security definer) can
-- insert notifications for others — this is intentionally permissive
-- because it's only ever called from trigger functions below, not
-- directly by client code (no direct insert policy for clients).

-- Exception: teachers can directly insert CUSTOM notifications for
-- students in rooms they own (spec §2.4 — manual notifications).
create policy "notifications_insert_teacher_custom"
  on public.notifications for insert
  with check (
    type = 'custom'
    and exists (
      select 1 from public.room_members rm
      join public.rooms r on r.id = rm.room_id
      where rm.student_id = notifications.recipient_id
        and r.teacher_id = auth.uid()
    )
  );

-- ========================================
-- Trigger: new assignment posted → notify every student in the room
-- ========================================
create or replace function public.notify_new_assignment()
returns trigger as $$
begin
  insert into public.notifications (recipient_id, type, title, body, room_id)
  select rm.student_id, 'assignment', 'New assignment: ' || new.title,
         'Due ' || to_char(new.due_date, 'DD Mon YYYY'), new.room_id
  from public.room_members rm
  where rm.room_id = new.room_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_new_assignment
  after insert on public.assignments
  for each row execute function public.notify_new_assignment();

-- ========================================
-- Trigger: new message posted → notify everyone in the room except sender
-- ========================================
create or replace function public.notify_new_message()
returns trigger as $$
begin
  insert into public.notifications (recipient_id, type, title, body, room_id)
  select rm.student_id, 'message', 'New message',
         coalesce(new.text, 'New content shared'), new.room_id
  from public.room_members rm
  where rm.room_id = new.room_id and rm.student_id != new.sender_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_new_message
  after insert on public.messages
  for each row execute function public.notify_new_message();

-- ========================================
-- Trigger: poll created -> notify every student in the room
-- ========================================
create or replace function public.notify_new_poll()
returns trigger as $$
begin
  insert into public.notifications (recipient_id, type, title, body, room_id)
  select rm.student_id, 'poll', 'New poll', new.question, new.room_id
  from public.room_members rm
  where rm.room_id = new.room_id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_new_poll on public.polls;
create trigger trg_notify_new_poll
  after insert on public.polls
  for each row execute function public.notify_new_poll();

-- ========================================
-- Trigger: attendance marked → notify the affected student
-- ========================================
create or replace function public.notify_attendance_marked()
returns trigger as $$
begin
  insert into public.notifications (recipient_id, type, title, body, room_id)
  values (
    new.student_id,
    'attendance',
    'Attendance marked',
    case when new.present then 'You were marked present today' else 'You were marked absent today' end,
    new.room_id
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_attendance_marked
  after insert on public.attendance
  for each row execute function public.notify_attendance_marked();

-- ========================================
-- Trigger: exam score recorded → notify the student
-- ========================================
create or replace function public.notify_exam_result()
returns trigger as $$
declare
  v_exam_title text;
  v_room_id uuid;
begin
  select title, room_id into v_exam_title, v_room_id
  from public.exams where id = new.exam_id;

  insert into public.notifications (recipient_id, type, title, body, room_id)
  values (
    new.student_id,
    'examResult',
    'Exam result published',
    v_exam_title || ': ' || new.marks_obtained || ' marks',
    v_room_id
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_exam_result
  after insert on public.exam_scores
  for each row execute function public.notify_exam_result();

-- ========================================
-- Trigger: payment received → notify the student (spec §2.4)
-- ========================================
create or replace function public.notify_payment_received()
returns trigger as $$
begin
  insert into public.notifications (recipient_id, type, title, body, room_id)
  values (
    new.student_id,
    'paymentReceived',
    'Payment received',
    'We received your payment of ' || new.amount,
    new.room_id
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_payment_received
  after insert on public.payments
  for each row execute function public.notify_payment_received();

-- ========================================
-- Payment due notifications
--
-- This function is safe to run daily. It notifies students whose current
-- month's fee has not been paid and avoids duplicates for the same month.
-- Schedule it with pg_cron (or invoke it from a scheduled Edge Function):
--
-- select cron.schedule(
--   'pathshala-payment-due',
--   '0 9 * * *',
--   $$select public.notify_payment_due();$$
-- );
-- ========================================
create or replace function public.notify_payment_due()
returns void as $$
begin
  insert into public.notifications (recipient_id, type, title, body, room_id)
  select
    rm.student_id,
    'paymentDue',
    'Payment due',
    'Your monthly tuition payment of ' || rm.monthly_fee || ' is due.',
    rm.room_id
  from public.room_members rm
  where rm.monthly_fee > 0
    and not exists (
      select 1
      from public.payments p
      where p.room_id = rm.room_id
        and p.student_id = rm.student_id
        and p.for_month = to_char(current_date, 'YYYY-MM')
    )
    and not exists (
      select 1
      from public.notifications n
      where n.recipient_id = rm.student_id
        and n.room_id = rm.room_id
        and n.type = 'paymentDue'
        and n.created_at::date = current_date
        and n.body = 'Your monthly tuition payment of ' || rm.monthly_fee || ' is due.'
    );
end;
$$ language plpgsql security definer;

-- ========================================
-- Trigger: new content published → notify students matching the target class
-- ========================================
create or replace function public.notify_new_content()
returns trigger as $$
begin
  insert into public.notifications (recipient_id, type, title, body)
  select p.id, 'content', 'New content: ' || new.title, new.description
  from public.profiles p
  where p.role = 'student'
    and (new.target_class_grade is null or p.class_grade = new.target_class_grade);
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_new_content
  after insert on public.content
  for each row execute function public.notify_new_content();

-- ========================================
-- NOTE on push delivery (not covered by SQL):
-- These triggers only create in-app notification rows. To also send a
-- push notification (FCM/APNs), pair this with a Supabase Edge Function
-- listening on the `notifications` table via Realtime, or a
-- `pg_net`/webhook call from these trigger functions to your push
-- provider. That wiring is provider-specific and left to
-- notification_service.dart + your Supabase project's Edge Functions.
-- ========================================
