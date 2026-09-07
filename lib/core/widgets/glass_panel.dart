import 'package:flutter/material.dart';

/// A soft, elevated surface for content that benefits from depth.
///
/// Historically this used `BackdropFilter` blur, but that renders black on
/// many Android emulators / software renderers, so it now uses a
/// translucent fill + shadow instead.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? Theme.of(context).brightness == Brightness.dark
                ? const Color(0xE62B2522)
                : const Color(0xF2FFFFFF)
            : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xA6FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F573A28),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
