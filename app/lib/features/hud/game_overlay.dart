import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import 'glfw_keys.dart';
import 'hud_controller.dart';
import 'hud_models.dart';
import 'hud_settings_dialog.dart';
import 'input_sink.dart';

/// Touch HUD drawn over the game surface. It also listens to physical keyboard and mouse:
/// those go straight to [sink] once (no echo), and the buttons hide automatically while they are in use.
class GameOverlay extends StatefulWidget {
  const GameOverlay({super.key, required this.sink, required this.child});

  final GameInputSink sink;

  /// The game surface (or a preview background in the editor).
  final Widget child;

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  final _pointers = PointerDeduper();
  final _keys = KeyDeduper();
  Offset? _lastMouse;
  int _mouseButton = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    final hud = context.read<HudController>();
    if (hud.editMode) return false;
    final code = glfwKeyFor(event.logicalKey);
    if (code == null) return false;
    if (event is KeyDownEvent) {
      if (_keys.down(code)) {
        hud.physicalInputSeen();
        widget.sink.key(code, true);
      }
      return true;
    }
    if (event is KeyUpEvent) {
      if (_keys.up(code)) widget.sink.key(code, false);
      return true;
    }
    return true; // KeyRepeatEvent: the game repeats by itself, so drop it
  }

  void _onPointer(PointerEvent e, {required bool down, required bool up}) {
    final hud = context.read<HudController>();
    if (!_pointers.accept(e.kind, e.position, e.timeStamp)) return;
    if (e.kind == PointerDeviceKind.mouse) {
      hud.physicalInputSeen();
      if (hud.editMode) return;
      final last = _lastMouse;
      if (last != null && !down && !up) {
        final d = e.position - last;
        if (d != Offset.zero) widget.sink.mouseMove(d.dx, d.dy);
      }
      _lastMouse = e.position;
      if (down) {
        _mouseButton = (e.buttons & kSecondaryMouseButton) != 0
            ? 1
            : (e.buttons & kMiddleMouseButton) != 0
                ? 2
                : 0;
        widget.sink.mouseButton(_mouseButton, true);
      } else if (up) {
        widget.sink.mouseButton(_mouseButton, false);
      }
    } else if (down) {
      hud.touchSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hud = context.watch<HudController>();
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _onPointer(e, down: true, up: false),
      onPointerMove: (e) => _onPointer(e, down: false, up: false),
      onPointerUp: (e) => _onPointer(e, down: false, up: true),
      onPointerSignal: (s) {
        if (s is PointerScrollEvent && !hud.editMode) widget.sink.scroll(s.scrollDelta.dy);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (hud.showButtons) _Buttons(sink: widget.sink),
          const _TopBar(),
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.sink});

  final GameInputSink sink;

  @override
  Widget build(BuildContext context) {
    final hud = context.watch<HudController>();
    return LayoutBuilder(
      builder: (context, box) {
        return Stack(
          children: [
            for (final b in hud.layout.buttons)
              if (b.visible || hud.editMode)
                _HudButtonView(
                  key: ValueKey(b.id),
                  button: b,
                  area: box.biggest,
                  sink: sink,
                ),
          ],
        );
      },
    );
  }
}

class _HudButtonView extends StatefulWidget {
  const _HudButtonView({super.key, required this.button, required this.area, required this.sink});

  final HudButton button;
  final Size area;
  final GameInputSink sink;

  @override
  State<_HudButtonView> createState() => _HudButtonViewState();
}

class _HudButtonViewState extends State<_HudButtonView> {
  bool _pressed = false;

  void _fire(bool down) {
    final b = widget.button;
    setState(() => _pressed = down);
    switch (b.action) {
      case HudAction.key:
        widget.sink.key(b.code, down);
      case HudAction.mouseLeft:
        widget.sink.mouseButton(0, down);
      case HudAction.mouseRight:
        widget.sink.mouseButton(1, down);
    }
  }

  @override
  void dispose() {
    if (_pressed) _fire(false); // never leave a key stuck down
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hud = context.watch<HudController>();
    final b = widget.button;
    final size = b.size * hud.scale;
    final selected = hud.editMode && hud.selectedId == b.id;
    final dimmed = hud.editMode && !b.visible;
    final color = AppColors.neon;

    final visual = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (_pressed ? color : Colors.black).withValues(alpha: _pressed ? 0.55 : 0.45),
        border: Border.all(
          color: selected ? Colors.white : color.withValues(alpha: 0.9),
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)],
      ),
      child: Text(
        b.label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.34),
      ),
    );

    return Positioned(
      left: widget.area.width * b.x - size / 2,
      top: widget.area.height * b.y - size / 2,
      child: Opacity(
        opacity: dimmed ? 0.3 : hud.opacity,
        child: hud.editMode
            ? GestureDetector(
                onTap: () => hud.select(b.id),
                onPanStart: (_) => hud.select(b.id),
                onPanUpdate: (d) => hud.moveButton(
                  b.id,
                  b.x + d.delta.dx / widget.area.width,
                  b.y + d.delta.dy / widget.area.height,
                ),
                child: visual,
              )
            : Listener(
                onPointerDown: (_) => _fire(true),
                onPointerUp: (_) => _fire(false),
                onPointerCancel: (_) => _fire(false),
                child: visual,
              ),
      ),
    );
  }
}

/// Always-visible mini toolbar: hide/show HUD, settings, edit.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final hud = context.watch<HudController>();
    Widget icon(IconData data, String tip, VoidCallback onTap, {bool active = false}) => IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          color: active ? AppColors.neon : Colors.white,
          icon: Icon(data),
          onPressed: onTap,
        );
    return Positioned(
      top: 6,
      right: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neon.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon(
              hud.hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              hud.hidden ? 'Show HUD' : 'Hide HUD',
              hud.toggleHidden,
              active: hud.hidden,
            ),
            icon(Icons.tune_rounded, 'HUD settings', () => showHudSettings(context)),
            icon(
              Icons.edit_rounded,
              hud.editMode ? 'Finish editing' : 'Edit layout',
              () => hud.setEditMode(!hud.editMode),
              active: hud.editMode,
            ),
          ],
        ),
      ),
    );
  }
}
