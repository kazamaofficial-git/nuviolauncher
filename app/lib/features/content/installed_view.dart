import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/block_icon.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/content/content_models.dart';
import '../../data/services/content/installed_content_service.dart';
import 'content_controller.dart';
import 'content_widgets.dart';

/// Files in the selected instance's mods / shaderpacks / resourcepacks folders.
class InstalledView extends StatefulWidget {
  const InstalledView({super.key, required this.controller});

  final ContentController controller;

  @override
  State<InstalledView> createState() => _InstalledViewState();
}

class _InstalledViewState extends State<InstalledView> {
  List<InstalledFile>? _files;
  String? _error;
  String? _instanceId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant InstalledView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.selectedInstance?.id != _instanceId) _reload();
  }

  Future<void> _reload() async {
    _instanceId = widget.controller.selectedInstance?.id;
    try {
      final files = await widget.controller.listInstalled();
      if (!mounted) return;
      setState(() {
        _files = files;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _files = const [];
        _error = 'Could not read the instance folder: $e';
      });
    }
  }

  Future<void> _delete(InstalledFile file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('${file.name} will be removed from this instance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.controller.deleteInstalled(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
    await _reload();
  }

  static BlockStyle _styleFor(ContentCategory c) {
    switch (c) {
      case ContentCategory.mod:
        return BlockStyle.stone;
      case ContentCategory.shader:
        return BlockStyle.amethyst;
      default:
        return BlockStyle.planks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    if (widget.controller.selectedInstance == null) {
      return const ContentEmptyState(message: 'Select an instance to see its content.');
    }
    if (files == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return ContentEmptyState(message: _error!, style: BlockStyle.netherrack);
    }
    if (files.isEmpty) {
      return const ContentEmptyState(
        message: 'Nothing installed yet. Browse content and press Install.',
        style: BlockStyle.dirt,
      );
    }
    return Column(
      children: [
        for (final f in files)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GlassCard(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  BlockIcon(style: _styleFor(f.category), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '${f.category.label}  -  ${formatBytes(f.size)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(f),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
