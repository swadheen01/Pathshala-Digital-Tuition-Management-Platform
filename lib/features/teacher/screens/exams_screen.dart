import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../models/exam_model.dart';
import '../../../providers/exam_provider.dart';

/// Teacher's list of exams for a room, with quick "add exam" dialog
/// (spec §2.7). Tapping an exam opens score recording.
class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key, required this.roomId});

  final String roomId;

  Future<void> _showCreateExamDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final maxMarksController = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Exam'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Exam Title'),
                validator: (v) => Validators.required(v, fieldName: 'Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxMarksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Marks'),
                validator: Validators.amount,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      await ref.read(examControllerProvider.notifier).createExam(
            roomId: roomId,
            title: titleController.text.trim(),
            maxMarks: double.parse(maxMarksController.text.trim()),
          );
      ref.invalidate(roomExamsProvider(roomId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(roomExamsProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Leaderboard Settings',
            onPressed: () => context.push(
              '/teacher/rooms/$roomId/leaderboard-settings',
            ),
          ),
        ],
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load exams. Please try again.')),
        data: (exams) {
          if (exams.isEmpty) {
            return const Center(
              child: Text('No exams yet.\nTap + to add one.',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ExamCard(exam: exams[index], roomId: roomId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateExamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.roomId});
  final ExamModel exam;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(exam.title),
        subtitle: Text('Max marks: ${exam.maxMarks.toStringAsFixed(0)}'
            '${exam.examDate != null ? ' · ${exam.examDate!.day}/${exam.examDate!.month}/${exam.examDate!.year}' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          '/teacher/rooms/$roomId/exams/${exam.id}/record',
        ),
      ),
    );
  }
}
