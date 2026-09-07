# Pathshala — Flutter Project Structure

Full folder/file layout for the app described in `tuition-app-project-spec-main.md`.
Create these exact folders and empty `.dart` files first — we'll fill each one in as we go through the build phases.

Architecture: **Riverpod** (state) + **go_router** (navigation) + **Supabase** (backend) + a `features/` folder per role, matching spec sections 2 (Teacher), 3 (Student), 4 (Admin), and Parent access (2.8).

---

## Full Tree

```
pathshala/
├── pubspec.yaml
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── l10n/
│   ├── app_en.arb                          # English strings
│   └── app_bn.arb                          # Bengali strings (spec §1 multi-language)
├── supabase/
│   └── migrations/
│       └── 0001_init.sql                   # DB schema (tables, RLS) — not Dart, lives outside lib/
│
└── lib/
    ├── main.dart                           # ✅ done — entry point
    ├── app.dart                            # ✅ done — root widget, theme, localization, router
    │
    ├── core/                               # App-wide, role-agnostic building blocks
    │   ├── config/
    │   │   └── supabase_config.dart        # ✅ done — Supabase client init
    │   ├── theme/
    │   │   ├── app_theme.dart              # Light/dark ThemeData
    │   │   └── app_text_styles.dart        # Reusable TextStyle constants
    │   ├── routes/
    │   │   ├── app_router.dart             # go_router config, role-based redirects
    │   │   └── route_names.dart            # Route path constants
    │   ├── constants/
    │   │   ├── app_colors.dart
    │   │   ├── app_strings.dart
    │   │   └── supabase_tables.dart        # Table/column name constants (avoid typos in queries)
    │   ├── utils/
    │   │   ├── validators.dart             # Form validation (email, OTP, roll no.)
    │   │   ├── date_utils.dart             # Class-day / due-date helpers
    │   │   ├── formatters.dart             # Currency, date display formatting
    │   │   └── offline_sync_helper.dart    # Queue + retry logic (spec §2.3 offline attendance)
    │   └── widgets/                        # Shared dumb UI components
    │       ├── loading_indicator.dart
    │       ├── custom_button.dart
    │       ├── custom_text_field.dart
    │       ├── empty_state.dart
    │       ├── error_view.dart
    │       └── app_avatar.dart
    │
    ├── models/                             # Plain Dart data classes (mirror Supabase tables)
    │   ├── user_model.dart                 # Teacher/Student/Admin/Parent shared user shape
    │   ├── room_model.dart                 # Tuition room (§2.1)
    │   ├── room_member_model.dart          # Join table: student ↔ room
    │   ├── room_schedule_model.dart        # Class weekdays (§2.5)
    │   ├── attendance_model.dart           # §2.3
    │   ├── message_model.dart              # §2.2
    │   ├── poll_model.dart                 # §2.2
    │   ├── poll_option_model.dart
    │   ├── poll_vote_model.dart
    │   ├── payment_model.dart              # §2.4
    │   ├── assignment_model.dart           # §2.6
    │   ├── submission_model.dart           # §2.6
    │   ├── exam_model.dart                 # §2.7
    │   ├── exam_score_model.dart           # §2.7
    │   ├── content_model.dart              # §4 (Admin-curated content)
    │   ├── notification_model.dart         # §1 push notifications
    │   └── parent_link_model.dart          # §2.8
    │
    ├── services/                           # Talks directly to Supabase (queries, mutations, storage, auth)
    │   ├── auth_service.dart               # OTP/email signup+login, role capture
    │   ├── user_service.dart
    │   ├── room_service.dart               # Create room, join by code, list rooms
    │   ├── attendance_service.dart         # Mark/fetch attendance, restricted to class days
    │   ├── messaging_service.dart          # Send/list messages, chat on/off toggle
    │   ├── poll_service.dart
    │   ├── payment_service.dart            # Record payment, dues calc, export
    │   ├── assignment_service.dart
    │   ├── exam_service.dart
    │   ├── content_service.dart            # Search/filter (§4)
    │   ├── notification_service.dart       # Push notification triggers + auto reminders
    │   ├── admin_service.dart              # Manage teachers/students/content, analytics
    │   ├── parent_service.dart
    │   ├── offline_sync_service.dart       # Local SQLite queue → sync when online (§2.3)
    │   └── storage_service.dart            # Image/file uploads (Supabase Storage)
    │
    ├── providers/                          # Riverpod providers wrapping the services above
    │   ├── auth_provider.dart
    │   ├── user_provider.dart
    │   ├── room_provider.dart
    │   ├── attendance_provider.dart
    │   ├── messaging_provider.dart
    │   ├── poll_provider.dart
    │   ├── payment_provider.dart
    │   ├── assignment_provider.dart
    │   ├── exam_provider.dart
    │   ├── content_provider.dart
    │   ├── notification_provider.dart
    │   ├── admin_provider.dart
    │   ├── parent_provider.dart
    │   ├── locale_provider.dart            # Bengali/English toggle state
    │   └── connectivity_provider.dart      # Online/offline status stream
    │
    └── features/                           # Screens, grouped by role — matches spec §2/§3/§4
        │
        ├── onboarding/
        │   └── screens/
        │       ├── splash_screen.dart
        │       └── language_select_screen.dart
        │
        ├── auth/
        │   ├── screens/
        │   │   ├── login_screen.dart
        │   │   ├── signup_screen.dart
        │   │   ├── otp_verification_screen.dart
        │   │   ├── role_selection_screen.dart      # Teacher / Student signup branch
        │   │   └── profile_setup_screen.dart       # Captures class/grade/institution (§1)
        │   └── widgets/
        │       └── auth_text_field.dart
        │
        ├── shared/                                 # Screens common to multiple roles
        │   └── screens/
        │       ├── home_shell_screen.dart          # Bottom-nav shell, role-aware
        │       ├── calendar_screen.dart             # In-app calendar (§1, §3)
        │       ├── notifications_screen.dart
        │       ├── settings_screen.dart
        │       └── profile_screen.dart
        │
        ├── teacher/                                # §2 Teacher Features
        │   ├── screens/
        │   │   ├── teacher_dashboard_screen.dart
        │   │   ├── room_list_screen.dart
        │   │   ├── create_room_screen.dart
        │   │   ├── room_detail_screen.dart
        │   │   ├── room_schedule_screen.dart       # §2.5
        │   │   ├── student_list_screen.dart        # §2.1
        │   │   ├── add_student_screen.dart
        │   │   ├── attendance_screen.dart          # §2.3
        │   │   ├── attendance_summary_screen.dart
        │   │   ├── messaging_screen.dart           # §2.2
        │   │   ├── create_poll_screen.dart
        │   │   ├── payments_screen.dart            # §2.4
        │   │   ├── record_payment_screen.dart
        │   │   ├── payment_history_export_screen.dart
        │   │   ├── assignments_screen.dart         # §2.6
        │   │   ├── create_assignment_screen.dart
        │   │   ├── review_submissions_screen.dart
        │   │   ├── exams_screen.dart               # §2.7
        │   │   ├── record_exam_score_screen.dart
        │   │   ├── leaderboard_settings_screen.dart
        │   │   └── parent_access_screen.dart       # §2.8
        │   └── widgets/
        │       ├── student_list_tile.dart
        │       ├── attendance_row.dart
        │       └── payment_card.dart
        │
        ├── student/                                # §3 Student Features
        │   ├── screens/
        │   │   ├── student_dashboard_screen.dart
        │   │   ├── school_tuition_tabs_screen.dart # §3 "School" / "Tuition" split
        │   │   ├── join_room_screen.dart
        │   │   ├── room_feed_screen.dart
        │   │   ├── attendance_view_screen.dart
        │   │   ├── assignment_submission_screen.dart
        │   │   ├── exam_performance_screen.dart
        │   │   ├── leaderboard_screen.dart
        │   │   ├── content_feed_screen.dart
        │   │   └── content_search_screen.dart      # §4 search/filter
        │   └── widgets/
        │       ├── content_card.dart
        │       └── performance_chart.dart
        │
        ├── admin/                                  # §4 Admin Features
        │   ├── screens/
        │   │   ├── admin_dashboard_screen.dart
        │   │   ├── manage_teachers_screen.dart
        │   │   ├── manage_students_screen.dart
        │   │   ├── manage_content_screen.dart
        │   │   ├── add_content_screen.dart
        │   │   └── analytics_screen.dart
        │   └── widgets/
        │       └── analytics_card.dart
        │
        └── parent/                                 # §2.8 Parent Access
            └── screens/
                ├── parent_dashboard_screen.dart
                ├── child_attendance_screen.dart
                ├── child_payments_screen.dart
                └── child_performance_screen.dart
```

---

## Build order (recommended)

1. **Core + Auth** — `core/`, `models/user_model.dart`, `services/auth_service.dart`, `providers/auth_provider.dart`, `features/auth/*`, `features/onboarding/*`
2. **Rooms** — `room_model.dart`, `room_service.dart`, `room_provider.dart`, teacher's create/list/detail screens + student's join/feed screens
3. **Attendance** (incl. offline sync) — `attendance_model.dart`, `attendance_service.dart`, `offline_sync_service.dart`, teacher + student attendance screens
4. **Messaging & Polls**
5. **Payments & Dues**
6. **Assignments & Exams/Leaderboard**
7. **Admin (content + analytics)**
8. **Parent access**
9. **Notifications wiring** (push notifications should be layered in as each feature above is completed, since every feature triggers at least one notification type)

---

## Status legend
- ✅ done = file already created in this conversation
- Everything else = folder/filename only, to be created empty now and filled in during its build phase

**Next up when you're ready:** `core/theme/app_theme.dart` + `core/routes/app_router.dart`/`route_names.dart` (needed to make `app.dart` compile), then `models/user_model.dart` + `services/auth_service.dart` to start Phase 1.
