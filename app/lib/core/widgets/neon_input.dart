import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/color_ext.dart';

/// Shared input decoration (avoids relying on theme-level input styling).
InputDecoration neonInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? helper,
  String? errorText,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  final accent = Theme.of(context).colorScheme.primary;
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    errorText: errorText,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surfaceHigh.fade(0.55),
    border: border(accent.fade(0.3)),
    enabledBorder: border(accent.fade(0.3)),
    focusedBorder: border(accent, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.6),
  );
}
