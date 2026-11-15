import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "PLUS" marker for features gated behind a Nuvio Plus licence.
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(colors: [AppColors.neon, AppColors.violet]),
      ),
      child: const Text(
        'PLUS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
