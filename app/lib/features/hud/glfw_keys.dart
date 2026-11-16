import 'package:flutter/services.dart';

/// Maps Flutter logical keys to GLFW key codes (the subset Minecraft needs).
int? glfwKeyFor(LogicalKeyboardKey key) {
  final id = key.keyId;
  // Letters: Flutter uses the lowercase code unit; GLFW uses uppercase ASCII.
  if (id >= 0x61 && id <= 0x7A) return id - 32;
  // Digits.
  if (id >= 0x30 && id <= 0x39) return id;
  const special = <int, int>{
    0x20: 32, // space
  };
  final s = special[id];
  if (s != null) return s;
  final table = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.escape: 256,
    LogicalKeyboardKey.enter: 257,
    LogicalKeyboardKey.tab: 258,
    LogicalKeyboardKey.backspace: 259,
    LogicalKeyboardKey.arrowRight: 262,
    LogicalKeyboardKey.arrowLeft: 263,
    LogicalKeyboardKey.arrowDown: 264,
    LogicalKeyboardKey.arrowUp: 265,
    LogicalKeyboardKey.shiftLeft: 340,
    LogicalKeyboardKey.controlLeft: 341,
    LogicalKeyboardKey.altLeft: 342,
    LogicalKeyboardKey.shiftRight: 344,
    LogicalKeyboardKey.controlRight: 345,
    for (var i = 0; i < 12; i++) _fn(i): 290 + i,
  };
  return table[key];
}

LogicalKeyboardKey _fn(int i) => [
      LogicalKeyboardKey.f1, LogicalKeyboardKey.f2, LogicalKeyboardKey.f3, LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5, LogicalKeyboardKey.f6, LogicalKeyboardKey.f7, LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9, LogicalKeyboardKey.f10, LogicalKeyboardKey.f11, LogicalKeyboardKey.f12,
    ][i];
