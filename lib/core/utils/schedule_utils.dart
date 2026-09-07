import 'package:flutter/material.dart';

import '../../models/room_model.dart';

/// Where a room's next / current session falls, resolved from its
/// `classDays` (1=Sun..7=Sat) and optional start/end time.
class ClassOccurrence {
  const ClassOccurrence({
    required this.room,
    required this.start,
    this.end,
  });

  final RoomModel room;

  /// Absolute start of this occurrence.
  final DateTime start;
  final DateTime? end;

  bool isLiveAt(DateTime now) {
    if (now.isBefore(start)) return false;
    final e = end;
    if (e != null) return now.isBefore(e);
    // Day-only schedule: treat the whole calendar day as "today's class".
    return now.year == start.year &&
        now.month == start.month &&
        now.day == start.day;
  }

  bool get isToday {
    final now = DateTime.now();
    return start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
  }
}

/// Dart `DateTime.weekday` is 1=Mon..7=Sun; the app uses 1=Sun..7=Sat.
int _appWeekday(DateTime d) => d.weekday == DateTime.sunday ? 1 : d.weekday + 1;

/// The next occurrence of [room] at or after [from] (looks up to 8 days
/// ahead). Null if the room has no class days.
ClassOccurrence? nextOccurrence(RoomModel room, {DateTime? from}) {
  if (room.classDays.isEmpty) return null;
  final now = from ?? DateTime.now();
  final start = room.startTime;
  final end = room.endTime;

  for (var i = 0; i < 8; i++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
    if (!room.classDays.contains(_appWeekday(day))) continue;

    final occStart = start == null
        ? day
        : DateTime(day.year, day.month, day.day, start.hour, start.minute);
    final occEnd = end == null
        ? null
        : DateTime(day.year, day.month, day.day, end.hour, end.minute);

    // Skip an occurrence that has already finished today.
    if (occEnd != null && occEnd.isBefore(now)) continue;
    if (start != null && occEnd == null && occStart.isBefore(now)) continue;

    return ClassOccurrence(room: room, start: occStart, end: occEnd);
  }
  return null;
}

/// Across [rooms]: the one live right now (if any) and the soonest one
/// coming up.
({ClassOccurrence? live, ClassOccurrence? next}) resolveClasses(
  List<RoomModel> rooms, {
  DateTime? at,
}) {
  final now = at ?? DateTime.now();
  ClassOccurrence? live;
  ClassOccurrence? next;

  for (final room in rooms) {
    final occ = nextOccurrence(room, from: now);
    if (occ == null) continue;
    if (occ.isLiveAt(now) && occ.room.startTime != null) {
      if (live == null || occ.start.isBefore(live.start)) live = occ;
    } else {
      if (next == null || occ.start.isBefore(next.start)) next = occ;
    }
  }
  return (live: live, next: next);
}

String formatOccurrence(ClassOccurrence occ, BuildContext context) {
  final start = occ.room.startTime;
  final dayLabel = occ.isToday
      ? 'Today'
      : const ['', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][
          _appWeekday(occ.start)];
  if (start == null) return dayLabel;
  final t = start.format(context);
  final e = occ.room.endTime;
  return e == null ? '$dayLabel · $t' : '$dayLabel · $t–${e.format(context)}';
}
