import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/content_provider.dart';

/// Admin adds a new content item — a YouTube/external link, optionally
/// targeted to a specific class/grade (spec §4).
class AddContentScreen extends ConsumerStatefulWidget {
  const AddContentScreen({super.key});

  @override
  ConsumerState<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends ConsumerState<AddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classGradeController = TextEditingController();
  bool _visibleToAll = true;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _classGradeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(contentControllerProvider.notifier).createContent(
              title: _titleController.text.trim(),
              url: _urlController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              subject: _subjectController.text.trim().isEmpty
                  ? null
                  : _subjectController.text.trim(),
              targetClassGrade:
                  _visibleToAll ? null : _classGradeController.text.trim(),
            );

    if (!mounted) return;

    if (!success) {
      final state = ref.read(contentControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${state.error}')),
      );
      return;
    }

    ref.invalidate(allContentProvider);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Content')),
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
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://youtube.com/...',
                  ),
                  validator: (v) => Validators.required(v, fieldName: 'URL'),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible to all students'),
                  value: _visibleToAll,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _visibleToAll = value),
                ),
                if (!_visibleToAll)
                  TextFormField(
                    controller: _classGradeController,
                    decoration: const InputDecoration(
                      labelText: 'Target Class/Grade',
                      hintText: 'e.g. Class 9',
                    ),
                    validator: (v) => _visibleToAll
                        ? null
                        : Validators.required(v, fieldName: 'Class/Grade'),
                    enabled: !isLoading,
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSave,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Content'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
