import 'dart:io';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../utils/color_ext.dart';

/// Builds the dark neon theme for a given accent colour.
abstract final class AppTheme {
  static ThemeData build(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: AppColors.lavender,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Transparent so the galaxy background behind the navigator shows through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.surface,
      fontFamily: Platform.isWindows ? 'Segoe UI' : null,
      dividerColor: accent.fade(0.18),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: accent.fade(0.25),
        selectedIconTheme: const IconThemeData(color: AppColors.lavender),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.lavender,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface.fade(0.94),
        selectedItemColor: AppColors.lavender,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
    );
  }
}
