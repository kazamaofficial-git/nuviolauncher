import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/color_ext.dart';

/// Deep-black galaxy backdrop: soft nebulae plus a slowly twinkling starfield.
class GalaxyBackground extends StatefulWidget {
  const GalaxyBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  )..repeat();

  late final List<_Star> _stars = _generateStars(150);

  static List<_Star> _generateStars(int count) {
    final rnd = math.Random(7);
    return List.generate(count, (_) {
      return _Star(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        radius: 0.4 + rnd.nextDouble() * 1.4,
        phase: rnd.nextDouble() * math.pi * 2,
        twinkle: 8 + rnd.nextInt(40),
        drift: (rnd.nextDouble() - 0.5) * 0.03,
        tint: rnd.nextDouble() < 0.3 ? AppColors.lavender : Colors.white,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _GalaxyPainter(_stars, _controller),
            size: Size.infinite,
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.twinkle,
    required this.drift,
    required this.tint,
  });

  final double x;
  final double y;
  final double radius;
  final double phase;
  final int twinkle;
  final double drift;
  final Color tint;
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter(this.stars, this.animation) : super(repaint: animation);

  final List<_Star> stars;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);

    final t = animation.value;
    final wobble = math.sin(t * math.pi * 2);

    void nebula(Offset c, double r, Color color, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.fade(alpha), color.fade(0)],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    final longest = math.max(size.width, size.height);
    nebula(Offset(size.width * (0.18 + 0.02 * wobble), size.height * 0.22),
        longest * 0.55, AppColors.violet, 0.28);
    nebula(Offset(size.width * 0.85, size.height * (0.78 - 0.02 * wobble)),
        longest * 0.5, AppColors.neon, 0.20);
    nebula(Offset(size.width * 0.55, size.height * 0.5), longest * 0.4,
        const Color(0xFF3B0A7A), 0.18);

    final paint = Paint();
    for (final s in stars) {
      final x = (s.x + wobble * s.drift) * size.width;
      final y = s.y * size.height;
      final tw = 0.5 + 0.5 * math.sin(t * math.pi * 2 * s.twinkle + s.phase);
      final alpha = 0.25 + 0.75 * tw;
      paint.color = s.tint.fade(alpha);
      canvas.drawCircle(Offset(x, y), s.radius, paint);
      if (s.radius > 1.5) {
        paint.color = AppColors.neon.fade(alpha * 0.25);
        canvas.drawCircle(Offset(x, y), s.radius * 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) => false;
}
