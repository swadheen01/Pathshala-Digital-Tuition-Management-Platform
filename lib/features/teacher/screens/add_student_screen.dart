import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/room_provider.dart';

/// Passed via GoRouter `extra` when opening the screen to edit an existing
/// roster row rather than add a new one.
class AddStudentArgs {
  const AddStudentArgs({
    required this.memberId,
    this.name,
    this.roll,
    this.phone,
    this.email,
    this.fee,
  });

  final String memberId;
  final String? name;
  final String? roll;
  final String? phone;
  final String? email;
  final num? fee;
}

/// Teacher adds a student to a room by name (spec §2.1). Phone / email /
/// roll are optional, so a student with no phone still gets a roster
/// entry and can be marked for attendance, payments and exams right away.
///
/// Pass an existing [RoomMemberWithProfile] via `extra` to edit instead.
class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key, required this.roomId, this.editMemberId,
      this.initialName, this.initialRoll, this.initialPhone, this.initialEmail,
      this.initialFee});

  final String roomId;
  final String? editMemberId;
  final String? initialName;
  final String? initialRoll;
  final String? initialPhone;
  final String? initialEmail;
  final num? initialFee;

  bool get isEditing => editMemberId != null;

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName ?? '');
  late final _roll = TextEditingController(text: widget.initialRoll ?? '');
  late final _phone = TextEditingController(text: widget.initialPhone ?? '');
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  late final _fee = TextEditingController(
      text: (widget.initialFee ?? 0) == 0 ? '' : '${widget.initialFee}');

  @override
  void dispose() {
    _name.dispose();
    _roll.dispose();
    _phone.dispose();
    _email.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ctrl = ref.read(roomControllerProvider.notifier);
    final fee = num.tryParse(_fee.text.trim()) ?? 0;
    final ok = widget.isEditing
        ? await ctrl.updateRosterStudent(
            memberId: widget.editMemberId!,
            fullName: _name.text,
            rollNumber: _roll.text,
            phone: _phone.text,
            email: _email.text,
            monthlyFee: fee,
          )
        : await ctrl.addRosterStudent(
            roomId: widget.roomId,
            fullName: _name.text,
            rollNumber: _roll.text,
            phone: _phone.text,
            email: _email.text,
            monthlyFee: fee,
          );

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content:
              Text(friendlyAuthError(ref.read(roomControllerProvider).error)),
        ));
      return;
    }
    ref.invalidate(roomMembersProvider(widget.roomId));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(roomControllerProvider).isLoading;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit student' : 'Add a student'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Only a name is required. Students with no phone '
                          'still appear in attendance, payments and exams.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => Validators.required(v, fieldName: 'Name'),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _roll,
                  decoration: const InputDecoration(
                    labelText: 'Roll number (optional)',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? null
                      : Validators.email(v),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fee,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly fee ৳ (optional)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _save,
                  icon: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(widget.isEditing ? 'Save changes' : 'Add student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
