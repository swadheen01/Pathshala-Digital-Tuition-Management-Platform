import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../models/assignment_model.dart';
import '../../../providers/assignment_provider.dart';

/// Teacher's list of assignments posted to a room (spec §2.6).
class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key, required this.roomId});

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
            return const Center(
              child: Text('No assignments yet.\nTap + to post one.',
                  textAlign: TextAlign.center),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _AssignmentCard(assignment: assignments[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          RouteNames.createAssignment.replaceFirst(':roomId', roomId),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});
  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(assignment.title),
        subtitle: Text(
          'Due ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
        ),
        trailing: assignment.isOverdue
            ? Chip(
                label: const Text('Overdue'),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              )
            : const Icon(Icons.chevron_right),
        onTap: () => context.push(
          RouteNames.reviewSubmissions
              .replaceFirst(':roomId', assignment.roomId)
              .replaceFirst(':assignmentId', assignment.id),
        ),
      ),
    );
  }
}
