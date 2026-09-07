import 'package:flutter/material.dart';

/// Raw color values referenced outside of ThemeData — e.g. status
/// colors for attendance/payment states that don't come from the
/// Material color scheme. Prefer Theme.of(context).colorScheme for
/// anything theme-related; use these only for fixed semantic colors.
class AppColors {
  AppColors._();

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFD92D20);
  static const Color info = Color(0xFF1677E8);
}
