import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/beta_badge.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/orbital_ring.dart';
import '../../core/widgets/page_header.dart';
import '../accounts/account_chip.dart';
import '../instances/instance_flow.dart';
import '../instances/instances_controller.dart';
import '../news/announcements_card.dart';
import '../news/news_controller.dart';
import '../news/update_banner.dart';
import '../wallpaper/wallpaper_background.dart';
import '../wallpaper/wallpaper_controller.dart';
import 'launch_controller.dart';

/// Landing page of the app: hero, play card, updates and announcements.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final update = context.watch<NewsController>().update;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (update != null) ...[
              UpdateBanner(release: update),
              const SizedBox(height: 16),
            ],
            const _HeroCard(),
            const SizedBox(height: 16),
            const _PlayCard(),
            const SizedBox(height: 16),
            const AnnouncementsCard(),
          ],
        ),
      ),
    );
  }
}

/// [GlassCard] drawn over the selected wallpaper.
class _WallpaperPanel extends StatelessWidget {
  const _WallpaperPanel({required this.child, this.glow = false, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final bool glow;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final wallpaper = context.watch<WallpaperController>().wallpaper;
    return WallpaperBackdrop(
      wallpaper: wallpaper,
      child: GlassCard(glow: glow, padding: padding, child: child),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final version = context.read<PackageInfo>().version;
    final ring = OrbitalRing(
      size: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset('assets/brand/icon.png', width: 96, height: 96),
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Text(
              'NUVIO LAUNCHER',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: AppColors.text,
              ),
            ),
            BetaBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'v$version  -  by Kazama Tech',
          style: const TextStyle(color: AppColors.lavender, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        const Text(
          'A modern, futuristic Minecraft launcher. This is an early beta - '
          'features are still being built.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    );

    return _WallpaperPanel(
      glow: true,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 600) {
            return Row(children: [ring, const SizedBox(width: 24), Expanded(child: texts)]);
          }
          return Column(children: [ring, const SizedBox(height: 12), texts]);
        },
      ),
    );
  }
}

class _PlayCard extends StatelessWidget {
  const _PlayCard();

  Future<void> _play(BuildContext context) async {
    final launch = context.read<LaunchController>();
    if (!launch.launcher.isSupported) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Android launching is in development (beta)'),
          content: const Text(
            'Versions, instances and licensing already work on Android, but '
            'starting the game is not available yet. It will arrive in a later beta.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    await launch.play();
  }

  @override
  Widget build(BuildContext context) {
    final instances = context.watch<InstancesController>();
    final launch = context.watch<LaunchController>();
    final selected = instances.selected;

    return _WallpaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Play', icon: Icons.rocket_launch_outlined)),
            ],
          ),
          if (selected == null) ...[
            const Text(
              'You have no instances yet. Create one to get started.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            NeonButton(
              label: 'Create instance',
              icon: Icons.add_rounded,
              onPressed: () => createInstanceFlow(context),
            ),
          ] else ...[
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Instance',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: instances.selectedId,
                  isExpanded: true,
                  items: [
                    for (final i in instances.items)
                      DropdownMenuItem(
                        value: i.id,
                        child: Text('${i.name}  (${i.versionId})'),
                      ),
                  ],
                  onChanged: launch.isBusy
                      ? null
                      : (id) {
                          if (id != null) instances.select(id);
                        },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const AccountChip(),
                const SizedBox(width: 10),
                Expanded(
                  child: NeonButton(
                    label: launch.isGameRunning
                        ? 'Playing...'
                        : launch.isBusy
                            ? 'Preparing...'
                            : 'Play',
                    icon: Icons.play_arrow_rounded,
                    expanded: true,
                    loading: launch.isBusy,
                    onPressed: launch.isBusy ? null : () => _play(context),
                  ),
                ),
                if (launch.isBusy) ...[
                  const SizedBox(width: 10),
                  NeonButton(
                    label: 'Stop',
                    icon: Icons.stop_rounded,
                    outlined: true,
                    onPressed: launch.stop,
                  ),
                ],
              ],
            ),
            if (launch.isBusy && launch.progress != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: launch.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
            if (launch.status.isNotEmpty && (launch.isBusy || launch.error == null)) ...[
              const SizedBox(height: 10),
              Text(launch.status, style: const TextStyle(color: AppColors.textMuted)),
            ],
            if (launch.error != null) ...[
              const SizedBox(height: 10),
              Text(launch.error!, style: const TextStyle(color: AppColors.danger)),
            ],
            if (launch.logs.isNotEmpty) ...[
              const SizedBox(height: 10),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Game log (${launch.logs.length} lines)'),
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.fade(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      itemCount: launch.logs.length,
                      itemBuilder: (_, i) => Text(
                        launch.logs[i],
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (selected.lastPlayed != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last played ${formatDateTime(selected.lastPlayed!)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
