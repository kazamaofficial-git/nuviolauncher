import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/block_icon.dart';
import '../../core/widgets/neon_input.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/content/content_models.dart';
import '../../data/models/instance.dart';
import '../shell/navigation_controller.dart';
import 'content_card.dart';
import 'content_controller.dart';
import 'content_detail_dialog.dart';
import 'content_widgets.dart';
import 'installed_view.dart';

/// Browse and install mods, shaders, resource packs, modpacks and worlds.
class ContentHubPage extends StatefulWidget {
  const ContentHubPage({super.key});

  @override
  State<ContentHubPage> createState() => _ContentHubPageState();
}

class _ContentHubPageState extends State<ContentHubPage> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _version = TextEditingController();
  bool _showInstalled = false;
  String _syncedVersion = '';

  @override
  void dispose() {
    _search.dispose();
    _version.dispose();
    super.dispose();
  }

  /// Keeps the version field in sync when the selected instance changes.
  void _syncVersion(String value) {
    if (value == _syncedVersion) return;
    _syncedVersion = value;
    if (_version.text == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _version.text != value) _version.text = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContentController>();
    final onTab = context.watch<NavigationController>().index == AppTab.content;
    if (onTab) controller.ensureLoaded();
    _syncVersion(controller.gameVersion);

    final results = controller.results;
    final unsupported = controller.unsupportedMessage;

    Widget? status;
    if (_showInstalled) {
      status = null;
    } else if (unsupported != null) {
      status = ContentEmptyState(message: unsupported, style: BlockStyle.endStone);
    } else if (controller.loading) {
      status = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (controller.error != null && results.isEmpty) {
      status = ContentEmptyState(
        message: controller.error!,
        style: BlockStyle.netherrack,
        action: TextButton(onPressed: controller.refresh, child: const Text('Retry')),
      );
    } else if (results.isEmpty) {
      status = const ContentEmptyState(
        message: 'No results. Try another search or filter.',
        style: BlockStyle.dirt,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _header(context, controller)),
            ),
            if (_showInstalled)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: InstalledView(
                    key: ValueKey(controller.selectedInstance?.id),
                    controller: controller,
                  ),
                ),
              )
            else if (status != null)
              SliverToBoxAdapter(child: status)
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i < results.length) {
                        final project = results[i];
                        return ContentCard(
                          project: project,
                          onTap: () => showContentDetail(context, controller, project),
                        );
                      }
                      return _loadMore(controller);
                    },
                    childCount: results.length + (controller.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _loadMore(ContentController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: controller.loadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: controller.loadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more'),
              ),
      ),
    );
  }

  Widget _header(BuildContext context, ContentController controller) {
    final instance = controller.selectedInstance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Content',
          subtitle: instance == null
              ? 'Create an instance to install content'
              : 'Installing into ${instance.name} (${instance.versionId})',
          trailing: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Browse')),
              ButtonSegment(value: true, label: Text('Installed')),
            ],
            selected: {_showInstalled},
            onSelectionChanged: (s) => setState(() => _showInstalled = s.first),
          ),
        ),
        if (!_showInstalled) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in ContentCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.label),
                      selected: controller.category == c,
                      onSelected: (_) => controller.setCategory(c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<ContentProviderId>(
                showSelectedIcon: false,
                segments: [
                  for (final p in ContentProviderId.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.label),
                      enabled: controller.isProviderAvailable(p),
                    ),
                ],
                selected: {controller.providerId},
                onSelectionChanged: (s) => controller.setProvider(s.first),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _search,
                  decoration: neonInputDecoration(
                    context,
                    hint: 'Search ${controller.category.label.toLowerCase()}',
                    prefixIcon: Icons.search_rounded,
                  ).copyWith(isDense: true),
                  onChanged: controller.setText,
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _version,
                  decoration: neonInputDecoration(context, label: 'MC version')
                      .copyWith(isDense: true),
                  onChanged: (v) => controller.setGameVersion(v.trim()),
                ),
              ),
              if (controller.category.supportsLoader)
                DropdownButtonHideUnderline(
                  child: DropdownButton<LoaderType>(
                    value: controller.loader,
                    items: [
                      for (final l in LoaderType.values)
                        DropdownMenuItem(
                          value: l,
                          child: Text(l == LoaderType.vanilla ? 'Any loader' : l.label),
                        ),
                    ],
                    onChanged: (l) {
                      if (l != null) controller.setLoader(l);
                    },
                  ),
                ),
            ],
          ),
          if (!controller.curseForgeAvailable)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'CurseForge is disabled: this build has no CURSEFORGE_API_KEY. '
                'Worlds are only listed on CurseForge.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
