import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_provider.dart';

/// Admin manages teacher accounts (spec §4).
class ManageTeachersScreen extends ConsumerWidget {
  const ManageTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(allTeachersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      body: teachersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load teachers. Please try again.')),
        data: (teachers) {
          if (teachers.isEmpty) {
            return const Center(child: Text('No teachers registered yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = teachers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(t.fullName.isNotEmpty
                        ? t.fullName[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(t.fullName),
                  subtitle: Text(t.email ?? t.phone ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove teacher?'),
                          content: Text(
                              'This will remove ${t.fullName} and all their rooms.'),
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
                            .deleteUser(t.id);
                        ref.invalidate(allTeachersProvider);
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
