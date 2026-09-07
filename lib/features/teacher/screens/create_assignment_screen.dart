import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/assignment_provider.dart';

/// Teacher posts an assignment/homework with a due date (spec §2.6).
class CreateAssignmentScreen extends ConsumerStatefulWidget {
  const CreateAssignmentScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends ConsumerState<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(assignmentControllerProvider.notifier).createAssignment(
              roomId: widget.roomId,
              title: _titleController.text.trim(),
              dueDate: _dueDate,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );

    if (!mounted) return;

    if (!success) {
      final state = ref.read(assignmentControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create: ${state.error}')),
      );
      return;
    }

    ref.invalidate(roomAssignmentsProvider(widget.roomId));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('New Assignment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => Validators.required(v, fieldName: 'Title'),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (optional)',
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due date'),
                  subtitle: Text(
                    '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: isLoading ? null : _pickDueDate,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleCreate,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post Assignment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
