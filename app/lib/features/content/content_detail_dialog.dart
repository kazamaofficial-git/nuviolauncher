import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/block_icon.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/content/content_models.dart';
import 'content_controller.dart';
import 'content_widgets.dart';

/// Shows the detail dialog of [project].
Future<void> showContentDetail(
  BuildContext context,
  ContentController controller,
  ContentProject project,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => ContentDetailDialog(controller: controller, project: project),
  );
}

/// Description + filtered versions list with install buttons.
class ContentDetailDialog extends StatefulWidget {
  const ContentDetailDialog({super.key, required this.controller, required this.project});

  final ContentController controller;
  final ContentProject project;

  @override
  State<ContentDetailDialog> createState() => _ContentDetailDialogState();
}

class _ContentDetailDialogState extends State<ContentDetailDialog> {
  String? _description;
  bool _descExpanded = false;
  List<ContentVersion>? _versions;
  String? _versionsError;
  bool _allVersions = false;

  String? _installingId;
  double? _progress;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadDescription();
    _loadVersions();
  }

  Future<void> _loadDescription() async {
    try {
      final text = await widget.controller.loadDescription(widget.project);
      if (mounted) setState(() => _description = text);
    } catch (_) {
      if (mounted) setState(() => _description = widget.project.description);
    }
  }

  Future<void> _loadVersions() async {
    setState(() {
      _versions = null;
      _versionsError = null;
    });
    try {
      final list = await widget.controller
          .loadVersions(widget.project, applyFilters: !_allVersions);
      if (mounted) setState(() => _versions = list);
    } on ContentException catch (e) {
      if (mounted) setState(() => _versionsError = e.message);
    } catch (e) {
      if (mounted) setState(() => _versionsError = 'Could not load versions: $e');
    }
  }

  Future<void> _openPage() async {
    final url = widget.project.pageUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _install(ContentVersion version) async {
    setState(() {
      _installingId = version.id;
      _progress = null;
      _message = null;
    });
    try {
      final path = await widget.controller.install(
        widget.project,
        version,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() => _progress = total == null || total <= 0 ? null : received / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _message = 'Installed: $path';
        _messageIsError = false;
      });
    } on ContentException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.message;
        _messageIsError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Install failed: $e';
        _messageIsError = true;
      });
    }
    if (mounted) setState(() => _installingId = null);
  }

  Widget _versionRow(ContentVersion v) {
    final project = widget.project;
    final file = v.file;
    final busy = _installingId == v.id;
    final noUrl = file != null && (file.url == null || file.url!.isEmpty);
    final hasInstance = widget.controller.selectedInstance != null;

    Widget button;
    if (!project.category.installable) {
      button = const OutlinedButton(onPressed: null, child: Text('Coming soon'));
    } else if (noUrl) {
      button = OutlinedButton.icon(
        onPressed: project.pageUrl == null ? null : _openPage,
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text('Open on ${project.provider.label}'),
      );
    } else if (busy) {
      button = SizedBox(
        width: 96,
        child: LinearProgressIndicator(value: _progress, minHeight: 6),
      );
    } else {
      button = FilledButton.icon(
        onPressed: file == null || !hasInstance || _installingId != null
            ? null
            : () => _install(v),
        icon: const Icon(Icons.download_rounded, size: 16),
        label: const Text('Install'),
      );
    }

    final tags = [
      ...v.gameVersions.take(3),
      if (v.gameVersions.length > 3) '+${v.gameVersions.length - 3}',
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name.isEmpty ? v.versionNumber : v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (tags.isNotEmpty)
                        Text('MC $tags',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      for (final l in v.loaders.take(3)) LoaderBadge(name: l),
                      if (file?.size != null)
                        Text(formatBytes(file!.size!),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            button,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final instance = widget.controller.selectedInstance;
    final maxHeight = MediaQuery.of(context).size.height - 24;
    final versions = _versions;
    final description = _description ?? project.description;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                ContentIcon(project: project, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      Text(
                        '${project.author.isEmpty ? '' : 'by ${project.author}  -  '}'
                        '${compactCount(project.downloads)} downloads  -  ${project.provider.label}',
                        style: const TextStyle(color: AppColors.lavender, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (project.pageUrl != null)
                  IconButton(
                    tooltip: 'Open on ${project.provider.label}',
                    onPressed: _openPage,
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_description == null && description.isEmpty)
              const LinearProgressIndicator(minHeight: 3)
            else ...[
              Text(
                description,
                maxLines: _descExpanded ? null : 4,
                overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
              if (description.length > 200)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _descExpanded = !_descExpanded),
                    child: Text(_descExpanded ? 'Show less' : 'Show more'),
                  ),
                ),
            ],
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    instance == null
                        ? 'No instance selected'
                        : 'Installs into: ${instance.name} (${instance.versionId})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                FilterChip(
                  label: const Text('All versions'),
                  selected: _allVersions,
                  visualDensity: VisualDensity.compact,
                  onSelected: _installingId != null
                      ? null
                      : (v) {
                          _allVersions = v;
                          _loadVersions();
                        },
                ),
              ],
            ),
            if (!project.category.installable)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Modpack installation is coming soon in a later beta.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _messageIsError ? AppColors.danger : AppColors.success,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (_versionsError != null)
              ContentEmptyState(
                message: _versionsError!,
                style: BlockStyle.netherrack,
                action: TextButton(onPressed: _loadVersions, child: const Text('Retry')),
              )
            else if (versions == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (versions.isEmpty)
              const ContentEmptyState(
                message: 'No versions match the current filters. Try "All versions".',
                style: BlockStyle.sand,
              )
            else
              for (final v in versions.take(60)) _versionRow(v),
          ],
        ),
      ),
    );
  }
}
