import 'package:flutter/material.dart';

/// Brand palette: neon purple, violet and lavender on deep black.
abstract final class AppColors {
  static const Color background = Color(0xFF05000D);
  static const Color surface = Color(0xFF0E0820);
  static const Color surfaceHigh = Color(0xFF1A0F36);

  static const Color neon = Color(0xFFA855F7);
  static const Color violet = Color(0xFF7C3AED);
  static const Color lavender = Color(0xFFC4B5FD);

  static const Color text = Color(0xFFF5F0FF);
  static const Color textMuted = Color(0xFF9D8FC0);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  /// Accent choices unlocked by Nuvio Plus.
  static const List<Color> accentChoices = [
    neon,
    violet,
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
    lavender,
  ];
}
