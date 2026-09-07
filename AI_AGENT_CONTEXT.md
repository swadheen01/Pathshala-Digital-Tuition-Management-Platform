# Pathshala — AI Agent Context

This file gives any AI coding agent (or new human contributor) everything needed to
understand and continue this project without re-deriving architecture decisions from
scratch. Read this fully before making changes.

---

## 1. What this app is

**Pathshala** is a Flutter + Supabase tuition-management app connecting four roles:
**Teacher, Student, Admin, Parent**. Full functional spec lives in
`tuition-app-project-spec-main.md` (original source of truth for *what* to build — this
file describes *how* it was built and where everything lives).

Primary user base is Bengali-speaking; the app supports an English/Bengali locale
toggle (not yet translated — see §8 Known Gaps).

---

## 2. Tech stack & why

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (Dart ≥3.3) | |
| State management | **Riverpod** (`flutter_riverpod`) | Every feature has a `*_provider.dart` wrapping a `*_service.dart` |
| Routing | **go_router** | Central config in `lib/core/routes/app_router.dart`, path constants in `route_names.dart` |
| Backend | **Supabase** (`supabase_flutter`) | Postgres + Auth + Storage + Realtime |
| Local offline storage | `sqflite` | Used only by `offline_sync_service.dart` for queued attendance |
| Connectivity detection | `connectivity_plus` | |
| Charts | `fl_chart` | Student performance graph |
| Calendar UI | `table_calendar` | |
| File sharing | `share_plus` | Payment CSV export |
| Link opening | `url_launcher` | Opening curated content URLs |

Full dependency list: `pubspec.yaml` at project root.

---

## 3. Architecture pattern (apply this consistently to new features)

Every feature follows the same four-layer pattern:

```
models/<feature>_model.dart       - plain Dart class, fromJson/toJson, Equatable
services/<feature>_service.dart   - talks directly to Supabase (queries/mutations/RPCs)
providers/<feature>_provider.dart - Riverpod FutureProvider/StreamProvider (reads) +
                                     a StateNotifier "*Controller" (writes/mutations)
features/<role>/screens/*.dart    - UI, consumes providers via ConsumerWidget/ConsumerStatefulWidget
```

**Provider naming convention:**
- `xServiceProvider` - the raw service instance
- `xProvider` / `roomXProvider(id)` - read-only data (Future/StreamProvider, `.family` when scoped to an id)
- `xControllerProvider` - a `StateNotifierProvider<XController, AsyncValue<void>>` for mutations; screens call
  `ref.read(xControllerProvider.notifier).someAction(...)` and check the return bool for success/failure

**Screens always follow this shape:**
```dart
class SomeScreen extends ConsumerWidget {
  build(context, ref) {
    final dataAsync = ref.watch(someProvider(id));
    return dataAsync.when(loading: ..., error: ..., data: (data) => ...);
  }
}
```

**Route params:** dynamic segments use go_router path params (`:roomId`, `:studentId`,
`:assignmentId`, `:examId`, `:childId`), extracted via `state.pathParameters['roomId']!`.
Non-URL-safe data (e.g. a `UserRole` enum, a room id needed alongside a childId param) is
passed via `extra:` on `context.push(...)` and read via `state.extra as T?`.

---

## 4. Full file tree (as of last update)

```
pathshala/
├── pubspec.yaml
├── PROJECT_STRUCTURE.md              (earlier planning doc - this file supersedes it)
├── supabase/migrations/              (run in this exact numeric order)
│   ├── 0001_init.sql                 profiles table, roles enum, auth trigger, RLS
│   ├── 0002_rooms.sql                rooms, room_members, join_room() RPC
│   ├── 0003_attendance.sql           attendance table, class-day trigger, summary RPC
│   ├── 0004_messaging.sql            messages, polls, poll_options, poll_votes
│   ├── 0005_payments.sql             payments table, dues calculation
│   ├── 0006_assignments.sql          assignments, submissions
│   ├── 0007_exams.sql                exams, exam_scores, leaderboard RPC
│   ├── 0008_admin_content.sql        content, content_views, analytics RPC
│   ├── 0009_parent.sql               parent_links + extends RLS on attendance/payments/exam_scores/rooms
│   └── 0010_notifications.sql        notifications table + auto-generation triggers (6 of 8 event types)
│
└── lib/
    ├── main.dart                     Supabase init + starts OfflineSyncService connectivity listener
    ├── app.dart                      MaterialApp.router, theme, locale, localizations
    │
    ├── core/
    │   ├── config/supabase_config.dart      SupabaseConfig.client - single source of Supabase connection
    │   ├── theme/app_theme.dart              AppTheme.light / .dark
    │   ├── routes/
    │   │   ├── route_names.dart              all path string constants
    │   │   └── app_router.dart               GoRouter config - every route lives here
    │   ├── constants/
    │   │   ├── app_colors.dart, app_strings.dart, supabase_tables.dart
    │   ├── utils/
    │   │   ├── validators.dart               form validators (email, otp, amount, etc.)
    │   │   ├── date_utils.dart                weekday conversion helpers (see §6 gotcha)
    │   │   └── formatters.dart
    │   └── widgets/
    │       ├── custom_button.dart, custom_text_field.dart, loading_indicator.dart,
    │       ├── empty_state.dart, error_view.dart, app_avatar.dart
    │       (NOTE: most existing screens predate these and inline their own
    │        CircularProgressIndicator/Text - not yet refactored to use these.)
    │
    ├── models/            (one file per entity, see §5 for full list)
    ├── services/          (one file per feature, see §5)
    ├── providers/         (one file per feature, see §5)
    │
    └── features/
        ├── auth/screens/          login, otp_verification, role_selection, profile_setup
        ├── shared/screens/        home_shell (bottom-nav root), calendar, notifications,
        │                          settings, profile, messaging, poll_message_card
        ├── teacher/screens/       dashboard, room_list, create_room, room_detail,
        │                          room_schedule, student_list, attendance, attendance_summary,
        │                          create_poll, payments, record_payment, payment_history_export,
        │                          assignments, create_assignment, review_submissions,
        │                          exams, record_exam_score, leaderboard_settings, parent_access
        ├── student/screens/       school_tuition_tabs (home), join_room, room_feed,
        │                          attendance_view, student_assignments, assignment_submission,
        │                          exam_performance, leaderboard, content_feed, content_search
        ├── admin/screens/         admin_dashboard, manage_teachers, manage_students,
        │                          manage_content, add_content, analytics
        └── parent/screens/        parent_dashboard, child_view_switcher (shared segmented nav),
                                   child_attendance, child_payments, child_performance
```

---

## 5. Models / Services / Providers index

| Feature | Model | Service | Provider |
|---|---|---|---|
| Auth/User | `user_model.dart` (`UserRole` enum: teacher/student/admin/parent) | `auth_service.dart` | `auth_provider.dart` (`currentProfileProvider`, `authControllerProvider`) |
| Rooms | `room_model.dart`, `room_member_model.dart` | `room_service.dart` | `room_provider.dart` |
| Attendance | `attendance_model.dart` | `attendance_service.dart` + `offline_sync_service.dart` | `attendance_provider.dart` |
| Messaging/Polls | `message_model.dart`, `poll_model.dart` | `messaging_service.dart` | `messaging_provider.dart` |
| Payments | `payment_model.dart` | `payment_service.dart` | `payment_provider.dart` |
| Assignments | `assignment_model.dart` (incl. `SubmissionModel`) | `assignment_service.dart` | `assignment_provider.dart` |
| Exams/Leaderboard | `exam_model.dart` (incl. `PerformancePoint`, `LeaderboardEntry`) | `exam_service.dart` | `exam_provider.dart` |
| Admin/Content | `content_model.dart` (incl. `PlatformAnalytics`) | `admin_service.dart`, `content_service.dart` | `admin_provider.dart`, `content_provider.dart` |
| Parent | `parent_link_model.dart` | `parent_service.dart` | `parent_provider.dart` |
| Notifications | `notification_model.dart` | `notification_service.dart` | `notification_provider.dart` |
| Storage (uploads) | - | `storage_service.dart` | (no provider yet - called directly from screens) |
| Locale | - | - | `locale_provider.dart` |
| Connectivity | - | - | `connectivity_provider.dart` |

**Payment field names** (differ slightly from the pattern elsewhere - check before
editing): `PaymentModel` uses `amount`, `paidOn`, `forMonth` (String, e.g. `"2026-07"`), `note` -
not `amountPaid`/`periodMonth`/`notes`.

---

## 6. Supabase schema notes & gotchas

- **Weekday convention mismatch is intentional and handled explicitly**: the app stores
  `room.classDays` as `1=Sun..7=Sat`. Dart's `DateTime.weekday` is `1=Mon..7=Sun`. Postgres's
  `extract(dow from date)` is `0=Sun..6=Sat`. Every place that compares a date against
  `classDays` converts explicitly - see `AppDateUtils.toAppWeekday()` (Dart side) and the
  trigger in `0003_attendance.sql` (SQL side, `extract(dow)+1`). **Do not compare a raw
  `DateTime.weekday` against `classDays` without converting.**

- **RLS is the actual access-control layer**, not just a client-side check. Notably:
  - Students can't read arbitrary rooms - `join_room()` is a `security definer` RPC so
    joining-by-code doesn't require a broad "any authenticated user can read any room" policy.
  - Parent access is bolted on via `0009_parent.sql`, which adds *additional* SELECT
    policies to `attendance`, `payments`, `exam_scores`, `room_members`, and `rooms` -
    parents aren't a separate data model, they're just another RLS-gated lens on the
    same rows students/teachers see.
  - Admin analytics (`get_platform_analytics()`) self-checks the caller's role inside the
    function body (`security definer`), since it aggregates across all users.

- **Migration run order matters** - foreign keys and RLS policies in later files
  reference tables/columns from earlier ones. Run 0001 through 0010 in order, never skip.

- **`payment_due` and `poll` notification types exist in the enum but have no DB trigger**
  in `0010_notifications.sql`. `poll` creation notifications need adding; `payment_due`
  needs a scheduled job (`pg_cron` + the teacher's configurable schedule from spec §2.4),
  not an insert trigger, since it's date-driven rather than event-driven.

---

## 7. Routing map

All routes are registered in `lib/core/routes/app_router.dart`; string constants in
`route_names.dart`. The four post-login dashboard routes
(`teacherDashboard`/`studentDashboard`/`adminDashboard`/`parentDashboard`) all resolve to
the **same** `HomeShellScreen`, which internally picks the correct tab/dashboard based on
`currentProfileProvider`'s role - they are not four different screens.

`HomeShellScreen` (bottom nav): Home (role-specific) - Calendar - Notifications - Settings.

---

## 8. Known gaps (don't assume these are done)

1. **Push notifications are DB-only.** Triggers create `notifications` rows, but nothing
   forwards to FCM/APNs yet. Needs a Supabase Edge Function or `pg_net` webhook.
2. **`.arb` translation files don't exist.** The `en`/`bn` locale toggle in
   `locale_provider.dart` / `settings_screen.dart` switches `MaterialApp.locale`, but no
   actual Bengali strings have been written - all UI text is still hardcoded English
   inline in widgets, not routed through `intl`.
3. **Storage buckets aren't created yet.** `storage_service.dart` assumes three buckets
   (`message-images`, `submissions`, `avatars`) exist in the Supabase dashboard -
   uploads will fail with a "bucket not found" error until created.
4. **No automated tests.** Nothing under `test/` yet.
5. **Reusable widgets in `core/widgets/` are unused.** They were added late; most screens
   still inline their own loading/error/empty states rather than using
   `LoadingIndicator`/`ErrorView`/`EmptyState`. Not broken, just inconsistent - a good
   cleanup pass if anyone revisits UI polish.
6. **`payment_due` and `poll` notification triggers missing** (see §6).
7. **Supabase URL/anon key are placeholders** in `supabase_config.dart` - must be
   supplied via `--dart-define` or edited directly before running.

---

## 9. How to run this project

1. This is a hand-built `lib/` tree matching the structure above (not generated by
   `flutter create` from scratch, though it assumes that base scaffold exists). Run
   `flutter pub get` to install dependencies.
2. Create a Supabase project; copy its URL + anon key.
3. Run all 10 migration files, in numeric order, via Supabase SQL Editor (or
   `supabase db push` if using the CLI with these files under a real `supabase/` project folder).
4. Create three Storage buckets: `message-images`, `submissions`, `avatars`.
5. Run:
   ```
   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```

---

## 10. Conventions to preserve when extending this project

- New features get the four-layer treatment (model/service/provider/screen) - don't put
  Supabase calls directly in a widget.
- New tables need an explicit RLS policy set mirroring the teacher-owns / student-is-member
  / parent-is-linked pattern already established - never leave a table with RLS disabled.
- Add new route paths to `route_names.dart` first, then wire in `app_router.dart`.
- Keep controller mutation methods returning `Future<bool>` (success/failure) so screens
  can branch on the result without inspecting `AsyncValue` error internals directly.
- Spec section references (e.g. `spec §2.6`) are used throughout code comments - keep
  this convention so any file's purpose can be traced back to `tuition-app-project-spec-main.md`.
