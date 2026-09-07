import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/assignment_model.dart';
import '../../../providers/assignment_provider.dart';

/// Teacher reviews submissions for an assignment and assigns
/// grades/feedback (spec §2.6).
class ReviewSubmissionsScreen extends ConsumerWidget {
  const ReviewSubmissionsScreen({
    super.key,
    required this.roomId,
    required this.assignmentId,
  });

  final String roomId;
  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(assignmentByIdProvider(assignmentId));
    final submissionsAsync =
        ref.watch(assignmentSubmissionsProvider(assignmentId));

    return Scaffold(
      appBar: AppBar(
        title: assignmentAsync.maybeWhen(
          data: (a) => Text(a.title),
          orElse: () => const Text('Submissions'),
        ),
      ),
      body: submissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load submissions. Please try again.')),
        data: (submissions) {
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = submissions[index];
              return _SubmissionCard(
                submission: s,
                onGrade: () => _showGradeDialog(context, ref, s),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showGradeDialog(
    BuildContext context,
    WidgetRef ref,
    SubmissionModel submission,
  ) async {
    final gradeController = TextEditingController(text: submission.grade);
    final feedbackController = TextEditingController(text: submission.feedback);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${submission.studentName ?? 'Student'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(labelText: 'Grade / Marks'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && gradeController.text.trim().isNotEmpty) {
      await ref.read(assignmentControllerProvider.notifier).gradeSubmission(
            submissionId: submission.id,
            grade: gradeController.text.trim(),
            feedback: feedbackController.text.trim().isEmpty
                ? null
                : feedbackController.text.trim(),
          );
      ref.invalidate(assignmentSubmissionsProvider(submission.assignmentId));
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission, required this.onGrade});

  final SubmissionModel submission;
  final VoidCallback onGrade;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(submission.studentName ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium),
                if (submission.isGraded)
                  Chip(label: Text('Grade: ${submission.grade}')),
              ],
            ),
            const SizedBox(height: 8),
            if (submission.type == SubmissionType.text)
              Text(submission.textContent ?? '')
            else if (submission.fileUrl != null)
              Text('Attachment: ${submission.fileUrl}',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            if (submission.feedback != null) ...[
              const SizedBox(height: 8),
              Text('Feedback: ${submission.feedback}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onGrade,
                child: Text(submission.isGraded ? 'Edit Grade' : 'Grade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
