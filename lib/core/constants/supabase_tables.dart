/// Table/column/RPC name constants — avoids typos like 'roomm_id' that
/// the Dart compiler can't catch since these are just strings passed
/// to PostgREST. Not exhaustive; add to this as new tables are added.
class SupabaseTables {
  SupabaseTables._();

  static const String profiles = 'profiles';
  static const String rooms = 'rooms';
  static const String roomMembers = 'room_members';
  static const String attendance = 'attendance';
  static const String messages = 'messages';
  static const String polls = 'polls';
  static const String pollOptions = 'poll_options';
  static const String pollVotes = 'poll_votes';
  static const String payments = 'payments';
  static const String assignments = 'assignments';
  static const String submissions = 'submissions';
  static const String exams = 'exams';
  static const String examScores = 'exam_scores';
  static const String content = 'content';
  static const String contentViews = 'content_views';
  static const String notifications = 'notifications';
  static const String parentLinks = 'parent_links';
}

class SupabaseRpcs {
  SupabaseRpcs._();

  static const String joinRoom = 'join_room';
  static const String getAttendanceSummary = 'get_attendance_summary';
  static const String getLeaderboard = 'get_leaderboard';
  static const String getPlatformAnalytics = 'get_platform_analytics';
}
