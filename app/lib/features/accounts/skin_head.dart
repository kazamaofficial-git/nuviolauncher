import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_colors.dart';
import '../../core/utils/color_ext.dart';

/// Loads and caches skin PNGs as decoded images.
abstract final class SkinImageCache {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(String url) {
    final future = _cache.putIfAbsent(url, () => _fetch(url));
    future.then((img) {
      if (img == null) _cache.remove(url);
    });
    return future;
  }

  static Future<ui.Image?> _fetch(String url) async {
    try {
      // Mojang still reports plain-http texture URLs; upgrade them.
      final safe = url.startsWith('http://textures.minecraft.net')
          ? url.replaceFirst('http://', 'https://')
          : url;
      final res = await http.get(Uri.parse(safe)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(res.bodyBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}

/// Player head cropped from a 64x64 (or 64x32) skin: face plus hat layer.
class SkinHead extends StatelessWidget {
  const SkinHead({super.key, required this.url, this.size = 48});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = url;
    final placeholder = _Placeholder(size: size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: SizedBox(
        width: size,
        height: size,
        child: (u == null || u.isEmpty)
            ? placeholder
            : FutureBuilder<ui.Image?>(
                future: SkinImageCache.load(u),
                builder: (context, snap) {
                  final image = snap.data;
                  if (image == null) return placeholder;
                  return CustomPaint(painter: _HeadPainter(image));
                },
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(Icons.view_in_ar_rounded, size: size * 0.55, color: AppColors.lavender.fade(0.8)),
    );
  }
}

class _HeadPainter extends CustomPainter {
  _HeadPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final dst = Offset.zero & size;
    canvas.drawImageRect(image, Rect.fromLTWH(8, 8, 8, 8), dst, paint);
    if (image.width >= 48 && image.height >= 16) {
      canvas.drawImageRect(image, Rect.fromLTWH(40, 8, 8, 8), dst, paint);
    }
  }

  @override
  bool shouldRepaint(_HeadPainter oldDelegate) => oldDelegate.image != image;
}
