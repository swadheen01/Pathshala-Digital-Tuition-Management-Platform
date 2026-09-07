/// Date helpers, mainly for class-day scheduling (spec §2.5) where
/// weekday conventions need converting between Dart's and the app's.
class AppDateUtils {
  AppDateUtils._();

  static const List<String> weekdayLabels = [
    '', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  /// Converts Dart's DateTime.weekday (1=Mon..7=Sun) to the app's
  /// convention (1=Sun..7=Sat), used throughout room.classDays.
  static int toAppWeekday(DateTime date) {
    return date.weekday == 7 ? 1 : date.weekday + 1;
  }

  static bool isClassDay(DateTime date, List<int> classDays) {
    return classDays.contains(toAppWeekday(date));
  }

  static String formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String classDaysLabel(List<int> days) {
    if (days.isEmpty) return 'No schedule set';
    final sorted = [...days]..sort();
    return sorted.map((d) => weekdayLabels[d]).join(', ');
  }
}
