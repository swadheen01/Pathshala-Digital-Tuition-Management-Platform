import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/room_provider.dart';

/// Teacher records a payment received from a student (spec §2.4).
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedStudentId;
  DateTime _paidOn = DateTime.now();
  DateTime _forMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student')),
      );
      return;
    }

    final forMonthStr =
        '${_forMonth.year}-${_forMonth.month.toString().padLeft(2, '0')}';

    final success =
        await ref.read(paymentControllerProvider.notifier).recordPayment(
              roomId: widget.roomId,
              studentId: _selectedStudentId!,
              amount: double.parse(_amountController.text.trim()),
              paidOn: _paidOn,
              forMonth: forMonthStr,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );

    if (!mounted) return;

    if (!success) {
      final state = ref.read(paymentControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${state.error}')),
      );
      return;
    }

    ref.invalidate(duesSummaryProvider(widget.roomId));
    context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paidOn = picked);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final controllerState = ref.watch(paymentControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                membersAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => Text('Failed to load students: $err'),
                  data: (members) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedStudentId,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: members
                          .map((m) => DropdownMenuItem(
                                value: m.member.refId,
                                child: Text(m.studentName),
                              ))
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (value) =>
                              setState(() => _selectedStudentId = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (৳)'),
                  validator: Validators.amount,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Paid on'),
                  subtitle:
                      Text('${_paidOn.day}/${_paidOn.month}/${_paidOn.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: isLoading ? null : _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
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
                      : const Text('Save Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
