import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/messaging_provider.dart';

/// Teacher creates a poll for a room (spec §2.2). Starts with 2 option
/// fields and lets the teacher add more.
class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 options')),
      );
      return;
    }

    final success =
        await ref.read(messagingControllerProvider.notifier).createPoll(
              roomId: widget.roomId,
              question: _questionController.text.trim(),
              options: options,
            );

    if (!mounted) return;

    if (!success) {
      final state = ref.read(messagingControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create poll: ${state.error}')),
      );
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Poll')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Question'),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                Text('Options', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                            ),
                            enabled: !isLoading,
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed:
                                isLoading ? null : () => _removeOption(index),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: isLoading ? null : _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
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
                      : const Text('Create Poll'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
