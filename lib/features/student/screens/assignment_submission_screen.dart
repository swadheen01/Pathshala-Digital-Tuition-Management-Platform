import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/assignment_model.dart';
import '../../../providers/assignment_provider.dart';

/// Student views assignment details and submits a text response
/// (spec §2.6, §3). File/image submission uses the same flow once
/// storage_service.dart (later phase) provides an upload URL.
class AssignmentSubmissionScreen extends ConsumerStatefulWidget {
  const AssignmentSubmissionScreen({
    super.key,
    required this.roomId,
    required this.assignmentId,
  });

  final String roomId;
  final String assignmentId;

  @override
  ConsumerState<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends ConsumerState<AssignmentSubmissionScreen> {
  final _textController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_textController.text.trim().isEmpty) return;

    final success =
        await ref.read(assignmentControllerProvider.notifier).submit(
              assignmentId: widget.assignmentId,
              type: SubmissionType.text,
              textContent: _textController.text.trim(),
            );

    if (!mounted) return;

    ref.invalidate(mySubmissionProvider(widget.assignmentId));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Submitted!' : 'Failed to submit'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentAsync =
        ref.watch(assignmentByIdProvider(widget.assignmentId));
    final mySubmissionAsync =
        ref.watch(mySubmissionProvider(widget.assignmentId));
    final controllerState = ref.watch(assignmentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment')),
      body: assignmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load assignment. Please try again.')),
        data: (assignment) {
          return mySubmissionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
                child: Text('Unable to load submissions. Please try again.')),
            data: (mySubmission) {
              if (mySubmission != null && !_prefilled) {
                _textController.text = mySubmission.textContent ?? '';
                _prefilled = true;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(assignment.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (assignment.description != null) ...[
                      const SizedBox(height: 16),
                      Text(assignment.description!),
                    ],
                    const Divider(height: 32),
                    if (mySubmission?.isGraded == true) ...[
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Grade: ${mySubmission!.grade}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              if (mySubmission.feedback != null)
                                Text(mySubmission.feedback!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text('Your Answer',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Type your answer here…',
                      ),
                      enabled: !controllerState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          controllerState.isLoading ? null : _handleSubmit,
                      child: controllerState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(mySubmission != null
                              ? 'Update Submission'
                              : 'Submit'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
