import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/color_ext.dart';

/// Small "BETA" pill shown next to the product name.
class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key, this.label = 'BETA'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lavender.fade(0.8)),
        color: AppColors.violet.fade(0.25),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.lavender,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
