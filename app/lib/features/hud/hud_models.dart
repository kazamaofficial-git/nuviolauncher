import 'dart:convert';

/// GLFW key codes used by the default layout (what the game bridge expects).
abstract final class Glfw {
  static const int space = 32;
  static const int a = 65, d = 68, e = 69, q = 81, s = 83, t = 84, w = 87;
  static const int escape = 256, tab = 258, f1 = 290, f5 = 294;
  static const int leftShift = 340, leftCtrl = 341;
}

/// What a HUD button does while pressed.
enum HudAction { key, mouseLeft, mouseRight }

/// One on-screen button. Positions are fractions (0..1) of the screen so layouts survive rotation/resizing.
class HudButton {
  const HudButton({
    required this.id,
    required this.label,
    required this.action,
    this.code = 0,
    required this.x,
    required this.y,
    this.size = 56,
    this.visible = true,
  });

  final String id;
  final String label;
  final HudAction action;

  /// GLFW key code when [action] is [HudAction.key].
  final int code;
  final double x;
  final double y;
  final double size;
  final bool visible;

  HudButton copyWith({double? x, double? y, double? size, bool? visible}) => HudButton(
        id: id,
        label: label,
        action: action,
        code: code,
        x: x ?? this.x,
        y: y ?? this.y,
        size: size ?? this.size,
        visible: visible ?? this.visible,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'action': action.name,
        'code': code,
        'x': x,
        'y': y,
        'size': size,
        'visible': visible,
      };

  factory HudButton.fromJson(Map<String, dynamic> j) => HudButton(
        id: j['id'] as String,
        label: j['label'] as String? ?? '',
        action: HudAction.values.firstWhere(
          (a) => a.name == j['action'],
          orElse: () => HudAction.key,
        ),
        code: (j['code'] as num?)?.toInt() ?? 0,
        x: ((j['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        y: ((j['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        size: ((j['size'] as num?)?.toDouble() ?? 56).clamp(32.0, 120.0),
        visible: j['visible'] as bool? ?? true,
      );
}

/// A full set of HUD buttons.
class HudLayout {
  const HudLayout(this.buttons);

  final List<HudButton> buttons;

  static HudLayout defaults() => const HudLayout([
        HudButton(id: 'fwd', label: 'W', action: HudAction.key, code: Glfw.w, x: 0.14, y: 0.58),
        HudButton(id: 'left', label: 'A', action: HudAction.key, code: Glfw.a, x: 0.07, y: 0.72),
        HudButton(id: 'back', label: 'S', action: HudAction.key, code: Glfw.s, x: 0.14, y: 0.86),
        HudButton(id: 'right', label: 'D', action: HudAction.key, code: Glfw.d, x: 0.21, y: 0.72),
        HudButton(id: 'jump', label: '⤒', action: HudAction.key, code: Glfw.space, x: 0.88, y: 0.72, size: 64),
        HudButton(id: 'sneak', label: '⇩', action: HudAction.key, code: Glfw.leftShift, x: 0.80, y: 0.86),
        HudButton(id: 'sprint', label: '»', action: HudAction.key, code: Glfw.leftCtrl, x: 0.07, y: 0.44, size: 48),
        HudButton(id: 'attack', label: '⚔', action: HudAction.mouseLeft, x: 0.88, y: 0.50, size: 64),
        HudButton(id: 'use', label: '✋', action: HudAction.mouseRight, x: 0.78, y: 0.64),
        HudButton(id: 'inv', label: 'E', action: HudAction.key, code: Glfw.e, x: 0.50, y: 0.92, size: 48),
        HudButton(id: 'chat', label: 'T', action: HudAction.key, code: Glfw.t, x: 0.60, y: 0.92, size: 48),
        HudButton(id: 'drop', label: 'Q', action: HudAction.key, code: Glfw.q, x: 0.40, y: 0.92, size: 48),
        HudButton(id: 'view', label: 'F5', action: HudAction.key, code: Glfw.f5, x: 0.93, y: 0.30, size: 44),
        HudButton(id: 'menu', label: 'Esc', action: HudAction.key, code: Glfw.escape, x: 0.50, y: 0.08, size: 44),
      ]);

  HudLayout map(HudButton Function(HudButton) f) => HudLayout(buttons.map(f).toList());

  String encode() => jsonEncode(buttons.map((b) => b.toJson()).toList());

  static HudLayout decode(String? raw) {
    if (raw == null || raw.isEmpty) return defaults();
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final layout = HudLayout(list.map(HudButton.fromJson).toList());
      return layout.buttons.isEmpty ? defaults() : layout;
    } catch (_) {
      return defaults();
    }
  }
}
