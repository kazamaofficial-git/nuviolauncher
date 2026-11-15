import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/release_info.dart';

/// Banner shown when a newer release is available.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.release});

  final ReleaseInfo release;

  @override
  Widget build(BuildContext context) {
    final asset = release.platforms[platformName];
    final size = asset?.size;
    return GlassCard(
      glow: true,
      child: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded, color: AppColors.lavender, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update available: v${release.version}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (size != null)
                  Text(
                    formatBytes(size),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          NeonButton(
            label: 'Download',
            icon: Icons.download_rounded,
            onPressed: () => launchUrl(
              Uri.parse(AppConstants.resolveUrl(asset?.url ?? '/download')),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
