import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import 'game_overlay.dart';
import 'hud_controller.dart';
import 'input_sink.dart';

/// Edit the touch HUD on a dark preview; opened from Settings.
class HudEditorPage extends StatefulWidget {
  const HudEditorPage({super.key});

  @override
  State<HudEditorPage> createState() => _HudEditorPageState();
}

class _HudEditorPageState extends State<HudEditorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HudController>().setEditMode(true));
  }

  @override
  void dispose() {
    // Provider may already be gone while the route is torn down.
    try {
      context.read<HudController>().setEditMode(false);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GameOverlay(
          sink: const NullInputSink(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B0220), Color(0xFF1A0838)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('HUD editor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Drag buttons. Tap a button, then open settings to resize or hide it.',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
