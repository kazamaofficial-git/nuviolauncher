import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../models/content/content_models.dart';
import 'content_config.dart';
import 'hash_verifier.dart';

typedef InstallProgress = void Function(int received, int? total);

/// Downloads content into an instance folder, verifying hashes when known.
class ContentInstaller {
  ContentInstaller({required http.Client client, required String appVersion})
      : _client = client,
        _userAgent = ContentConfig.userAgent(appVersion);

  final http.Client _client;
  final String _userAgent;

  /// Folder a [category] installs into, or null when it cannot be installed yet.
  static String? targetPath(String instanceDir, ContentCategory category) {
    final folder = category.installFolder;
    return folder == null ? null : p.join(instanceDir, folder);
  }

  /// Strips directories and characters that are invalid in file names.
  static String sanitizeFileName(String name) {
    final base = p.basename(name.replaceAll('\\', '/'));
    final clean = base.replaceAll(RegExp(r'[<>:"|?*\x00-\x1f]'), '_').trim();
    if (clean.isEmpty || clean == '.' || clean == '..') return 'download.bin';
    return clean;
  }

  /// Downloads [file] and installs it. Returns the installed path
  /// (the file, or the `saves/` folder for worlds).
  Future<String> install({
    required Directory instanceDir,
    required ContentCategory category,
    required ContentFile file,
    String? pageUrl,
    InstallProgress? onProgress,
  }) async {
    final folder = targetPath(instanceDir.path, category);
    if (folder == null) {
      throw ContentException('${category.label} cannot be installed yet.');
    }
    final url = file.url;
    if (url == null || url.isEmpty) {
      throw ContentException(
        'The author disabled third-party downloads for this file.',
        openUrl: pageUrl,
      );
    }
    final dir = Directory(folder);
    await dir.create(recursive: true);
    final name = sanitizeFileName(file.filename);
    final part = File(p.join(folder, '$name.part'));

    try {
      await _download(url, part, onProgress);
      final mismatch =
          await HashVerifier.verifyFile(part, sha1: file.sha1, sha512: file.sha512);
      if (mismatch != null) {
        throw ContentException('$mismatch. The download was discarded.');
      }
      if (category == ContentCategory.world) {
        return await _extractWorld(part, dir, name);
      }
      final dest = File(p.join(folder, name));
      if (await dest.exists()) await dest.delete();
      await part.rename(dest.path);
      return dest.path;
    } finally {
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _download(String url, File part, InstallProgress? onProgress) async {
    final request = http.Request('GET', Uri.parse(url))
      ..headers['User-Agent'] = _userAgent;
    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ContentException('Download failed: $e');
    }
    if (response.statusCode != 200) {
      throw ContentException('Download failed (HTTP ${response.statusCode}).');
    }
    final total = response.contentLength;
    var received = 0;
    final sink = part.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } catch (e) {
      throw ContentException('Download interrupted: $e');
    } finally {
      await sink.close();
    }
  }

  /// Extracts a world zip into [savesDir]. Zips whose entries do not share a
  /// single top-level folder are placed in a folder named after the zip.
  Future<String> _extractWorld(File zip, Directory savesDir, String zipName) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    } catch (_) {
      throw const ContentException('The world archive is not a valid zip file.');
    }
    final entries = archive.files
        .where((f) => _safeSegments(f.name) != null)
        .toList(growable: false);
    if (entries.isEmpty) {
      throw const ContentException('The world archive is empty.');
    }
    final tops = <String>{
      for (final e in entries) _safeSegments(e.name)!.first,
    };
    final wrapper = tops.length == 1 &&
            entries.any((e) => _safeSegments(e.name)!.length > 1)
        ? null
        : p.withoutExtension(zipName);
    final base = wrapper == null ? savesDir.path : p.join(savesDir.path, wrapper);

    for (final entry in entries) {
      final segments = _safeSegments(entry.name)!;
      final out = p.joinAll([base, ...segments]);
      if (!p.isWithin(savesDir.path, out)) continue;
      if (entry.isFile) {
        final file = File(out);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content as List<int>);
      } else {
        await Directory(out).create(recursive: true);
      }
    }
    return wrapper == null ? p.join(savesDir.path, tops.first) : base;
  }

  /// Splits a zip entry name into safe path segments, or null if unsafe/empty.
  static List<String>? _safeSegments(String name) {
    final parts = name
        .replaceAll('\\', '/')
        .split('/')
        .where((s) => s.isNotEmpty && s != '.')
        .toList();
    if (parts.isEmpty) return null;
    if (parts.any((s) => s == '..' || s.contains(':'))) return null;
    return parts;
  }
}
