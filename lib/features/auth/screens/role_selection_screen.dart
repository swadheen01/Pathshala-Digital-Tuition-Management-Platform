import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/widgets/premium.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

/// Shown once, right after a user's first sign-in when we don't yet know
/// whether they're a teacher or a student (notably Google sign-ups, which
/// carry no role metadata). Persists the choice, then the router redirect
/// advances to profile setup.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _submitting;

  Future<void> _select(UserRole role) async {
    setState(() => _submitting = role);
    final ok =
        await ref.read(authControllerProvider.notifier).chooseRole(role);
    if (!mounted) return;
    if (!ok) {
      setState(() => _submitting = null);
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
    // Success → router redirect takes over.
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting != null;

    return AuthScaffold(
      title: 'How will you use Pathshala?',
      subtitle: 'This sets up the right home screen for you. '
          'You can ask an admin to change it later.',
      showBack: false,
      children: [
        _RoleCard(
          icon: Icons.school_outlined,
          label: 'I\'m a teacher',
          subtitle: 'Create rooms, take attendance, track payments and exams.',
          loading: _submitting == UserRole.teacher,
          disabled: busy,
          onTap: () => _select(UserRole.teacher),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.backpack_outlined,
          label: 'I\'m a student',
          subtitle: 'Join rooms, submit work, and follow your progress.',
          loading: _submitting == UserRole.student,
          disabled: busy,
          onTap: () => _select(UserRole.student),
        ),
        const SizedBox(height: 28),
        Center(
          child: TextButton(
            onPressed: busy
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppTheme.onDarkMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.loading,
    required this.disabled,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppTheme.ctaGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.onDarkMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.onDarkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
