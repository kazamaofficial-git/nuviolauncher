import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/neon_input.dart';
import '../../core/widgets/plus_badge.dart';
import '../../data/models/instance.dart';
import '../license/license_controller.dart';
import '../settings/settings_controller.dart';
import '../versions/versions_controller.dart';

/// Values collected by [InstanceEditorDialog].
class InstanceDraft {
  const InstanceDraft({
    required this.name,
    required this.versionId,
    required this.loader,
    required this.renderer,
    required this.ramMb,
    required this.jvmArgs,
  });

  final String name;
  final String versionId;
  final LoaderType loader;
  final String renderer;
  final int ramMb;
  final String jvmArgs;
}

/// Create/edit dialog for an instance. Pops an [InstanceDraft] on save.
class InstanceEditorDialog extends StatefulWidget {
  const InstanceEditorDialog({super.key, this.existing, this.presetVersionId});

  final Instance? existing;
  final String? presetVersionId;

  @override
  State<InstanceEditorDialog> createState() => _InstanceEditorDialogState();
}

class _InstanceEditorDialogState extends State<InstanceEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _jvm;
  String? _versionId;
  late LoaderType _loader;
  late String _renderer;
  late double _ram;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final defaultRam = context.read<SettingsController>().settings.defaultRamMb;
    _name = TextEditingController(text: e?.name ?? 'My instance');
    _jvm = TextEditingController(text: e?.jvmArgs ?? '');
    _versionId = e?.versionId ?? widget.presetVersionId;
    _loader = e?.loader ?? LoaderType.vanilla;
    _renderer = e?.renderer ?? AppConstants.renderers.first;
    _ram = (e?.ramMb ?? defaultRam)
        .clamp(AppConstants.minRamMb, AppConstants.maxRamMb)
        .toDouble();
    context.read<VersionsController>().ensureLoaded();
  }

  @override
  void dispose() {
    _name.dispose();
    _jvm.dispose();
    super.dispose();
  }

  void _save(bool hasPlus) {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your instance a name.');
      return;
    }
    final version = _versionId;
    if (version == null) {
      setState(() => _error = 'Choose a Minecraft version.');
      return;
    }
    Navigator.pop(
      context,
      InstanceDraft(
        name: name,
        versionId: version,
        loader: _loader,
        renderer: _renderer,
        ramMb: _ram.round(),
        // JVM profiles are a Plus feature; keep the stored value when locked.
        jvmArgs: hasPlus ? _jvm.text.trim() : (widget.existing?.jvmArgs ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final versions = context.watch<VersionsController>();
    final hasPlus = context.watch<LicenseController>().hasPlus;

    final ids = <String>{
      if (_versionId != null) _versionId!,
      ...versions.releases.map((v) => v.id),
    }.toList();

    return AlertDialog(
      title: Text(widget.existing == null ? 'New instance' : 'Edit instance'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: neonInputDecoration(context, label: 'Name'),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: neonInputDecoration(
                  context,
                  label: 'Minecraft version',
                  helper: versions.loading ? 'Loading versions...' : versions.error,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _versionId,
                    isExpanded: true,
                    hint: const Text('Select a version'),
                    items: [
                      for (final id in ids) DropdownMenuItem(value: id, child: Text(id)),
                    ],
                    onChanged: (v) => setState(() => _versionId = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: neonInputDecoration(
                  context,
                  label: 'Mod loader',
                  helper: _loader.isSupported
                      ? null
                      : '${_loader.label} support is coming soon - the instance can be saved but not launched yet.',
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LoaderType>(
                    value: _loader,
                    isExpanded: true,
                    items: [
                      for (final l in LoaderType.values)
                        DropdownMenuItem(
                          value: l,
                          child: Text(l.isSupported ? l.label : '${l.label} (coming soon)'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _loader = v ?? _loader),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: neonInputDecoration(context, label: 'Renderer'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _renderer,
                    isExpanded: true,
                    items: [
                      for (final r in AppConstants.renderers)
                        DropdownMenuItem(value: r, child: Text(r)),
                    ],
                    onChanged: (v) => setState(() => _renderer = v ?? _renderer),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Memory: ${formatRam(_ram.round())}',
                  style: const TextStyle(color: AppColors.textMuted)),
              Slider(
                min: AppConstants.minRamMb.toDouble(),
                max: AppConstants.maxRamMb.toDouble(),
                divisions:
                    (AppConstants.maxRamMb - AppConstants.minRamMb) ~/ AppConstants.ramStepMb,
                value: _ram,
                onChanged: (v) => setState(() => _ram = v),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _jvm,
                enabled: hasPlus,
                decoration: neonInputDecoration(
                  context,
                  label: 'JVM arguments',
                  hint: '-XX:+UseG1GC',
                  helper: hasPlus ? null : 'Per-instance JVM profiles require Nuvio Plus.',
                  suffix: hasPlus
                      ? null
                      : const Padding(padding: EdgeInsets.all(12), child: PlusBadge()),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => _save(hasPlus), child: const Text('Save')),
      ],
    );
  }
}
