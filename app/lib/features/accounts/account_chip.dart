import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../data/models/account.dart';
import '../shell/navigation_controller.dart';
import 'account_labels.dart';
import 'accounts_controller.dart';
import 'skin_head.dart';

/// Compact "selected account" pill; tapping opens the Accounts tab.
class AccountChip extends StatelessWidget {
  const AccountChip({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>();
    final account = accounts.selected;
    final health = account == null ? null : accounts.healthOf(account);
    final warn = health != null && health != AccountHealth.ok && health != AccountHealth.checking;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.read<NavigationController>().go(AppTab.accounts),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (warn ? AppColors.warning : Theme.of(context).colorScheme.primary).fade(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SkinHead(url: account?.skinUrl, size: 28),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    account?.shownName ?? 'No account',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (account != null && account.type == AccountType.nuvio) ...[
                  const SizedBox(width: 6),
                  const MiniChip(label: 'Nuvio', color: AppColors.neon),
                ],
                if (warn) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
