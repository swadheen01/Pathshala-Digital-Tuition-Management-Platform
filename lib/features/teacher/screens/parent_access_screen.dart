import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/room_provider.dart';

/// Teacher grants a parent read-only access to a student's data
/// (spec §2.8). The parent must already have a Pathshala account.
class ParentAccessScreen extends ConsumerStatefulWidget {
  const ParentAccessScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ParentAccessScreen> createState() => _ParentAccessScreenState();
}

class _ParentAccessScreenState extends ConsumerState<ParentAccessScreen> {
  String? _selectedStudentId;

  Future<void> _showGrantDialog() async {
    if (_selectedStudentId == null) return;

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Parent's Email"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
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
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(parentControllerProvider.notifier).grantAccess(
                parentEmail: emailController.text.trim(),
                studentId: _selectedStudentId!,
              );

      if (!mounted) return;

      if (!success) {
        final state = ref.read(parentControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${state.error}')),
        );
        return;
      }

      ref.invalidate(roomParentLinksProvider(widget.roomId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Access granted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final linksAsync = ref.watch(roomParentLinksProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Access')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            membersAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) =>
                  const Text('Unable to load students. Please try again.'),
              data: (members) {
                // Parent access links to a real account, so name-only
                // roster students aren't eligible until they've joined.
                final linkable =
                    members.where((m) => m.member.isClaimed).toList();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedStudentId,
                  decoration: InputDecoration(
                    labelText: 'Student',
                    helperText: linkable.length == members.length
                        ? null
                        : 'Students with no account yet are hidden.',
                  ),
                  items: linkable
                      .map((m) => DropdownMenuItem(
                            value: m.member.studentId,
                            child: Text(m.studentName),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedStudentId = value),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedStudentId == null ? null : _showGrantDialog,
              child: const Text('Grant Parent Access'),
            ),
            const SizedBox(height: 24),
            Text('Existing Links',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: linksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                    child: Text(
                        'Unable to load access settings. Please try again.')),
                data: (links) {
                  if (links.isEmpty) {
                    return const Center(child: Text('No parent links yet.'));
                  }
                  return ListView.builder(
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return ListTile(
                        leading: const Icon(Icons.family_restroom),
                        title: Text(link.studentName ?? 'Unknown'),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            await ref
                                .read(parentControllerProvider.notifier)
                                .revokeAccess(link.id);
                            ref.invalidate(
                                roomParentLinksProvider(widget.roomId));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
