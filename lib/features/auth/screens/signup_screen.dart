import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/premium.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

/// Self-registration for students and teachers. Admin/Parent accounts are
/// provisioned elsewhere. On success the router redirect takes over:
/// straight to profile setup if the session is live, otherwise we show
/// the "confirm your email" screen.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _role = UserRole.student;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success =
        await ref.read(authControllerProvider.notifier).signUpWithPassword(
              email: email,
              password: _passwordController.text,
              role: _role,
            );
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              friendlyAuthError(ref.read(authControllerProvider).error),
            ),
          ),
        );
      return;
    }

    // Session live already (email confirmation disabled): the router
    // redirect will move us to profile setup. Otherwise, confirm email.
    if (ref.read(authServiceProvider).currentSession == null) {
      context.push(RouteNames.otpVerification, extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Pick your role, then set a password to get started.',
      children: [
        _RolePicker(
          value: _role,
          onChanged:
              isLoading ? null : (r) => setState(() => _role = r),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumField(
                  controller: _emailController,
                  label: 'Email address',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                PremiumField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.onDarkMuted,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    final error =
                        Validators.required(value, fieldName: 'Password');
                    if (error != null) return error;
                    if (value!.length < 6) {
                      return 'Use at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PremiumField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  icon: Icons.lock_reset_outlined,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onSubmitted: (_) => _continue(),
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Create account',
                  loading: isLoading,
                  onPressed: isLoading ? null : _continue,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Already have an account? ',
                  style: TextStyle(color: AppTheme.onDarkMuted)),
              GestureDetector(
                onTap: () => context.go(RouteNames.login),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleChip(
            icon: Icons.backpack_outlined,
            label: 'Student',
            selected: value == UserRole.student,
            onTap: onChanged == null
                ? null
                : () => onChanged!(UserRole.student),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleChip(
            icon: Icons.school_outlined,
            label: 'Teacher',
            selected: value == UserRole.teacher,
            onTap: onChanged == null
                ? null
                : () => onChanged!(UserRole.teacher),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.ctaGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.glassStroke,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
