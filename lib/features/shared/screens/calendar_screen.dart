import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/widgets/app_nav_drawer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exam_provider.dart';
import '../../../providers/room_provider.dart';

/// In-app calendar showing scheduled class days, exam dates, and
/// (for teachers) a reminder of upcoming payment due dates, all in
/// one place (spec §1).
///
/// NOTE: exam dates currently only show across rooms the current user
/// is a member of / teaches; class-day recurrence is derived from each
/// room's `classDays` weekday list rather than stored as individual
/// events, so this screen computes occurrences for the visible month.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isTeacher = profileAsync.valueOrNull?.role.name == 'teacher';

    final roomsAsync = isTeacher
        ? ref.watch(teacherRoomsProvider)
        : ref.watch(studentRoomsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppNavDrawer(),
      appBar: AppBar(title: const Text('Calendar')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load calendar. Please try again.')),
        data: (rooms) {
          // Union of every room's class weekdays (1=Sun..7=Sat).
          final classDaySet = <int>{};
          for (final room in rooms) {
            classDaySet.addAll(room.classDays);
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    // Dart weekday 1=Mon..7=Sun → our 1=Sun..7=Sat.
                    final ourWeekday = day.weekday == 7 ? 1 : day.weekday + 1;
                    final isClassDay = classDaySet.contains(ourWeekday);
                    if (!isClassDay) return null;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}'),
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: rooms.isEmpty
                    ? const Center(
                        child: Text(
                            'Join or create a room to see class days here.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text('Class Days',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          for (final room in rooms)
                            Card(
                              child: ListTile(
                                title: Text(room.name),
                                subtitle: Text(_classDaysLabel(room.classDays)),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text('Upcoming Exams',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          for (final room in rooms)
                            _RoomExamsList(roomId: room.id),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _classDaysLabel(List<int> days) {
    const labels = ['', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (days.isEmpty) return 'No schedule set';
    return days.map((d) => labels[d]).join(', ');
  }
}

class _RoomExamsList extends ConsumerWidget {
  const _RoomExamsList({required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(roomExamsProvider(roomId));

    return examsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (exams) {
        final upcoming = exams
            .where((e) =>
                e.examDate != null && e.examDate!.isAfter(DateTime.now()))
            .toList();
        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          children: upcoming
              .map((e) => ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: Text(e.title),
                    subtitle: Text(_formatDate(e.examDate!)),
                  ))
              .toList(),
        );
      },
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
