import 'package:flutter/material.dart';

/// A vivid navy, indigo, violet, and gold visual language matched to the icon.
class AppTheme {
  AppTheme._();

  static const skyBlue = Color(0xFF4C3DFF);
  static const navy = Color(0xFF102A56);
  static const deepBlue = Color(0xFF172B5C);
  static const sunGold = Color(0xFFFFB547);
  static const ink = Color(0xFF171126);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCFAFF), Color(0xFFF0EAFF), Color(0xFFE5D9FF)],
    stops: [0, .52, 1],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5F55FF), Color(0xFF172B5C)],
  );

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4385), Color(0xFF102A56), Color(0xFF24105C)],
  );

  /// Full-bleed background for the auth / onboarding flow.
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241A5C), Color(0xFF3A2BA0), Color(0xFF120E33)],
    stops: [0, .48, 1],
  );

  /// Primary call-to-action fill.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6C5BFF), Color(0xFF8A4DFF)],
  );

  static const Color glassStroke = Color(0x33FFFFFF);
  static const Color onDark = Color(0xFFF3F0FF);
  static const Color onDarkMuted = Color(0xFFB9B2E6);

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: skyBlue,
      onPrimary: Colors.white,
      secondary: Color(0xFFB14DFF),
      onSecondary: Colors.white,
      tertiary: sunGold,
      onTertiary: ink,
      surface: Color(0xEEF8FAFF),
      onSurface: ink,
      surfaceContainerLow: Color(0xD9F0EAFF),
      surfaceContainerHighest: Color(0xFFE5D9FF),
      outline: Color(0xFFCBB8FF),
      error: Color(0xFFB91C1C),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.55,
        ),
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: ink,
            displayColor: ink,
          )
          .copyWith(
            headlineSmall: const TextStyle(
              fontSize: 28,
              height: 1.12,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.8,
            ),
            titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF70655D),
            ),
          ),
      cardTheme: CardThemeData(
        color: const Color(0xE6FFFFFF),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1F312E81),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xB3FFFFFF)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: skyBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlue,
          backgroundColor: const Color(0xB3FFFFFF),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xD9FFFFFF),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: skyBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xE6FCFAFF),
        elevation: 0,
        indicatorColor: const Color(0x335F55FF),
        height: 72,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x338A4DFF)),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        iconColor: skyBlue,
        selectedTileColor: Color(0x1A5F55FF),
        selectedColor: skyBlue,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEDE7FF),
        selectedColor: skyBlue,
        secondarySelectedColor: skyBlue,
        labelStyle: const TextStyle(
          color: Color(0xFF4A3F86),
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: skyBlue,
        unselectedLabelColor: Color(0xFF9C93B4),
        indicatorColor: skyBlue,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: skyBlue),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: skyBlue,
          brightness: Brightness.dark,
        ),
      );
}
