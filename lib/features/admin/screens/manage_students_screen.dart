import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_provider.dart';

/// Admin manages student accounts (spec §4).
class ManageStudentsScreen extends ConsumerWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(allStudentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load students. Please try again.')),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students registered yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = students[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(s.fullName.isNotEmpty
                        ? s.fullName[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(s.fullName),
                  subtitle: Text([
                    if (s.classGrade != null) s.classGrade!,
                    if (s.institution != null) s.institution!,
                  ].join(' · ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove student?'),
                          content: Text('Remove ${s.fullName}\'s account?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(adminControllerProvider.notifier)
                            .deleteUser(s.id);
                        ref.invalidate(allStudentsProvider);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
