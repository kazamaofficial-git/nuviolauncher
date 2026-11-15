import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../core/utils/offline_uuid.dart';
import '../../core/widgets/neon_input.dart';
import '../../data/models/account.dart';
import '../../data/models/auth_exception.dart';
import 'account_labels.dart';
import 'accounts_controller.dart';
import 'device_login_dialog.dart';

/// Opens the "Add account" chooser and runs the chosen sign-in flow.
Future<void> showAddAccountDialog(BuildContext context) async {
  final accounts = context.read<AccountsController>();
  final type = await showDialog<AccountType>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _OptionTile(
                icon: AccountType.microsoft.icon,
                title: 'Microsoft',
                subtitle: accounts.microsoftConfigured
                    ? 'Real Minecraft account. Works on every server.'
                    : 'Not configured in this build.',
                enabled: accounts.microsoftConfigured,
                onTap: () => Navigator.pop(ctx, AccountType.microsoft),
              ),
              _OptionTile(
                icon: AccountType.nuvio.icon,
                title: 'Nuvio Account',
                subtitle: 'Link with the Nuvio website. Custom skin and cape.',
                onTap: () => Navigator.pop(ctx, AccountType.nuvio),
              ),
              _OptionTile(
                icon: AccountType.local.icon,
                title: 'Local (offline)',
                subtitle: 'Just a username. No skin, no online servers.',
                onTap: () => Navigator.pop(ctx, AccountType.local),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (type == null || !context.mounted) return;
  await startAddFlow(context, type);
}

/// Runs the sign-in flow for [type] (also used for "Sign in again").
Future<void> startAddFlow(BuildContext context, AccountType type) async {
  final controller = context.read<AccountsController>();
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));

  switch (type) {
    case AccountType.local:
      final name = await showDialog<String>(
        context: context,
        builder: (_) => const _LocalDialog(),
      );
      if (name == null) return;
      try {
        final a = await controller.addLocal(name);
        say('Added ${a.shownName}');
      } on AuthException catch (e) {
        say(e.message);
      }
    case AccountType.microsoft:
      if (!controller.microsoftConfigured) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Microsoft login unavailable'),
            content: const Text('Microsoft login is not configured in this build.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
        return;
      }
      final msResult = await showDialog<DeviceLoginResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeviceLoginDialog(
          title: 'Sign in with Microsoft',
          instructions: 'Open the link below and enter this code to sign in.',
          run: (onCode, cancel) => controller.addMicrosoft(onCode: onCode, cancel: cancel),
        ),
      );
      _report(msResult, say);
    case AccountType.nuvio:
      final nuvioResult = await showDialog<DeviceLoginResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeviceLoginDialog(
          title: 'Link Nuvio Account',
          instructions: 'Approve this device on the Nuvio website. The code must match.',
          run: (onCode, cancel) => controller.addNuvio(onCode: onCode, cancel: cancel),
        ),
      );
      _report(nuvioResult, say);
  }
}

void _report(DeviceLoginResult? result, void Function(String) say) {
  if (result == null || result.cancelled) return;
  final error = result.error;
  if (error != null) {
    say(error);
    return;
  }
  final a = result.account;
  if (a == null) return;
  if (a.type == AccountType.microsoft && !a.ownsJava) {
    say('${a.shownName} was added, but it has no Minecraft Java license, so it cannot launch the game.');
  } else {
    say('Signed in as ${a.shownName}');
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceHigh.fade(0.6),
              border: Border.all(color: accent.fade(0.35)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.lavender),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalDialog extends StatefulWidget {
  const _LocalDialog();

  @override
  State<_LocalDialog> createState() => _LocalDialogState();
}

class _LocalDialogState extends State<_LocalDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (!isValidUsername(name)) {
      setState(() => _error = '3-16 letters, digits or underscore');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Local account'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 16,
                decoration: neonInputDecoration(
                  context,
                  label: 'Username',
                  helper: 'Offline mode: no skin, no online-mode servers',
                  errorText: _error,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
