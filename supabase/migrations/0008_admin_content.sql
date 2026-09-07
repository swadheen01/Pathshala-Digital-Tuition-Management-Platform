-- Pathshala — Admin Content & Analytics migration
-- Run after 0001–0007

-- ========================================
-- content: curated links/videos (spec §4)
-- ========================================
create table if not exists public.content (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  url text not null,
  description text,
  thumbnail_url text,
  target_class_grade text, -- null = visible to all students (general content)
  subject text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_content_class_grade
  on public.content (target_class_grade);

-- ========================================
-- content_views: lightweight engagement tracking for analytics (spec §4)
-- ========================================
create table if not exists public.content_views (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.content(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  viewed_at timestamptz not null default now()
);

-- ========================================
-- Row Level Security
-- ========================================
alter table public.content enable row level security;
alter table public.content_views enable row level security;

-- Everyone authenticated can read content (search/filter is a client-side
-- concern per spec §4 — "available to all users").
create policy "content_select_all_authenticated"
  on public.content for select
  using (auth.uid() is not null);

-- Only admins manage content.
create policy "content_all_admin"
  on public.content for all
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  )
  with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Students log their own views; admins can read all views for analytics.
create policy "content_views_insert_own"
  on public.content_views for insert
  with check (auth.uid() = student_id);

create policy "content_views_select_admin"
  on public.content_views for select
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- ========================================
-- get_platform_analytics RPC (spec §4: admin dashboard)
-- ========================================
create or replace function public.get_platform_analytics()
returns json
language plpgsql
security definer
as $$
declare
  v_result json;
begin
  -- Restrict to admins only.
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin') then
    raise exception 'Not authorized';
  end if;

  select json_build_object(
    'active_teachers', (select count(*) from public.profiles where role = 'teacher'),
    'active_students', (select count(*) from public.profiles where role = 'student'),
    'total_rooms', (select count(*) from public.rooms),
    'total_content', (select count(*) from public.content),
    'most_viewed_content', (
      select coalesce(json_agg(t), '[]'::json) from (
        select c.id as content_id, c.title, count(cv.id) as view_count
        from public.content c
        left join public.content_views cv on cv.content_id = c.id
        group by c.id, c.title
        order by count(cv.id) desc
        limit 5
      ) t
    )
  ) into v_result;

  return v_result;
end;
$$;
