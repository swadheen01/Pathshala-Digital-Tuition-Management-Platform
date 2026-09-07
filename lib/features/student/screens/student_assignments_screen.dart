import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../models/assignment_model.dart';
import '../../../providers/assignment_provider.dart';

/// Student's list of assignments in a room (spec §3). Tapping one opens
/// AssignmentSubmissionScreen to view details/submit.
class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(roomAssignmentsProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load assignments. Please try again.')),
        data: (assignments) {
          if (assignments.isEmpty) {
            return const Center(child: Text('No assignments yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final a = assignments[index];
              return _AssignmentTile(assignment: a, roomId: roomId);
            },
          );
        },
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment, required this.roomId});
  final AssignmentModel assignment;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(assignment.title),
        subtitle: Text(
          'Due ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          RouteNames.assignmentSubmission
              .replaceFirst(':roomId', roomId)
              .replaceFirst(':assignmentId', assignment.id),
        ),
      ),
    );
  }
}
