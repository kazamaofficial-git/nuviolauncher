import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/account.dart';
import 'account_labels.dart';
import 'accounts_controller.dart';
import 'add_account_flow.dart';
import 'skin_head.dart';

/// Lists all accounts and lets the user add, select, refresh and remove them.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountsController>();
    final accounts = controller.accounts;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeader(
              title: 'Accounts',
              subtitle: 'Microsoft, Nuvio and local accounts. The selected one is used to play.',
              trailing: NeonButton(
                label: 'Add account',
                icon: Icons.add_rounded,
                onPressed: () => showAddAccountDialog(context),
              ),
            ),
            if (accounts.isEmpty)
              const GlassCard(
                child: Text(
                  'No accounts yet. Add a Microsoft, Nuvio or Local account to play.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            for (final a in accounts)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AccountCard(account: a),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final Account account;

  Future<void> _confirmRemove(BuildContext context) async {
    final controller = context.read<AccountsController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          account.type == AccountType.nuvio
              ? '${account.shownName} will be signed out and its token revoked.'
              : '${account.shownName} will be removed from this launcher.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await controller.remove(account.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountsController>();
    final health = controller.healthOf(account);
    final selected = controller.selectedId == account.id;
    final error = controller.errorOf(account.id);

    return GlassCard(
      glow: selected,
      padding: const EdgeInsets.all(12),
      onTap: () => controller.select(account.id),
      child: Row(
        children: [
          SkinHead(url: account.skinUrl, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.shownName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    MiniChip(
                      label: account.type.label,
                      color: account.type == AccountType.nuvio ? AppColors.neon : AppColors.lavender,
                      icon: account.type.icon,
                    ),
                    MiniChip(label: health.label, color: health.color),
                    if (selected) const MiniChip(label: 'Selected', color: AppColors.neon),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                ],
                if (health == AccountHealth.needsRelogin) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => startAddFlow(context, account.type),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Sign in again'),
                  ),
                ],
              ],
            ),
          ),
          if (!selected)
            IconButton(
              tooltip: 'Use this account',
              icon: const Icon(Icons.radio_button_unchecked),
              onPressed: () => controller.select(account.id),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.radio_button_checked, color: AppColors.neon),
            ),
          if (account.type != AccountType.local)
            IconButton(
              tooltip: 'Refresh',
              icon: health == AccountHealth.checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              onPressed: health == AccountHealth.checking
                  ? null
                  : () => controller.refreshAccount(account.id),
            ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmRemove(context),
          ),
        ],
      ),
    );
  }
}
