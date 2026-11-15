import 'dart:io';

import 'package:path/path.dart' as p;

import '../../models/content/content_models.dart';

/// A file found in one of an instance's content folders.
class InstalledFile {
  const InstalledFile({
    required this.category,
    required this.path,
    required this.size,
    required this.modified,
  });

  final ContentCategory category;
  final String path;
  final int size;
  final DateTime modified;

  String get name => p.basename(path);
}

/// Lists and deletes installed mods, shaders and resource packs.
abstract final class InstalledContentService {
  static const List<ContentCategory> categories = [
    ContentCategory.mod,
    ContentCategory.shader,
    ContentCategory.resourcePack,
  ];

  static Future<List<InstalledFile>> list(Directory instanceDir) async {
    final out = <InstalledFile>[];
    for (final category in categories) {
      final dir = Directory(p.join(instanceDir.path, category.installFolder!));
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || entity.path.endsWith('.part')) continue;
        final stat = await entity.stat();
        out.add(InstalledFile(
          category: category,
          path: entity.path,
          size: stat.size,
          modified: stat.modified,
        ));
      }
    }
    out.sort((a, b) {
      final c = a.category.index.compareTo(b.category.index);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  static Future<void> delete(InstalledFile file) async {
    final f = File(file.path);
    if (await f.exists()) await f.delete();
  }
}
