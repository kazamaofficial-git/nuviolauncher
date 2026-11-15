import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/color_ext.dart';

/// Translucent "glass" panel with a neon border and optional glow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.glow = false,
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHigh.fade(0.78),
            AppColors.surface.fade(0.62),
          ],
        ),
        border: Border.all(color: accent.fade(glow ? 0.45 : 0.2)),
        boxShadow: glow
            ? [BoxShadow(color: accent.fade(0.28), blurRadius: 30, spreadRadius: -4)]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
