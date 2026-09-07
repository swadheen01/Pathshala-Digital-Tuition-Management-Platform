import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/premium.dart';
import '../../../providers/auth_provider.dart';

/// Shown after signup when email confirmation is enabled.
///
/// Primary path: the user taps the link in their inbox, the app opens via
/// the `io.supabase.pathshala://login-callback/` deep link, supabase_flutter
/// exchanges the code for a session, and the router redirect moves them on
/// to profile setup — this screen never needs a button press.
///
/// Fallback path: the user pastes the 6-digit code from the same email.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendIn = 45);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).verifyEmailOtp(
          email: widget.email,
          token: _otpController.text.trim(),
        );
    if (!mounted || success) return; // router redirect handles success
    _toast(friendlyAuthError(ref.read(authControllerProvider).error));
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendConfirmation(widget.email);
    if (!mounted) return;
    if (ok) {
      _startCooldown();
      _toast('Confirmation email sent again.');
    } else {
      _toast(friendlyAuthError(ref.read(authControllerProvider).error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Confirm your email',
      subtitle:
          'We sent a confirmation link to ${widget.email}. Open it on this '
          'device and you\'ll be signed in automatically.',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      color: Color(0xFF9B8CFF)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Waiting for confirmation…',
                      style: TextStyle(
                        color: AppTheme.onDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (isLoading || _resendIn > 0) ? null : _resend,
                child: Text(
                  _resendIn > 0
                      ? 'Resend link in ${_resendIn}s'
                      : 'Resend confirmation email',
                  style: const TextStyle(color: Color(0xFFB9B2E6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Have a code instead?',
          style: TextStyle(color: AppTheme.onDarkMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumField(
                  controller: _otpController,
                  label: '6-digit code',
                  icon: Icons.password_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !isLoading,
                  onSubmitted: (_) => _verify(),
                  validator: Validators.otp,
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Verify code',
                  loading: isLoading,
                  onPressed: isLoading ? null : _verify,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
