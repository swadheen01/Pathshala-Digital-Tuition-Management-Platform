import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../providers/auth_provider.dart';
import '../../features/admin/screens/add_content_screen.dart';
import '../../features/admin/screens/analytics_screen.dart';
import '../../features/admin/screens/manage_content_screen.dart';
import '../../features/admin/screens/manage_students_screen.dart';
import '../../features/admin/screens/manage_teachers_screen.dart';
import '../../features/parent/screens/child_attendance_screen.dart';
import '../../features/parent/screens/child_payments_screen.dart';
import '../../features/parent/screens/child_performance_screen.dart';
import '../../features/shared/screens/home_shell_screen.dart';
import '../../features/shared/screens/messaging_screen.dart';
import '../../features/shared/screens/profile_screen.dart';
import '../../features/shared/screens/settings_screen.dart';
import '../../features/student/screens/content_feed_screen.dart';
import '../../features/student/screens/content_search_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/student/screens/assignment_submission_screen.dart';
import '../../features/student/screens/attendance_view_screen.dart';
import '../../features/student/screens/exam_performance_screen.dart';
import '../../features/student/screens/join_room_screen.dart';
import '../../features/student/screens/leaderboard_screen.dart';
import '../../features/student/screens/room_feed_screen.dart';
import '../../features/student/screens/student_assignments_screen.dart';
import '../../features/teacher/screens/add_student_screen.dart';
import '../../features/teacher/screens/assignments_screen.dart';
import '../../features/teacher/screens/attendance_screen.dart';
import '../../features/teacher/screens/attendance_summary_screen.dart';
import '../../features/teacher/screens/create_assignment_screen.dart';
import '../../features/teacher/screens/create_poll_screen.dart';
import '../../features/teacher/screens/create_room_screen.dart';
import '../../features/teacher/screens/exams_screen.dart';
import '../../features/teacher/screens/leaderboard_settings_screen.dart';
import '../../features/teacher/screens/parent_access_screen.dart';
import '../../features/teacher/screens/payment_history_export_screen.dart';
import '../../features/teacher/screens/payments_screen.dart';
import '../../features/teacher/screens/record_exam_score_screen.dart';
import '../../features/teacher/screens/record_payment_screen.dart';
import '../../features/teacher/screens/review_submissions_screen.dart';
import '../../features/teacher/screens/room_detail_screen.dart';
import '../../features/teacher/screens/room_list_screen.dart';
import '../../features/teacher/screens/room_schedule_screen.dart';
import '../../features/teacher/screens/student_list_screen.dart';
import '../../models/user_model.dart';
import 'route_names.dart';

/// Temporary placeholder screen for routes that are not implemented yet.
/// Once a real screen file is built (e.g. LoginScreen), swap it in below
/// and delete the corresponding _Placeholder call.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          '$label\n(screen not built yet)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// A [Listenable] that fires whenever the auth gate changes, so GoRouter
/// re-evaluates its `redirect`. This is what makes the email-confirmation
/// / OAuth deep link actually move the user forward: the moment
/// supabase_flutter delivers the session, [authGateProvider] recomputes
/// and the router redirects to the right place.
class _AuthRouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

String _dashboardRouteFor(UserRole? role) {
  switch (role) {
    case UserRole.teacher:
      return RouteNames.teacherDashboard;
    case UserRole.admin:
      return RouteNames.adminDashboard;
    case UserRole.parent:
      return RouteNames.parentDashboard;
    case UserRole.student:
    case null:
      return RouteNames.studentDashboard;
  }
}

const _publicRoutes = <String>{
  RouteNames.login,
  RouteNames.signup,
  RouteNames.otpVerification,
  RouteNames.forgotPassword,
  RouteNames.languageSelect,
};

const _onboardingRoutes = <String>{
  RouteNames.roleSelection,
  RouteNames.profileSetup,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(authGateProvider, (_, __) => refresh.ping());

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,

    redirect: (context, state) {
      final gate = ref.read(authGateProvider);
      final loc = state.matchedLocation;

      // 1. Auth state not resolved yet — hold on the splash screen.
      if (gate.isResolving) {
        return loc == RouteNames.splash ? null : RouteNames.splash;
      }

      // 2. Signed out — only public routes are reachable.
      if (!gate.isAuthenticated) {
        if (_publicRoutes.contains(loc)) return null;
        return RouteNames.login;
      }

      // 3. Signed in but onboarding is incomplete.
      if (gate.step == OnboardingStep.chooseRole) {
        return loc == RouteNames.roleSelection
            ? null
            : RouteNames.roleSelection;
      }
      if (gate.step == OnboardingStep.completeProfile) {
        return loc == RouteNames.profileSetup ? null : RouteNames.profileSetup;
      }

      // 4. Fully onboarded — never sit on splash / auth / onboarding.
      if (loc == RouteNames.splash ||
          _publicRoutes.contains(loc) ||
          _onboardingRoutes.contains(loc)) {
        return _dashboardRouteFor(gate.role);
      }
      return null;
    },

    routes: [
      // --- Onboarding / Auth ---
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.languageSelect,
        builder: (context, state) =>
            const _PlaceholderScreen('Language Select'),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RouteNames.otpVerification,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, String>) {
            return OtpVerificationScreen(email: extra['email'] ?? '');
          }
          return OtpVerificationScreen(email: extra as String? ?? '');
        },
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) =>
            ForgotPasswordScreen(initialEmail: state.extra as String?),
      ),
      GoRoute(
        path: RouteNames.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        builder: (context, state) =>
            ProfileSetupScreen(role: state.extra as UserRole?),
      ),

      // --- Shared ---
      GoRoute(
        path: RouteNames.calendar,
        builder: (context, state) => const _PlaceholderScreen('Calendar'),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // --- Teacher ---
      GoRoute(
        path: RouteNames.teacherDashboard,
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: RouteNames.roomList,
        builder: (context, state) => const RoomListScreen(),
      ),
      GoRoute(
        path: RouteNames.createRoom,
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: RouteNames.roomDetail,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.attendance,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return AttendanceScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.attendanceSummary,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return AttendanceSummaryScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.studentList,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return StudentListScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.addStudent,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final edit = state.extra as AddStudentArgs?;
          return AddStudentScreen(
            roomId: roomId,
            editMemberId: edit?.memberId,
            initialName: edit?.name,
            initialRoll: edit?.roll,
            initialPhone: edit?.phone,
            initialEmail: edit?.email,
            initialFee: edit?.fee,
          );
        },
      ),
      GoRoute(
        path: RouteNames.roomSchedule,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomScheduleScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.messaging,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return MessagingScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.createPoll,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return CreatePollScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.payments,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return PaymentsScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.recordPayment,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RecordPaymentScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.paymentHistoryExport,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return PaymentHistoryExportScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.assignments,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return AssignmentsScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.createAssignment,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return CreateAssignmentScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.reviewSubmissions,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final assignmentId = state.pathParameters['assignmentId']!;
          return ReviewSubmissionsScreen(
            roomId: roomId,
            assignmentId: assignmentId,
          );
        },
      ),
      GoRoute(
        path: RouteNames.exams,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ExamsScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.recordExamScore,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final examId = state.pathParameters['examId']!;
          return RecordExamScoreScreen(roomId: roomId, examId: examId);
        },
      ),
      GoRoute(
        path: RouteNames.leaderboardSettings,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return LeaderboardSettingsScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.parentAccess,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ParentAccessScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.payments,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return PaymentsScreen(roomId: roomId);
        },
      ),

      // --- Student ---
      GoRoute(
        path: RouteNames.studentDashboard,
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: RouteNames.joinRoom,
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: RouteNames.roomFeed,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomFeedScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.studentAssignments,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return StudentAssignmentsScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.examPerformance,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ExamPerformanceScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.leaderboard,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return LeaderboardScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.contentFeed,
        builder: (context, state) => const ContentFeedScreen(),
      ),
      GoRoute(
        path: RouteNames.contentSearch,
        builder: (context, state) => const ContentSearchScreen(),
      ),
      GoRoute(
        path: RouteNames.attendanceView,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return AttendanceViewScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.assignmentSubmission,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final assignmentId = state.pathParameters['assignmentId']!;
          return AssignmentSubmissionScreen(
            roomId: roomId,
            assignmentId: assignmentId,
          );
        },
      ),

      // --- Admin ---
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: RouteNames.manageTeachers,
        builder: (context, state) => const ManageTeachersScreen(),
      ),
      GoRoute(
        path: RouteNames.manageStudents,
        builder: (context, state) => const ManageStudentsScreen(),
      ),
      GoRoute(
        path: RouteNames.manageContent,
        builder: (context, state) => const ManageContentScreen(),
      ),
      GoRoute(
        path: RouteNames.addContent,
        builder: (context, state) => const AddContentScreen(),
      ),
      GoRoute(
        path: RouteNames.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // --- Parent ---
      GoRoute(
        path: RouteNames.parentDashboard,
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: RouteNames.childAttendance,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          final roomId = state.extra as String? ?? '';
          return ChildAttendanceScreen(childId: childId, roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.childPayments,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          final roomId = state.extra as String? ?? '';
          return ChildPaymentsScreen(childId: childId, roomId: roomId);
        },
      ),
      GoRoute(
        path: RouteNames.childPerformance,
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          final roomId = state.extra as String? ?? '';
          return ChildPerformanceScreen(childId: childId, roomId: roomId);
        },
      ),
    ],
  );
});
