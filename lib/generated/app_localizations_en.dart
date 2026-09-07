// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pathshala';

  @override
  String get home => 'Home';

  @override
  String get calendar => 'Calendar';

  @override
  String get alerts => 'Alerts';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String failedToLoad(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String welcomeTeacher(Object name) {
    return 'Welcome, $name';
  }

  @override
  String roomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rooms',
      one: '1 Room',
    );
    return '$_temp0';
  }

  @override
  String get manageRooms => 'Tap to manage your tuition rooms';

  @override
  String get createRoom => 'Create a new room';

  @override
  String get room => 'Room';

  @override
  String failedToLoadRoom(Object error) {
    return 'Failed to load room: $error';
  }

  @override
  String joinCode(Object code) {
    return 'Join code: $code';
  }

  @override
  String get students => 'Students';

  @override
  String get attendance => 'Attendance';

  @override
  String get classSchedule => 'Class Schedule';

  @override
  String get messagesPolls => 'Messages & Polls';

  @override
  String get paymentsDues => 'Payments & Dues';

  @override
  String get assignments => 'Assignments';

  @override
  String get examsLeaderboard => 'Exams & Leaderboard';

  @override
  String get parentAccess => 'Parent Access';
}
