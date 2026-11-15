import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/neon_input.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/license_state.dart';
import 'license_controller.dart';

/// Nuvio Plus activation and status.
class LicensePage extends StatefulWidget {
  const LicensePage({super.key});

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final TextEditingController _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  (String, Color) _statusLabel(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return ('Active', AppColors.success);
      case LicenseStatus.expired:
        return ('Expired', AppColors.danger);
      case LicenseStatus.needsRevalidation:
        return ('Go online to re-verify', AppColors.warning);
      case LicenseStatus.none:
        return ('Not activated', AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseController>();
    final state = license.state;
    final (label, color) = _statusLabel(license.status);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              title: 'Nuvio Plus',
              subtitle: 'Unlock extra features with a licence key',
            ),
            GlassCard(
              glow: license.hasPlus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: color),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (state != null) ...[
                    const SizedBox(height: 14),
                    _InfoRow('Licence', state.info.keyMasked),
                    _InfoRow('Plan', state.info.plan),
                    _InfoRow('Devices', '${state.info.devicesUsed} / ${state.info.maxDevices}'),
                    _InfoRow(
                      'Expires',
                      state.info.expiresAt == null
                          ? 'Never'
                          : formatDate(state.info.expiresAt!),
                    ),
                    _InfoRow('Last verified', formatDateTime(state.checkedAt)),
                    const SizedBox(height: 14),
                    NeonButton(
                      label: 'Remove from this device',
                      icon: Icons.link_off_rounded,
                      outlined: true,
                      loading: license.busy,
                      onPressed: license.deactivate,
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _key,
                      textCapitalization: TextCapitalization.characters,
                      decoration: neonInputDecoration(
                        context,
                        label: 'Licence key',
                        hint: 'NUVIO-XXXX-XXXX-XXXX',
                        prefixIcon: Icons.key_rounded,
                      ),
                      onSubmitted: (v) => license.activate(v),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        NeonButton(
                          label: 'Activate',
                          icon: Icons.bolt_rounded,
                          loading: license.busy,
                          onPressed: () => license.activate(_key.text),
                        ),
                        NeonButton(
                          label: 'Get a licence',
                          icon: Icons.open_in_new_rounded,
                          outlined: true,
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.resolveUrl('/')),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (license.message != null) ...[
                    const SizedBox(height: 12),
                    Text(license.message!, style: const TextStyle(color: AppColors.lavender)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('What you get', icon: Icons.auto_awesome_outlined),
                  _Perk('Unlimited instances (free plan: ${AppConstants.freeInstanceLimit})'),
                  _Perk('Custom accent colours'),
                  _Perk('Per-instance JVM profiles'),
                  SizedBox(height: 6),
                  Text(
                    'Your licence works offline for 7 days between online checks.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
