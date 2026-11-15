import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import 'wallpaper_controller.dart';
import 'wallpapers.dart';

/// Full-bleed wallpaper with a dark gradient + vignette for legibility.
class WallpaperBackground extends StatelessWidget {
  const WallpaperBackground({super.key, required this.child, this.wallpaper});

  final Widget child;

  /// Overrides the selected wallpaper (used for previews).
  final Wallpaper? wallpaper;

  @override
  Widget build(BuildContext context) {
    final w = wallpaper ?? context.watch<WallpaperController>().wallpaper;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Image.asset(
          w.asset,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x9905000D), Color(0xCC05000D)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Color(0x00000000), Color(0x99000000)],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Small backdrop used inside cards: wallpaper + readability scrim.
class WallpaperBackdrop extends StatelessWidget {
  const WallpaperBackdrop({super.key, required this.wallpaper, required this.child, this.radius = 20});

  final Wallpaper wallpaper;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              wallpaper.asset,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xDD05000D), Color(0x8805000D)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
