import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/room_provider.dart';

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Edit which weekdays this room holds class, and (optionally) the class
/// time window (spec §2.5). Attendance dates are restricted to these days;
/// the time drives the home-screen "class on now / next" card.
class RoomScheduleScreen extends ConsumerStatefulWidget {
  const RoomScheduleScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RoomScheduleScreen> createState() => _RoomScheduleScreenState();
}

class _RoomScheduleScreenState extends ConsumerState<RoomScheduleScreen> {
  Set<int>? _selectedDays;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _seeded = false;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _save() async {
    if (_selectedDays == null) return;
    final ok = await ref.read(roomControllerProvider.notifier).updateRoomSettings(
          widget.roomId,
          classDays: _selectedDays!.toList()..sort(),
        );
    // Times go through the service directly (updateRoomSettings doesn't
    // carry them) — reuse the room service.
    await ref.read(roomServiceProvider).updateRoom(
          widget.roomId,
          clearTimes: _start == null || _end == null,
          classStartTime: _start == null ? null : _fmt(_start!),
          classEndTime: _end == null ? null : _fmt(_end!),
        );

    if (!mounted) return;
    ref.invalidate(roomByIdProvider(widget.roomId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(ok ? 'Schedule updated' : 'Failed to update')));
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));
    final busy = ref.watch(roomControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Class schedule')),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load the schedule. Please try again.')),
        data: (room) {
          if (!_seeded) {
            _selectedDays = room.classDays.toSet();
            _start = room.startTime;
            _end = room.endTime;
            _seeded = true;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Class days',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final weekday = i + 1;
                  return FilterChip(
                    label: Text(_weekdayLabels[i]),
                    selected: _selectedDays!.contains(weekday),
                    onSelected: (v) => setState(() {
                      v
                          ? _selectedDays!.add(weekday)
                          : _selectedDays!.remove(weekday);
                    }),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Text('Class time (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              const Text(
                'Set a start and end time to show students and yourself '
                'which class is on now and what\'s next.',
                style: TextStyle(color: Color(0xFF70655D), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Starts',
                      value: _start,
                      onPick: (t) => setState(() => _start = t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Ends',
                      value: _end,
                      onPick: (t) => setState(() => _end = t),
                    ),
                  ),
                ],
              ),
              if (_start != null || _end != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _start = _end = null),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear time'),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: busy ? null : _save,
                child: const Text('Save schedule'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? const TimeOfDay(hour: 17, minute: 0),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xD9FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppTheme.skyBlue, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF70655D))),
                Text(
                  value == null ? '—' : value!.format(context),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
