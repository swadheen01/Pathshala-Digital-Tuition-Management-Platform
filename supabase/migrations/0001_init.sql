-- Pathshala — Initial migration
-- Run via: supabase db push  (or paste into Supabase SQL Editor)

-- ========================================
-- profiles: one row per authenticated user
-- Mirrors lib/models/user_model.dart
-- ========================================
create type user_role as enum ('teacher', 'student', 'admin', 'parent');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role user_role not null default 'student',
  email text,
  phone text,
  class_grade text,          -- e.g. "Class 9" — captured at registration (spec §1, §4)
  institution text,
  avatar_url text,
  language_preference text not null default 'en',  -- 'en' or 'bn' (spec §1)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh on every edit
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ========================================
-- Row Level Security
-- ========================================
alter table public.profiles enable row level security;

-- Anyone authenticated can read their own profile.
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

-- Admins can read every profile (needed for §4 Admin management + analytics).
create policy "profiles_select_admin"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- Teachers can read profiles of students who share a room with them.
-- (Depends on room_members table — added in the next migration once
-- rooms exist. Left as a placeholder comment for now.)
-- create policy "profiles_select_teacher_room_students" ...

-- A user can insert their own profile row (first-time signup / completeProfile()).
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

-- A user can update only their own profile.
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ========================================
-- Auto-create a bare profile row on signup
-- (auth_service.dart's completeProfile() will upsert on top of this)
-- ========================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    new.phone
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
