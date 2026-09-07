# Pathshala

Tuition management app connecting teachers, students, admins, and parents.

## Supabase setup checklist

1. Apply the migrations in `supabase/migrations/` in order, including
   `0011_fix_profiles_rls_recursion.sql`,
   `0012_fix_rooms_rls_recursion.sql`, and
   `0013_first_time_profile_setup.sql`. The latter is required if the app
   reports `infinite recursion detected in policy for relation "rooms"` when
   loading the home dashboard.
2. Create Storage buckets named `message-images`, `submissions`, and `avatars`.
   The first and last need public read access; `submissions` should remain
   private and be accessed through signed URLs.
3. Deploy `supabase/functions/notify-push` and set `PUSH_WEBHOOK_URL` to the
   FCM/APNs gateway used by your deployment.
4. Configure a Supabase Database Webhook for `INSERT` events on
   `public.notifications` targeting `notify-push`.
5. Enable `pg_cron` and schedule `select public.notify_payment_due();` daily,
   or invoke that function from an equivalent scheduled Edge Function.

## Local development

Run `flutter pub get`, then `flutter run`. Localization resources live in
`l10n/`; Flutter generates `lib/generated/app_localizations.dart` during the
build.

## Authentication setup

The app uses email/password + Google sign-in. A single GoRouter `redirect`
(see `lib/core/routes/app_router.dart`) is the only thing that navigates after
auth: it reads `authGateProvider` (session + `profiles.profile_completed` +
role) and sends the user to the splash, an onboarding step, or their
role-specific dashboard. No screen navigates on its own auth event anymore.

### Roster: name-only students + join-and-claim

`0015_roster_and_claims.sql` lets a teacher add a student to a room by
name alone (no phone / no account) via **Students → Add student**. Those
rows live in `room_members` with `student_id IS NULL`. Attendance,
payments and exam scores key on `room_members.ref_id`
(`COALESCE(student_id, id)`), so a phoneless student is fully trackable
from day one.

When a student later joins with the room code and types a name that
matches an unclaimed roster row, they can request to be linked to it. The
teacher approves under **Room → Join requests**, which sets `student_id`
on that row and moves any recorded history across. Approval/rejection and
the request lookup all run through `SECURITY DEFINER` RPCs
(`request_room_claim`, `get_room_join_requests`, `approve_room_claim`,
`reject_room_claim`).

### Bootstrap administrator

`0016_admin_bootstrap_and_class_times.sql` makes
**contactwith.swadheen@gmail.com** an administrator: any existing profile
with that email is promoted, and `handle_new_user` assigns the `admin`
role (and skips onboarding) if that address ever signs up. `set_my_role`
also refuses to downgrade that account. The same migration adds optional
`rooms.class_start_time` / `class_end_time` (drives the home-screen "class
on now / next" cards) and two home-screen RPCs
(`get_my_room_attendance`, `get_teacher_payment_overview`).

### Required migrations

Apply everything in `supabase/migrations/` in order, **including
`0014_auth_hardening.sql`, `0015_roster_and_claims.sql` and
`0016_admin_bootstrap_and_class_times.sql`**. 0014:

- guarantees `profiles.profile_completed` exists,
- rewrites `handle_new_user()` so a Google sign-up (no `role` metadata) gets a
  real display name and `profile_completed = false` (which forces the
  role-selection screen instead of silently defaulting to *student*),
- adds `set_my_role(user_role)` — the RPC the role-selection screen calls.

### Supabase Dashboard checklist

1. **Authentication > Providers > Email** — enabled.
   - Leave **Confirm email** ON. The confirmation link now completes inside
     the app (PKCE + deep link), so this no longer breaks sign-in.
2. **Authentication > Providers > Google** — enabled, with the OAuth client
   ID/secret configured. In the Google Cloud OAuth client, add
   `io.supabase.pathshala://login-callback/` as an authorized redirect URI.
3. **Authentication > URL Configuration**
   - **Site URL**: your production URL (or `io.supabase.pathshala://login-callback/`
     if you have no web build — this is the fallback the email link uses when
     no explicit redirect matches).
   - **Redirect URLs** allow-list — add **exactly**:
     `io.supabase.pathshala://login-callback/`
     This one entry is used by Google OAuth, email confirmation, and password
     reset. If it is missing, the email link opens the Site URL in a browser
     and never returns to the app — that was the original "clicking the link
     doesn't log in" bug.
4. **Authentication > Rate limits** — if you see `AuthRetryableFetchException`
   on signup, first confirm the project isn't paused and the device has
   network; then check you haven't hit the hourly email/signup rate limit.

The redirect string is defined once in
`lib/core/config/supabase_config.dart` (`authRedirectUri`) and must match the
Android intent filter (`android/app/src/main/AndroidManifest.xml`) and the iOS
`CFBundleURLSchemes` entry (`ios/Runner/Info.plist`) — both are already set to
scheme `io.supabase.pathshala`, host `login-callback`.

### Known follow-up

Password-reset links log the user in but there is no "choose a new password"
screen yet — add a handler for `AuthChangeEvent.passwordRecovery` when that
flow is needed.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
