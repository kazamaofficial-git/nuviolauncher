import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../data/models/account.dart';
import 'accounts_controller.dart';

extension AccountTypeUi on AccountType {
  String get label => switch (this) {
        AccountType.microsoft => 'Microsoft',
        AccountType.nuvio => 'Nuvio',
        AccountType.local => 'Local',
      };

  IconData get icon => switch (this) {
        AccountType.microsoft => Icons.verified_user_outlined,
        AccountType.nuvio => Icons.auto_awesome,
        AccountType.local => Icons.person_outline_rounded,
      };
}

extension AccountHealthUi on AccountHealth {
  String get label => switch (this) {
        AccountHealth.ok => 'OK',
        AccountHealth.checking => 'Checking...',
        AccountHealth.needsRelogin => 'Needs re-login',
        AccountHealth.noJava => 'No Java license',
        AccountHealth.noProfile => 'No Minecraft profile',
        AccountHealth.offline => 'Offline',
      };

  Color get color => switch (this) {
        AccountHealth.ok => AppColors.success,
        AccountHealth.checking => AppColors.lavender,
        AccountHealth.needsRelogin => AppColors.warning,
        AccountHealth.noJava => AppColors.danger,
        AccountHealth.noProfile => AppColors.warning,
        AccountHealth.offline => AppColors.textMuted,
      };
}

/// Small rounded label with an optional icon.
class MiniChip extends StatelessWidget {
  const MiniChip({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.fade(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.fade(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
