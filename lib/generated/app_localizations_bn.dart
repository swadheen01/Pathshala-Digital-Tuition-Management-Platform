// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'পাঠশালা';

  @override
  String get home => 'হোম';

  @override
  String get calendar => 'ক্যালেন্ডার';

  @override
  String get alerts => 'নোটিশ';

  @override
  String get settings => 'সেটিংস';

  @override
  String get notifications => 'নোটিফিকেশন';

  @override
  String get markAllRead => 'সব পড়া হিসেবে চিহ্নিত করুন';

  @override
  String get noNotifications => 'এখনও কোনো নোটিফিকেশন নেই।';

  @override
  String failedToLoad(Object error) {
    return 'লোড করা যায়নি: $error';
  }

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String welcomeTeacher(Object name) {
    return 'স্বাগতম, $name';
  }

  @override
  String roomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রুম',
      one: '১টি রুম',
    );
    return '$_temp0';
  }

  @override
  String get manageRooms => 'আপনার টিউশন রুম পরিচালনা করতে ট্যাপ করুন';

  @override
  String get createRoom => 'নতুন রুম তৈরি করুন';

  @override
  String get room => 'রুম';

  @override
  String failedToLoadRoom(Object error) {
    return 'রুম লোড করা যায়নি: $error';
  }

  @override
  String joinCode(Object code) {
    return 'যোগদানের কোড: $code';
  }

  @override
  String get students => 'শিক্ষার্থীরা';

  @override
  String get attendance => 'উপস্থিতি';

  @override
  String get classSchedule => 'ক্লাসের সময়সূচি';

  @override
  String get messagesPolls => 'মেসেজ ও পোল';

  @override
  String get paymentsDues => 'পেমেন্ট ও বকেয়া';

  @override
  String get assignments => 'অ্যাসাইনমেন্ট';

  @override
  String get examsLeaderboard => 'পরীক্ষা ও লিডারবোর্ড';

  @override
  String get parentAccess => 'অভিভাবক অ্যাক্সেস';
}
