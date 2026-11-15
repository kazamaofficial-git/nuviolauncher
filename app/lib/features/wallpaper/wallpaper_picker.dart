import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import 'wallpaper_controller.dart';
import 'wallpapers.dart';

/// Grid of the fixed wallpaper thumbnails; the selected one glows.
class WallpaperPicker extends StatelessWidget {
  const WallpaperPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WallpaperController>();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final w in Wallpapers.all)
          _Thumb(
            wallpaper: w,
            selected: w.id == controller.id,
            onTap: () => controller.select(w.id),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.wallpaper, required this.selected, required this.onTap});

  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 132,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.white.fade(0.12),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.fade(0.6), blurRadius: 16, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      wallpaper.thumbAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.surface),
                    ),
                    if (selected)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              wallpaper.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
