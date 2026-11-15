import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/beta_badge.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_input.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/plus_badge.dart';
import '../license/license_controller.dart';
import '../wallpaper/wallpaper_picker.dart';
import 'settings_controller.dart';

/// Account, appearance, game paths and About.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _gameDir;
  late final TextEditingController _javaPath;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>().settings;
    _gameDir = TextEditingController(text: s.gameDir);
    _javaPath = TextEditingController(text: s.javaPath);
  }

  @override
  void dispose() {
    _gameDir.dispose();
    _javaPath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final hasPlus = context.watch<LicenseController>().hasPlus;
    final info = context.read<PackageInfo>();
    final s = controller.settings;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(title: 'Settings', subtitle: 'Appearance and game'),
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('Wallpaper', icon: Icons.wallpaper_rounded),
                  WallpaperPicker(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: SectionTitle('Accent colour', icon: Icons.palette_outlined),
                      ),
                      if (!hasPlus) const PlusBadge(),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final color in AppColors.accentChoices)
                        _AccentSwatch(
                          color: color,
                          selected: hasPlus
                              ? (s.accentValue ?? AppColors.neon.toARGB32()) == color.toARGB32()
                              : color == AppColors.neon,
                          onTap: () {
                            if (!hasPlus) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Custom accent colours are part of Nuvio Plus.'),
                                ),
                              );
                              return;
                            }
                            controller.update(s.withAccent(color.toARGB32()));
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Game', icon: Icons.sports_esports_outlined),
                  TextField(
                    controller: _gameDir,
                    decoration: neonInputDecoration(
                      context,
                      label: 'Game folder',
                      helper: 'Leave empty to use the default folder.',
                      prefixIcon: Icons.folder_outlined,
                    ),
                    onChanged: (v) => controller.update(s.copyWith(gameDir: v.trim())),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _javaPath,
                    decoration: neonInputDecoration(
                      context,
                      label: 'Java executable',
                      helper: 'Leave empty to auto-detect (JAVA_HOME or PATH).',
                      prefixIcon: Icons.coffee_outlined,
                    ),
                    onChanged: (v) => controller.update(s.copyWith(javaPath: v.trim())),
                  ),
                  const SizedBox(height: 14),
                  Text('Default memory: ${formatRam(s.defaultRamMb)}',
                      style: const TextStyle(color: AppColors.textMuted)),
                  Slider(
                    min: AppConstants.minRamMb.toDouble(),
                    max: AppConstants.maxRamMb.toDouble(),
                    divisions:
                        (AppConstants.maxRamMb - AppConstants.minRamMb) ~/ AppConstants.ramStepMb,
                    value: s.defaultRamMb
                        .clamp(AppConstants.minRamMb, AppConstants.maxRamMb)
                        .toDouble(),
                    onChanged: (v) => controller.update(s.copyWith(defaultRamMb: v.round())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('About', icon: Icons.info_outline_rounded),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset('assets/brand/icon.png', width: 52, height: 52),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  AppConstants.appName,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const BetaBadge(),
                              ],
                            ),
                            Text('Version ${info.version} (${info.buildNumber})',
                                style: const TextStyle(color: AppColors.textMuted)),
                            const Text('Developed by ${AppConstants.developer}',
                                style: TextStyle(color: AppColors.lavender)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.fade(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Nuvio Launcher is in beta. Expect rough edges. Not affiliated with '
                      'Mojang or Microsoft.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(AppConstants.resolveUrl('/')),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.language_rounded, size: 18),
                    label: Text(AppConstants.apiBase),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2.5),
          boxShadow: [BoxShadow(color: color.fade(0.55), blurRadius: 14)],
        ),
        child: selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
      ),
    );
  }
}
