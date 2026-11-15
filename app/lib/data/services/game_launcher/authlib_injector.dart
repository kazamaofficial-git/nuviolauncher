import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'game_launcher.dart';

/// Downloads and verifies authlib-injector (needed for Nuvio accounts).
class AuthlibInjector {
  AuthlibInjector({
    required http.Client client,
    this.metadataUrl = defaultMetadataUrl,
  }) : _client = client;

  static const String defaultMetadataUrl =
      'https://authlib-injector.yushi.moe/artifact/latest.json';

  final http.Client _client;
  final String metadataUrl;

  /// Returns the verified jar inside [dir], downloading it when needed.
  /// Falls back to an already-downloaded jar when offline.
  Future<File> ensure(Directory dir) async {
    await dir.create(recursive: true);
    final Map<String, dynamic> meta;
    try {
      final res = await _client.get(Uri.parse(metadataUrl)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw const FormatException('bad status');
      meta = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      final cached = await _cachedJar(dir);
      if (cached != null) return cached;
      throw const LaunchException(
        'Could not download authlib-injector (needed for Nuvio accounts). Check your connection.',
      );
    }

    final url = meta['download_url'];
    final checksums = meta['checksums'];
    final sha = checksums is Map ? checksums['sha256'] : null;
    if (url is! String || sha is! String) {
      throw const LaunchException('authlib-injector metadata is invalid.');
    }
    final version = (meta['version'] ?? meta['build_number'] ?? 'latest')
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File(p.join(dir.path, 'authlib-injector-$version.jar'));
    final expected = sha.toLowerCase();

    if (await file.exists() && await _sha256(file) == expected) return file;

    final http.Response res;
    try {
      res = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    } catch (_) {
      final cached = await _cachedJar(dir);
      if (cached != null) return cached;
      throw const LaunchException('Could not download authlib-injector.');
    }
    if (res.statusCode != 200 || sha256.convert(res.bodyBytes).toString() != expected) {
      throw const LaunchException('authlib-injector download failed its checksum verification.');
    }
    final part = File('${file.path}.part');
    await part.writeAsBytes(res.bodyBytes, flush: true);
    if (await file.exists()) await file.delete();
    await part.rename(file.path);
    return file;
  }

  Future<String> _sha256(File f) async =>
      (await sha256.bind(f.openRead()).first).toString();

  Future<File?> _cachedJar(Directory dir) async {
    final jars = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.jar'))
        .cast<File>()
        .toList();
    if (jars.isEmpty) return null;
    jars.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return jars.first;
  }
}
