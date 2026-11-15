import 'package:flutter/material.dart';

/// Block looks supported by [BlockIcon].
enum BlockStyle {
  grass,
  dirt,
  stone,
  sand,
  snow,
  amethyst,
  netherrack,
  endStone,
  planks;

  /// Deterministic style for any seed (e.g. a project id).
  static BlockStyle fromSeed(String seed) {
    var h = 17;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return BlockStyle.values[h % BlockStyle.values.length];
  }
}

class _Palette {
  const _Palette(this.top, this.side, {this.cap, this.bands = false, this.sparkle = false});

  final Color top;
  final Color side;

  /// Colour drawn over the upper rows of the side faces (grass, snow).
  final Color? cap;
  final bool bands;
  final bool sparkle;
}

const Map<BlockStyle, _Palette> _palettes = {
  BlockStyle.grass: _Palette(Color(0xFF5DA83A), Color(0xFF8B5E3C), cap: Color(0xFF4F9430)),
  BlockStyle.dirt: _Palette(Color(0xFF9A6B45), Color(0xFF8B5E3C)),
  BlockStyle.stone: _Palette(Color(0xFF9A9A9A), Color(0xFF808080)),
  BlockStyle.sand: _Palette(Color(0xFFEBDC9F), Color(0xFFD9C583)),
  BlockStyle.snow: _Palette(Color(0xFFF6F9FF), Color(0xFF8B5E3C), cap: Color(0xFFE9F0FA)),
  BlockStyle.amethyst:
      _Palette(Color(0xFFBF8CFF), Color(0xFF8D55D8), sparkle: true),
  BlockStyle.netherrack: _Palette(Color(0xFF8E3434), Color(0xFF732828)),
  BlockStyle.endStone: _Palette(Color(0xFFE8E5AE), Color(0xFFD3CF93)),
  BlockStyle.planks: _Palette(Color(0xFFCFA86A), Color(0xFFB08950), bands: true),
};

/// Small isometric Minecraft-style cube drawn with a [CustomPainter].
class BlockIcon extends StatelessWidget {
  const BlockIcon({super.key, this.style = BlockStyle.grass, this.size = 40});

  final BlockStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BlockPainter(style)),
    );
  }
}

class _BlockPainter extends CustomPainter {
  _BlockPainter(this.style);

  final BlockStyle style;

  static const int _n = 4;

  static Color _mix(Color c, Color other, double t) => Color.lerp(c, other, t) ?? c;

  /// Cheap deterministic noise in 0..1.
  static double _noise(int a, int b, int c) {
    var h = a * 73856093 ^ b * 19349663 ^ c * 83492791;
    h = (h ^ (h >> 13)) & 0x7fffffff;
    return (h % 1000) / 1000.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pal = _palettes[style]!;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final top = Offset(cx, h * 0.06);
    final right = Offset(w * 0.94, h * 0.28);
    final mid = Offset(cx, h * 0.50);
    final left = Offset(w * 0.06, h * 0.28);
    final botL = Offset(w * 0.06, h * 0.72);
    final botM = Offset(cx, h * 0.94);
    final botR = Offset(w * 0.94, h * 0.72);

    // Soft ground shadow.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.88, w * 0.76, h * 0.1),
      Paint()..color = const Color(0x55000000),
    );

    final sideLeft = _mix(pal.side, Colors.black, 0.18);
    final sideRight = _mix(pal.side, Colors.black, 0.36);

    _face(canvas, top, right - top, left - top, pal.top, pal, 1, isTop: true);
    _face(canvas, left, mid - left, botL - left, sideLeft, pal, 2);
    _face(canvas, mid, right - mid, botM - mid, sideRight, pal, 3);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w / 40).clamp(0.6, 1.4)
      ..color = const Color(0x66000000);
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(botR.dx, botR.dy)
        ..lineTo(botM.dx, botM.dy)
        ..lineTo(botL.dx, botL.dy)
        ..lineTo(left.dx, left.dy)
        ..close(),
      edge,
    );
    canvas.drawLine(mid, top + (mid - top), edge);
    canvas.drawLine(left, mid, edge);
    canvas.drawLine(mid, right, edge);
    canvas.drawLine(mid, botM, edge);
  }

  /// Paints a parallelogram face: origin [o], edge vectors [u] (columns) and
  /// [v] (rows), as an [_n] x [_n] grid of slightly varied "pixels".
  void _face(
    Canvas canvas,
    Offset o,
    Offset u,
    Offset v,
    Color base,
    _Palette pal,
    int seed, {
    bool isTop = false,
  }) {
    Path quad(int i, int j) {
      final p0 = o + u * (i / _n) + v * (j / _n);
      return Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo((p0 + u / _n.toDouble()).dx, (p0 + u / _n.toDouble()).dy)
        ..lineTo((p0 + u / _n.toDouble() + v / _n.toDouble()).dx,
            (p0 + u / _n.toDouble() + v / _n.toDouble()).dy)
        ..lineTo((p0 + v / _n.toDouble()).dx, (p0 + v / _n.toDouble()).dy)
        ..close();
    }

    final whole = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo((o + u).dx, (o + u).dy)
      ..lineTo((o + u + v).dx, (o + u + v).dy)
      ..lineTo((o + v).dx, (o + v).dy)
      ..close();
    canvas.drawPath(whole, Paint()..color = base);

    final cell = Paint()..isAntiAlias = true;
    for (var j = 0; j < _n; j++) {
      for (var i = 0; i < _n; i++) {
        final r = _noise(i + 1, j + 1, seed + style.index * 7);
        Color? fill;
        if (!isTop && pal.cap != null && (j == 0 || (j == 1 && r > 0.5))) {
          fill = _mix(pal.cap!, Colors.black, seed == 3 ? 0.3 : 0.12);
          if (style == BlockStyle.snow) {
            fill = _mix(pal.cap!, Colors.black, seed == 3 ? 0.22 : 0.08);
          }
        } else if (pal.bands) {
          if (j.isOdd) fill = _mix(base, Colors.black, 0.12);
          if (r > 0.82) fill = _mix(base, Colors.white, 0.12);
        } else if (pal.sparkle && r > 0.7) {
          fill = _mix(base, Colors.white, 0.45);
        } else if (r < 0.28) {
          fill = _mix(base, Colors.black, 0.12);
        } else if (r > 0.8) {
          fill = _mix(base, Colors.white, 0.1);
        }
        if (fill == null) continue;
        cell.color = fill;
        canvas.drawPath(quad(i, j), cell);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlockPainter oldDelegate) => oldDelegate.style != style;
}
