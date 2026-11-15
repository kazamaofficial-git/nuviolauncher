import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/beta_badge.dart';
import '../accounts/accounts_page.dart';
import '../content/content_hub_page.dart';
import '../home/home_page.dart';
import '../instances/instances_page.dart';
import '../license/license_page.dart';
import '../settings/settings_page.dart';
import '../versions/versions_page.dart';
import 'navigation_controller.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_Destination> _destinations = [
  _Destination('Home', Icons.home_outlined, Icons.home_rounded),
  _Destination('Instances', Icons.apps_outlined, Icons.apps_rounded),
  _Destination('Versions', Icons.layers_outlined, Icons.layers_rounded),
  _Destination('Content', Icons.extension_outlined, Icons.extension_rounded),
  _Destination('Accounts', Icons.account_circle_outlined, Icons.account_circle),
  _Destination('Plus', Icons.workspace_premium_outlined, Icons.workspace_premium),
  _Destination('Settings', Icons.settings_outlined, Icons.settings),
];

/// Landscape-only scaffold: a compact, scrollable side navigation + page body.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = [
    HomePage(),
    InstancesPage(),
    VersionsPage(),
    ContentHubPage(),
    AccountsPage(),
    LicensePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationController>();
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _SideNav(selected: nav.index, onSelect: nav.go),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            Expanded(child: IndexedStack(index: nav.index, children: _pages)),
          ],
        ),
      ),
    );
  }
}

/// Scrollable so it never overflows on short (phone landscape) screens.
class _SideNav extends StatelessWidget {
  const _SideNav({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          const _RailBrand(),
          for (var i = 0; i < _destinations.length; i++)
            _NavItem(
              destination: _destinations[i],
              selected: i == selected,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.lavender : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? AppColors.neon.withValues(alpha: 0.16) : null,
            border: Border.all(
              color: selected ? AppColors.neon.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? destination.selectedIcon : destination.icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                destination.label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/brand/icon.png', width: 40, height: 40),
          ),
          const SizedBox(height: 6),
          const Text(
            'NUVIO',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const BetaBadge(),
        ],
      ),
    );
  }
}
