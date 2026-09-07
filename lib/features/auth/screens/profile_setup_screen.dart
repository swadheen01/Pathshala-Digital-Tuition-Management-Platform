import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/premium.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

/// Final onboarding step: full name + role-specific fields (class/grade,
/// institution). Writing the row with `profile_completed = true` is what
/// lets the router redirect release the user to their dashboard.
///
/// `role` may be passed via `extra`; otherwise it is resolved from the
/// pending choice or the existing profile row.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.role});

  final UserRole? role;

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classGradeController = TextEditingController();
  final _institutionController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _classGradeController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  UserRole _resolveRole() {
    return widget.role ??
        ref.read(pendingRoleProvider) ??
        ref.read(currentProfileProvider).valueOrNull?.role ??
        UserRole.student;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final role = _resolveRole();
    final profile =
        await ref.read(authControllerProvider.notifier).completeProfile(
              fullName: _nameController.text.trim(),
              role: role,
              classGrade: role == UserRole.student
                  ? _classGradeController.text.trim()
                  : null,
              institution: _institutionController.text.trim().isEmpty
                  ? null
                  : _institutionController.text.trim(),
            );

    if (!mounted || profile != null) return; // router redirect handles success

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            friendlyAuthError(ref.read(authControllerProvider).error),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final role = _resolveRole();

    // Prefill the name from any value the trigger captured (e.g. Google).
    if (!_prefilled) {
      final existing = ref.read(currentProfileProvider).valueOrNull;
      final name = existing?.fullName ?? '';
      if (name.isNotEmpty && name != 'Pathshala user') {
        _nameController.text = name;
      }
      _prefilled = true;
    }

    return AuthScaffold(
      title: 'Set up your profile',
      subtitle: role == UserRole.teacher
          ? 'A few details so your students recognise you.'
          : 'A few details so your teachers can place you in the right class.',
      showBack: false,
      children: [
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumField(
                  controller: _nameController,
                  label: 'Full name',
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) => Validators.required(v, fieldName: 'Name'),
                ),
                if (role == UserRole.student) ...[
                  const SizedBox(height: 16),
                  PremiumField(
                    controller: _classGradeController,
                    label: 'Class / grade',
                    hint: 'e.g. Class 9',
                    icon: Icons.grade_outlined,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Class/Grade'),
                  ),
                ],
                const SizedBox(height: 16),
                PremiumField(
                  controller: _institutionController,
                  label: 'Institution (optional)',
                  hint: 'School / college name',
                  icon: Icons.apartment_outlined,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Continue',
                  loading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
