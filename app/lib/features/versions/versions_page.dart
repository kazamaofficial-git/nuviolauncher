import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/block_icon.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_input.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/mc_version.dart';
import '../instances/instance_flow.dart';
import 'versions_controller.dart';

/// Browse Mojang's versions and spin up an instance from any of them.
class VersionsPage extends StatefulWidget {
  const VersionsPage({super.key});

  @override
  State<VersionsPage> createState() => _VersionsPageState();
}

class _VersionsPageState extends State<VersionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<VersionsController>().ensureLoaded();
  }

  static const Map<VersionFilter, String> _labels = {
    VersionFilter.release: 'Release',
    VersionFilter.snapshot: 'Snapshot',
    VersionFilter.old: 'Old',
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VersionsController>();
    final visible = controller.visible;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Versions',
                subtitle: 'Official Minecraft: Java Edition versions',
                trailing: IconButton(
                  tooltip: 'Reload',
                  onPressed: controller.loading ? null : controller.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              TextField(
                onChanged: controller.setQuery,
                decoration: neonInputDecoration(
                  context,
                  hint: 'Search versions (e.g. 1.21)',
                  prefixIcon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in VersionFilter.values)
                    FilterChip(
                      label: Text(_labels[f]!),
                      selected: controller.filters.contains(f),
                      onSelected: (_) => controller.toggleFilter(f),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: controller.loading && visible.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null && visible.isEmpty
                        ? Center(
                            child: Text(controller.error!,
                                style: const TextStyle(color: AppColors.danger)),
                          )
                        : ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (context, i) => _VersionTile(version: visible[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({required this.version});

  final McVersion version;

  /// release = grass, snapshot = amethyst, anything older = sand.
  static BlockStyle _styleFor(String type) {
    switch (type) {
      case 'release':
        return BlockStyle.grass;
      case 'snapshot':
        return BlockStyle.amethyst;
      default:
        return BlockStyle.sand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = version.releaseTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        radius: 14,
        child: Row(
          children: [
            BlockIcon(style: _styleFor(version.type), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(version.id, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${version.type.replaceAll('_', ' ')}'
                    '${time == null ? '' : '  -  ${formatDate(time)}'}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => createInstanceFlow(context, presetVersionId: version.id),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create instance'),
            ),
          ],
        ),
      ),
    );
  }
}
