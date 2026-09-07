import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/room_provider.dart';

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Teacher creates a new tuition room with its class-day schedule and an
/// optional class time window (spec §2.1, §2.5).
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final Set<int> _days = {};
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one class day')),
      );
      return;
    }

    final room = await ref.read(roomControllerProvider.notifier).createRoom(
          name: _name.text.trim(),
          subject: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          classDays: _days.toList()..sort(),
          classStartTime: _start == null ? null : _fmt(_start!),
          classEndTime: _end == null ? null : _fmt(_end!),
        );
    if (!mounted) return;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to create room: '
            '${ref.read(roomControllerProvider).error}'),
      ));
      return;
    }

    ref.invalidate(teacherRoomsProvider);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room created 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this join code with your students:'),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: room.joinCode));
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  room.joinCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to copy',
                style: TextStyle(fontSize: 11, color: Color(0xFF70655D))),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(roomControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create a room')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Room name',
                    hintText: 'e.g. Physics Batch A',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Room name'),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                Text('Class days',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text('Attendance can only be marked on selected days.',
                    style: TextStyle(color: Color(0xFF70655D), fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final weekday = i + 1;
                    return FilterChip(
                      label: Text(_weekdayLabels[i]),
                      selected: _days.contains(weekday),
                      onSelected: isLoading
                          ? null
                          : (v) => setState(() {
                                v
                                    ? _days.add(weekday)
                                    : _days.remove(weekday);
                              }),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Text('Class time (optional)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimePill(
                        label: 'Starts',
                        value: _start,
                        onPick: (t) => setState(() => _start = t),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePill(
                        label: 'Ends',
                        value: _end,
                        onPick: (t) => setState(() => _end = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : _create,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill(
      {required this.label, required this.value, required this.onPick});
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: value ?? const TimeOfDay(hour: 17, minute: 0),
        );
        if (t != null) onPick(t);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xD9FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: AppTheme.skyBlue),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF70655D))),
                Text(value == null ? '—' : value!.format(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
