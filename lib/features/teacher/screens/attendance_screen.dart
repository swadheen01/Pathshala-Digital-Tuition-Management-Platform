import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/attendance_provider.dart';
import '../../../providers/room_provider.dart';

/// Teacher marks attendance (tick/check per student) for a specific
/// date (spec §2.3). Date picker is restricted to the room's configured
/// class_days (spec §2.5). Works offline via OfflineSyncService.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _presentMap = {};
  bool _loadedForDate = false;

  /// Only allow picking dates matching the room's class_days (spec §2.5).
  bool _isSelectable(List<int> classDays, DateTime day) {
    // Dart's DateTime.weekday is 1=Mon..7=Sun; convert to our 1=Sun..7=Sat.
    final ourWeekday = day.weekday == 7 ? 1 : day.weekday + 1;
    return classDays.contains(ourWeekday);
  }

  Future<void> _pickDate(List<int> classDays) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      selectableDayPredicate: (day) => _isSelectable(classDays, day),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadedForDate = false;
        _presentMap.clear();
      });
    }
  }

  Future<void> _handleSave() async {
    final success =
        await ref.read(attendanceControllerProvider.notifier).markAttendance(
              roomId: widget.roomId,
              date: _selectedDate,
              presentMap: _presentMap,
            );

    if (!mounted) return;

    ref.invalidate(roomSummaryProvider(widget.roomId));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Attendance saved'
              : 'No connection — saved locally, will sync automatically',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final controllerState = ref.watch(attendanceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          roomAsync.maybeWhen(
            data: (room) => IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _pickDate(room.classDays),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load students. Please try again.')),
        data: (members) {
          if (!_loadedForDate) {
            // Pre-fill from existing attendance for this date, if any.
            ref
                .read(attendanceServiceProviderForPrefill)
                .fetchAttendanceForDate(
                  roomId: widget.roomId,
                  date: _selectedDate,
                )
                .then((existing) {
              if (mounted) {
                setState(() {
                  for (final m in members) {
                    _presentMap[m.member.refId] =
                        existing[m.member.refId] ?? true;
                  }
                  _loadedForDate = true;
                });
              }
            });
          }

          if (members.isEmpty) {
            return const Center(child: Text('No students in this room yet.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final studentId = member.member.refId;
                    final present = _presentMap[studentId] ?? true;

                    return CheckboxListTile(
                      title: Text(member.studentName),
                      subtitle: member.member.rollNumber != null
                          ? Text('Roll: ${member.member.rollNumber}')
                          : null,
                      value: present,
                      onChanged: (value) {
                        setState(() {
                          _presentMap[studentId] = value ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: controllerState.isLoading ? null : _handleSave,
                  child: controllerState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Attendance'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
