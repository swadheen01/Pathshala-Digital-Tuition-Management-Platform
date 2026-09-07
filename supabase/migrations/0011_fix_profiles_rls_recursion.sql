-- Fix recursive profiles RLS policies.
--
-- The old profiles_select_admin policy queried public.profiles from inside
-- a policy on public.profiles. PostgreSQL evaluates that policy repeatedly
-- and raises "infinite recursion detected in policy for relation profiles".

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "profiles_select_admin" on public.profiles;

create policy "profiles_select_admin"
  on public.profiles for select
  using (public.is_admin());

drop policy if exists "content_all_admin" on public.content;

create policy "content_all_admin"
  on public.content for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "content_views_select_admin" on public.content_views;

create policy "content_views_select_admin"
  on public.content_views for select
  using (public.is_admin());
