import 'package:flutter/material.dart';

/// The Nuvio logo badge drawn before the name of a Nuvio account.
class NuvioBadge extends StatelessWidget {
  const NuvioBadge({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Image.asset(
          'assets/brand/badge.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Nuvio',
        ),
      );
}
