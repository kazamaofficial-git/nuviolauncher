import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/block_icon.dart';
import '../../data/models/content/content_models.dart';
import '../../data/models/instance.dart';

/// `1.2M`, `34.5K` or the plain number.
String compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// Project icon from the network; falls back to a deterministic [BlockIcon].
class ContentIcon extends StatelessWidget {
  const ContentIcon({super.key, required this.project, this.size = 48});

  final ContentProject project;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = BlockIcon(style: BlockStyle.fromSeed(project.id), size: size);
    final url = project.iconUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Small coloured chip for a loader name (mods).
class LoaderBadge extends StatelessWidget {
  const LoaderBadge({super.key, required this.name});

  final String name;

  static BlockStyle styleFor(String name) {
    switch (name.toLowerCase()) {
      case 'fabric':
        return BlockStyle.sand;
      case 'forge':
        return BlockStyle.stone;
      case 'neoforge':
        return BlockStyle.dirt;
      case 'quilt':
        return BlockStyle.amethyst;
      default:
        return BlockStyle.grass;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = LoaderType.values
        .firstWhere((l) => l.name == name.toLowerCase(), orElse: () => LoaderType.vanilla)
        .label;
    final text = name.isEmpty ? label : '${name[0].toUpperCase()}${name.substring(1)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlockIcon(style: styleFor(name), size: 16),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

/// Illustrated empty / error state.
class ContentEmptyState extends StatelessWidget {
  const ContentEmptyState({
    super.key,
    required this.message,
    this.style = BlockStyle.stone,
    this.action,
  });

  final String message;
  final BlockStyle style;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlockIcon(style: style, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}
