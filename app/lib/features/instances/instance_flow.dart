import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../shell/navigation_controller.dart';
import 'instance_editor_dialog.dart';
import 'instances_controller.dart';

/// Opens the editor to create an instance, or the Plus upsell when the free
/// limit has been reached.
Future<void> createInstanceFlow(BuildContext context, {String? presetVersionId}) async {
  final instances = context.read<InstancesController>();
  final nav = context.read<NavigationController>();

  if (!instances.canCreate) {
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Instance limit reached'),
        content: Text(
          'The free plan includes ${AppConstants.freeInstanceLimit} instances. '
          'Activate Nuvio Plus for unlimited instances.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Nuvio Plus')),
        ],
      ),
    );
    if (upgrade == true) nav.go(AppTab.license);
    return;
  }

  if (!context.mounted) return;
  final result = await showDialog<InstanceDraft>(
    context: context,
    builder: (_) => InstanceEditorDialog(presetVersionId: presetVersionId),
  );
  if (result == null) return;
  await instances.create(
    name: result.name,
    versionId: result.versionId,
    loader: result.loader,
    renderer: result.renderer,
    ramMb: result.ramMb,
    jvmArgs: result.jvmArgs,
  );
}
