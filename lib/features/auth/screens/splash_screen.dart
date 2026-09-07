import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';

/// Purely a branded loading surface. All navigation away from here is
/// handled centrally by the router redirect in `app_router.dart` as soon
/// as the auth gate resolves (session restored, profile fetched, or the
/// email-confirmation / OAuth deep link delivers a session).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandWordmark(),
              const SizedBox(height: 10),
              const Text(
                'Learn. Grow. Succeed.',
                style: TextStyle(
                  color: AppTheme.onDarkMuted,
                  fontSize: 13,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: null,
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF9B8CFF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
