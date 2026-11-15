import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/color_ext.dart';

/// Glowing tilted orbital rings with a small orbiting "planet",
/// drawn behind (and around) an optional [child] such as the logo.
class OrbitalRing extends StatefulWidget {
  const OrbitalRing({super.key, this.size = 220, this.child, this.color});

  final double size;
  final Widget? child;
  final Color? color;

  @override
  State<OrbitalRing> createState() => _OrbitalRingState();
}

class _OrbitalRingState extends State<OrbitalRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _OrbitPainter(_controller, color),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = animation.value;

    void ring({
      required double scale,
      required double tilt,
      required double spin,
      required double width,
      required double planetSpeed,
    }) {
      final a = size.width * 0.5 * scale;
      final b = a * 0.36;
      final rect = Rect.fromCenter(center: Offset.zero, width: a * 2, height: b * 2);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(tilt + t * math.pi * 2 * spin);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = SweepGradient(
          colors: [color.fade(0), color, Colors.white.fade(0.9), color.fade(0)],
          stops: const [0.0, 0.45, 0.6, 1.0],
        ).createShader(rect);
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..shader = stroke.shader;
      canvas.drawOval(rect, glow);
      canvas.drawOval(rect, stroke);

      final theta = t * math.pi * 2 * planetSpeed;
      final p = Offset(a * math.cos(theta), b * math.sin(theta));
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = color.fade(0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(p, 2.4, Paint()..color = Colors.white);
      canvas.restore();
    }

    ring(scale: 0.95, tilt: -0.45, spin: 1, width: 1.6, planetSpeed: 2);
    ring(scale: 0.72, tilt: 0.55, spin: -1, width: 1.2, planetSpeed: 3);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}
