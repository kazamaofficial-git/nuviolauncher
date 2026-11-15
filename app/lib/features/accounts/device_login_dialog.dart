import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';
import '../../core/widgets/neon_button.dart';
import '../../data/models/account.dart';
import '../../data/models/auth_exception.dart';
import '../../data/models/device_code.dart';
import '../../data/services/auth/device_poll.dart';

/// Outcome of a device login dialog.
class DeviceLoginResult {
  const DeviceLoginResult({this.account, this.error, this.cancelled = false});

  final Account? account;
  final String? error;
  final bool cancelled;
}

typedef DeviceLoginRunner = Future<Account> Function(
  void Function(DeviceCode code) onCode,
  AuthCancelToken cancel,
);

/// Shows the user code + link, a countdown, and runs the login in the background.
class DeviceLoginDialog extends StatefulWidget {
  const DeviceLoginDialog({
    super.key,
    required this.title,
    required this.instructions,
    required this.run,
  });

  final String title;
  final String instructions;
  final DeviceLoginRunner run;

  @override
  State<DeviceLoginDialog> createState() => _DeviceLoginDialogState();
}

class _DeviceLoginDialogState extends State<DeviceLoginDialog> {
  final AuthCancelToken _cancel = AuthCancelToken();
  DeviceCode? _code;
  DateTime? _expiresAt;
  Timer? _ticker;
  Duration _left = Duration.zero;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cancel.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final account = await widget.run(_onCode, _cancel);
      _finish(DeviceLoginResult(account: account));
    } on AuthException catch (e) {
      _finish(e.kind == AuthErrorKind.cancelled
          ? const DeviceLoginResult(cancelled: true)
          : DeviceLoginResult(error: e.message));
    } catch (e) {
      _finish(DeviceLoginResult(error: 'Unexpected error: $e'));
    }
  }

  void _onCode(DeviceCode code) {
    if (!mounted) return;
    _expiresAt = DateTime.now().add(Duration(seconds: code.expiresIn));
    setState(() {
      _code = code;
      _left = Duration(seconds: code.expiresIn);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final end = _expiresAt;
      if (end == null || !mounted) return;
      final left = end.difference(DateTime.now());
      setState(() => _left = left.isNegative ? Duration.zero : left);
    });
    unawaited(_open());
  }

  Future<void> _open() async {
    final code = _code;
    if (code == null) return;
    try {
      await launchUrl(Uri.parse(code.verificationUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      // The link is also shown on screen.
    }
  }

  void _finish(DeviceLoginResult result) {
    if (_finished) return;
    _finished = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  String get _countdown {
    final m = _left.inMinutes.toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    final accent = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (code == null) ...[
                const Text('Contacting the server...'),
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ] else ...[
                Text(widget.instructions, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh.fade(0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.fade(0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          code.userCode,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy code',
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code.userCode));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  code.verificationUrl,
                  style: const TextStyle(color: AppColors.lavender, fontSize: 12),
                ),
                const SizedBox(height: 10),
                NeonButton(
                  label: 'Open in browser',
                  icon: Icons.open_in_new_rounded,
                  outlined: true,
                  onPressed: _open,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _left == Duration.zero
                            ? 'Code expired.'
                            : 'Waiting for approval... expires in $_countdown',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _cancel.cancel();
            _finish(const DeviceLoginResult(cancelled: true));
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
