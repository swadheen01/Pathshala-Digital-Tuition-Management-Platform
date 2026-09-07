import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/exam_provider.dart';
import '../../../providers/room_provider.dart';

/// Teacher enters marks for every student in a room, for one exam
/// (spec §2.7). Pre-fills existing scores if already recorded.
class RecordExamScoreScreen extends ConsumerStatefulWidget {
  const RecordExamScoreScreen({
    super.key,
    required this.roomId,
    required this.examId,
  });

  final String roomId;
  final String examId;

  @override
  ConsumerState<RecordExamScoreScreen> createState() =>
      _RecordExamScoreScreenState();
}

class _RecordExamScoreScreenState extends ConsumerState<RecordExamScoreScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final marksByStudent = <String, double>{};
    for (final entry in _controllers.entries) {
      final value = double.tryParse(entry.value.text.trim());
      if (value != null) marksByStudent[entry.key] = value;
    }

    final success =
        await ref.read(examControllerProvider.notifier).recordScores(
              examId: widget.examId,
              marksByStudent: marksByStudent,
            );

    if (!mounted) return;

    ref.invalidate(examScoresProvider(widget.examId));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Scores saved' : 'Failed to save')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final scoresAsync = ref.watch(examScoresProvider(widget.examId));
    final controllerState = ref.watch(examControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Scores')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load exams. Please try again.')),
        data: (members) {
          return scoresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
                child: Text('Unable to load students. Please try again.')),
            data: (existingScores) {
              if (!_prefilled) {
                for (final m in members) {
                  final existing = existingScores
                      .where((s) => s.studentId == m.member.refId)
                      .toList();
                  _controllers[m.member.refId] = TextEditingController(
                    text: existing.isNotEmpty
                        ? existing.first.marksObtained.toString()
                        : '',
                  );
                }
                _prefilled = true;
              }

              if (members.isEmpty) {
                return const Center(child: Text('No students in this room.'));
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(child: Text(m.studentName)),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _controllers[m.member.refId],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Marks',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                          : const Text('Save Scores'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
