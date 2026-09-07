import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'generated/app_localizations.dart';
import 'providers/locale_provider.dart';

/// Root widget of the Pathshala app.
///
/// Kept deliberately thin: it only wires together the router, theme,
/// and localization. All actual screens live under lib/features/.
class PathshalaApp extends ConsumerWidget {
  const PathshalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Pathshala',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // --- Localization (Bengali / English toggle) ---
      locale: locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('bn'), // Bengali
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: router,
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
