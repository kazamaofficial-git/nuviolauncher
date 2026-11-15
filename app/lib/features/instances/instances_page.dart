import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/block_icon.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/instance.dart';
import '../license/license_controller.dart';
import '../wallpaper/wallpapers.dart';
import 'instance_editor_dialog.dart';
import 'instance_flow.dart';
import 'instances_controller.dart';

/// Lists, selects, edits and deletes instances.
class InstancesPage extends StatelessWidget {
  const InstancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final instances = context.watch<InstancesController>();
    final hasPlus = context.watch<LicenseController>().hasPlus;
    final limitText = hasPlus
        ? '${instances.items.length} instances'
        : '${instances.items.length} / ${AppConstants.freeInstanceLimit} (free plan)';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeader(
              title: 'Instances',
              subtitle: limitText,
              trailing: NeonButton(
                label: 'New instance',
                icon: Icons.add_rounded,
                onPressed: () => createInstanceFlow(context),
              ),
            ),
            if (instances.items.isEmpty)
              const GlassCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      BlockIcon(style: BlockStyle.grass, size: 56),
                      SizedBox(height: 8),
                      Text(
                        'No instances yet. Create one to start playing.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final instance in instances.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InstanceTile(
                    instance: instance,
                    selected: instance.id == instances.selectedId,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({required this.instance, required this.selected});

  final Instance instance;
  final bool selected;

  Future<void> _edit(BuildContext context) async {
    final controller = context.read<InstancesController>();
    final draft = await showDialog<InstanceDraft>(
      context: context,
      builder: (_) => InstanceEditorDialog(existing: instance),
    );
    if (draft == null) return;
    await controller.update(instance.copyWith(
      name: draft.name,
      versionId: draft.versionId,
      loader: draft.loader,
      renderer: draft.renderer,
      ramMb: draft.ramMb,
      jvmArgs: draft.jvmArgs,
    ));
  }

  Future<void> _delete(BuildContext context) async {
    final controller = context.read<InstancesController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete instance?'),
        content: Text('"${instance.name}" will be removed from the launcher.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await controller.delete(instance.id);
  }

  @override
  Widget build(BuildContext context) {
    final last = instance.lastPlayed;
    return GlassCard(
      glow: selected,
      onTap: () => context.read<InstancesController>().select(instance.id),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? AppColors.lavender : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              Wallpapers.forSeed(instance.id).thumbAsset,
              width: 64,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 40),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instance.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${instance.versionId}  -  ${instance.loader.label}  -  '
                  '${formatRam(instance.ramMb)}'
                  '${last == null ? '' : '  -  played ${formatDate(last)}'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                if (!instance.loader.isSupported)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Loader support coming soon',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
