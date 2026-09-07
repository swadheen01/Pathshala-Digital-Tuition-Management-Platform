/// Central registry of route paths and names.
/// Import this instead of hardcoding path strings when navigating,
/// e.g. context.go(RouteNames.teacherDashboard) instead of context.go('/teacher').
class RouteNames {
  RouteNames._();

  // --- Onboarding / Auth ---
  static const String splash = '/';
  static const String languageSelect = '/language';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  static const String roleSelection = '/role-selection';
  static const String profileSetup = '/profile-setup';

  // --- Shared ---
  static const String calendar = '/calendar';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // --- Teacher ---
  static const String teacherDashboard = '/teacher';
  static const String roomList = '/teacher/rooms';
  static const String createRoom = '/teacher/rooms/create';
  static const String roomDetail = '/teacher/rooms/:roomId';
  static const String roomSchedule = '/teacher/rooms/:roomId/schedule';
  static const String studentList = '/teacher/rooms/:roomId/students';
  static const String addStudent = '/teacher/rooms/:roomId/students/add';
  static const String attendance = '/teacher/rooms/:roomId/attendance';
  static const String attendanceSummary =
      '/teacher/rooms/:roomId/attendance/summary';
  static const String messaging = '/teacher/rooms/:roomId/messages';
  static const String createPoll = '/teacher/rooms/:roomId/polls/create';
  static const String payments = '/teacher/rooms/:roomId/payments';
  static const String recordPayment =
      '/teacher/rooms/:roomId/payments/record';
  static const String paymentHistoryExport =
      '/teacher/rooms/:roomId/payments/export';
  static const String assignments = '/teacher/rooms/:roomId/assignments';
  static const String createAssignment =
      '/teacher/rooms/:roomId/assignments/create';
  static const String reviewSubmissions =
      '/teacher/rooms/:roomId/assignments/:assignmentId/submissions';
  static const String exams = '/teacher/rooms/:roomId/exams';
  static const String recordExamScore =
      '/teacher/rooms/:roomId/exams/:examId/record';
  static const String leaderboardSettings =
      '/teacher/rooms/:roomId/leaderboard-settings';
  static const String parentAccess = '/teacher/rooms/:roomId/parent-access';

  // --- Student ---
  static const String studentDashboard = '/student';
  static const String schoolTuitionTabs = '/student/home';
  static const String joinRoom = '/student/join-room';
  static const String roomFeed = '/student/rooms/:roomId';
  static const String studentAssignments = '/student/rooms/:roomId/assignments';
  static const String attendanceView = '/student/rooms/:roomId/attendance';
  static const String assignmentSubmission =
      '/student/rooms/:roomId/assignments/:assignmentId';
  static const String examPerformance = '/student/rooms/:roomId/performance';
  static const String leaderboard = '/student/rooms/:roomId/leaderboard';
  static const String contentFeed = '/student/content';
  static const String contentSearch = '/student/content/search';

  // --- Admin ---
  static const String adminDashboard = '/admin';
  static const String manageTeachers = '/admin/teachers';
  static const String manageStudents = '/admin/students';
  static const String manageContent = '/admin/content';
  static const String addContent = '/admin/content/add';
  static const String analytics = '/admin/analytics';

  // --- Parent ---
  static const String parentDashboard = '/parent';
  static const String childAttendance = '/parent/child/:childId/attendance';
  static const String childPayments = '/parent/child/:childId/payments';
  static const String childPerformance = '/parent/child/:childId/performance';
}
