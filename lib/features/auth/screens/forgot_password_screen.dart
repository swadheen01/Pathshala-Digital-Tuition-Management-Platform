import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/premium.dart';
import '../../../providers/auth_provider.dart';

/// Sends a password-reset email. The link uses the same
/// `io.supabase.pathshala://login-callback/` redirect, so tapping it opens
/// the app with a recovery session.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController =
      TextEditingController(text: widget.initialEmail ?? '');
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text.trim());
    if (!mounted) return;

    if (ok) {
      setState(() => _sent = true);
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Reset your password',
      subtitle: _sent
          ? 'Check ${_emailController.text.trim()} for a reset link.'
          : 'Enter your account email and we\'ll send you a reset link.',
      children: [
        GlassCard(
          child: _sent
              ? const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF7CE0B0)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reset link sent. Open it on this device to continue.',
                        style: TextStyle(color: AppTheme.onDark),
                      ),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        enabled: !isLoading,
                        onSubmitted: (_) => _send(),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Send reset link',
                        loading: isLoading,
                        onPressed: isLoading ? null : _send,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
