import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/premium.dart';
import '../../../providers/auth_provider.dart';

/// Sign in with email + password, or Google. Navigation after a
/// successful sign-in is handled centrally by the router redirect
/// (see app_router.dart) — this screen only kicks off the auth call.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithPassword(email: email, password: _passwordController.text);

    if (!mounted || success) return;

    final error = ref.read(authControllerProvider).error;
    final message = friendlyAuthError(error);
    _toast(message);

    // "Email not confirmed" — resend the link so the user can retry.
    if (message.contains('confirm your email')) {
      await ref.read(authControllerProvider.notifier).resendConfirmation(email);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted || success) return;
    _toast(friendlyAuthError(ref.read(authControllerProvider).error));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Center(child: BrandWordmark()),
                  const SizedBox(height: 36),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue to your classroom.',
                    style: TextStyle(
                      color: AppTheme.onDarkMuted,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    child: Column(
                      children: [
                        PremiumField(
                          controller: _emailController,
                          label: 'Email',
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
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onSubmitted: (_) => _handleSignIn(),
                          validator: (v) =>
                              Validators.required(v, fieldName: 'Password'),
                          suffix: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.onDarkMuted,
                              size: 20,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push(
                                      RouteNames.forgotPassword,
                                      extra: _emailController.text.trim(),
                                    ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Color(0xFFB9B2E6)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GradientButton(
                          label: 'Sign in',
                          loading: isLoading,
                          onPressed: isLoading ? null : _handleSignIn,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: TextStyle(
                                color: AppTheme.onDarkMuted, fontSize: 12)),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: 'Continue with Google',
                    leading: const GoogleGlyph(),
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('New here? ',
                            style: TextStyle(color: AppTheme.onDarkMuted)),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => context.push(RouteNames.signup),
                          child: const Text(
                            'Create an account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
