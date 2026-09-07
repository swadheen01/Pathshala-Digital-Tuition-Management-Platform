import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable button with a built-in loading state, so screens don't
/// each reimplement the CircularProgressIndicator swap.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    if (isSecondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null || isLoading ? null : AppTheme.primaryGradient,
        color: onPressed == null || isLoading ? null : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: onPressed == null || isLoading
            ? null
            : const [
                BoxShadow(
                  color: Color(0x3D8E3F26),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: child,
      ),
    );
  }
}
