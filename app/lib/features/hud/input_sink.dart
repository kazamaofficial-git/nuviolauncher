import 'package:flutter/gestures.dart';

/// Where HUD and physical input end up. The Android runtime implements this and forwards to the game.
abstract class GameInputSink {
  void key(int glfwKey, bool down);
  void mouseButton(int button, bool down); // 0 = left, 1 = right, 2 = middle
  void mouseMove(double dx, double dy);
  void scroll(double dy);
}

/// Swallows everything (used by the HUD editor preview).
class NullInputSink implements GameInputSink {
  const NullInputSink();
  @override
  void key(int glfwKey, bool down) {}
  @override
  void mouseButton(int button, bool down) {}
  @override
  void mouseMove(double dx, double dy) {}
  @override
  void scroll(double dy) {}
}

/// Android can report one physical mouse click as both a mouse event and an emulated touch.
/// A touch/stylus event right after a mouse event at the same spot is such an echo and is dropped.
class PointerDeduper {
  PointerDeduper({this.window = const Duration(milliseconds: 80), this.slop = 4});

  final Duration window;
  final double slop;
  Duration? _lastMouseAt;
  Offset? _lastMousePos;

  /// Returns true when the event should be processed.
  bool accept(PointerDeviceKind kind, Offset position, Duration timeStamp) {
    if (kind == PointerDeviceKind.mouse) {
      _lastMouseAt = timeStamp;
      _lastMousePos = position;
      return true;
    }
    final at = _lastMouseAt;
    final pos = _lastMousePos;
    if (at != null && pos != null) {
      final recent = (timeStamp - at).abs() <= window;
      if (recent && (position - pos).distance <= slop) return false;
    }
    return true;
  }
}

/// Makes each physical key go down once and up once (no auto-repeat or duplicate deliveries).
class KeyDeduper {
  final Set<int> _down = <int>{};

  bool down(int key) => _down.add(key);
  bool up(int key) => _down.remove(key);
  void reset() => _down.clear();
  bool get anyDown => _down.isNotEmpty;
}
