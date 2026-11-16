import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'hud_controller.dart';

Future<void> showHudSettings(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<HudController>.value(
        value: context.read<HudController>(),
        child: const _HudSettingsDialog(),
      ),
    );

class _HudSettingsDialog extends StatelessWidget {
  const _HudSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final hud = context.watch<HudController>();
    final sel = hud.selected;
    return AlertDialog(
      title: const Text('HUD settings'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide buttons'),
                value: hud.hidden,
                onChanged: (_) => hud.toggleHidden(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-hide with keyboard / mouse'),
                subtitle: const Text('Buttons disappear while a physical keyboard or mouse is used and return on touch.'),
                value: hud.autoHide,
                onChanged: hud.setAutoHide,
              ),
              const SizedBox(height: 8),
              Text('Opacity ${(hud.opacity * 100).round()}%'),
              Slider(value: hud.opacity, min: 0.2, max: 1, onChanged: hud.setOpacity),
              Text('Button scale ${(hud.scale * 100).round()}%'),
              Slider(value: hud.scale, min: 0.6, max: 1.6, onChanged: hud.setScale),
              if (hud.editMode && sel != null) ...[
                const Divider(),
                Text('Selected: ${sel.label}'),
                Slider(
                  value: sel.size.clamp(32, 120),
                  min: 32,
                  max: 120,
                  onChanged: (v) => hud.resizeButton(sel.id, v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible'),
                  value: sel.visible,
                  onChanged: (v) => hud.setButtonVisible(sel.id, v),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Tap the pencil to drag, resize or hide individual buttons.',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: hud.resetLayout, child: const Text('Reset layout')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    );
  }
}
