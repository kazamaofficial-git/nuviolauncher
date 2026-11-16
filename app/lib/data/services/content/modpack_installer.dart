import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/utils/async_pool.dart';
import '../../models/content/content_models.dart';
import '../../models/instance.dart';
import '../game_launcher/downloader.dart';
import 'content_config.dart';

/// One file a modpack wants inside the instance.
class PackFile {
  const PackFile({required this.path, required this.urls, this.sha1});

  /// Path relative to the instance directory.
  final String path;
  final List<String> urls;
  final String? sha1;
}

/// What a modpack archive describes.
class ModpackPlan {
  const ModpackPlan({
    required this.name,
    required this.mcVersion,
    required this.loader,
    required this.loaderVersion,
    required this.files,
    required this.overrideDirs,
  });

  final String name;
  final String mcVersion;
  final LoaderType loader;
  final String? loaderVersion;
  final List<PackFile> files;

  /// Archive folders copied over the instance (`overrides`, `client-overrides`).
  final List<String> overrideDirs;
}

/// Reads Modrinth (`.mrpack`) and CurseForge (`manifest.json`) modpacks and installs their files.
class ModpackInstaller {
  ModpackInstaller({required http.Client client, required String appVersion})
      : _client = client,
        _downloader = Downloader(client),
        _appVersion = appVersion;

  final http.Client _client;
  final Downloader _downloader;
  final String _appVersion;

  /// Relative path made of safe segments only, or null when it could escape the instance folder.
  static List<String>? safeSegments(String path) {
    final parts = path.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty && s != '.').toList();
    if (parts.isEmpty || parts.any((s) => s == '..' || s.contains(':'))) return null;
    return parts;
  }

  // ── Parsing ────────────────────────────────────────────────

  /// Parses `modrinth.index.json`.
  static ModpackPlan parseModrinth(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as Map?)?.cast<String, dynamic>() ?? const {};
    final mc = deps['minecraft'] as String?;
    if (mc == null) throw const ContentException('The modpack does not name a Minecraft version.');
    var loader = LoaderType.vanilla;
    String? loaderVersion;
    const keys = {
      'fabric-loader': LoaderType.fabric,
      'quilt-loader': LoaderType.quilt,
      'forge': LoaderType.forge,
      'neoforge': LoaderType.neoforge,
    };
    keys.forEach((k, v) {
      if (deps[k] is String) {
        loader = v;
        loaderVersion = deps[k] as String;
      }
    });
    final files = <PackFile>[];
    for (final raw in (json['files'] as List? ?? const [])) {
      final f = (raw as Map).cast<String, dynamic>();
      final env = (f['env'] as Map?)?.cast<String, dynamic>();
      if (env != null && env['client'] == 'unsupported') continue;
      final path = f['path'] as String?;
      final urls = (f['downloads'] as List? ?? const []).whereType<String>().toList();
      if (path == null || urls.isEmpty) continue;
      files.add(PackFile(
        path: path,
        urls: urls,
        sha1: (f['hashes'] as Map?)?['sha1'] as String?,
      ));
    }
    return ModpackPlan(
      name: json['name'] as String? ?? 'Modpack',
      mcVersion: mc,
      loader: loader,
      loaderVersion: loaderVersion,
      files: files,
      overrideDirs: const ['overrides', 'client-overrides'],
    );
  }

  /// Parses a CurseForge `manifest.json` (file ids still need resolving to URLs).
  static ({String name, String mc, LoaderType loader, String? loaderVersion, List<({int project, int file})> files, String overrides})
      parseCurseForge(Map<String, dynamic> json) {
    final mcMap = (json['minecraft'] as Map?)?.cast<String, dynamic>() ?? const {};
    final mc = mcMap['version'] as String?;
    if (mc == null) throw const ContentException('The modpack does not name a Minecraft version.');
    var loader = LoaderType.vanilla;
    String? loaderVersion;
    final loaders = (mcMap['modLoaders'] as List? ?? const []).cast<Map>();
    final primary = loaders.firstWhere((l) => l['primary'] == true, orElse: () => loaders.isEmpty ? {} : loaders.first);
    final id = primary['id'] as String?;
    if (id != null) {
      final dash = id.indexOf('-');
      if (dash > 0) {
        final name = id.substring(0, dash).toLowerCase();
        loaderVersion = id.substring(dash + 1);
        loader = LoaderType.values.firstWhere(
          (l) => l.name == name,
          orElse: () => LoaderType.vanilla,
        );
        if (loader == LoaderType.vanilla) loaderVersion = null;
      }
    }
    final files = <({int project, int file})>[];
    for (final raw in (json['files'] as List? ?? const [])) {
      final f = (raw as Map).cast<String, dynamic>();
      if (f['required'] == false) continue;
      final pid = f['projectID'], fid = f['fileID'];
      if (pid is num && fid is num) files.add((project: pid.toInt(), file: fid.toInt()));
    }
    return (
      name: json['name'] as String? ?? 'Modpack',
      mc: mc,
      loader: loader,
      loaderVersion: loaderVersion,
      files: files,
      overrides: json['overrides'] as String? ?? 'overrides',
    );
  }

  // ── Installing ─────────────────────────────────────────────

  /// Downloads [packUrl] and reads its manifest. Nothing is written to an instance yet.
  Future<({ModpackPlan plan, File archive})> prepare({
    required String packUrl,
    required String? sha1,
    required Directory workDir,
    required ContentProviderId provider,
    required int threads,
    void Function(String message)? status,
  }) async {
    status?.call('Downloading modpack...');
    final archive = File(p.join(workDir.path, 'pack.zip'));
    try {
      await _downloader.download(packUrl, archive, expectedSha1: sha1);
    } catch (e) {
      throw ContentException('Could not download the modpack: $e');
    }
    final input = InputFileStream(archive.path);
    final Archive zip;
    try {
      zip = ZipDecoder().decodeBuffer(input);
    } catch (_) {
      throw const ContentException('The modpack is not a valid zip archive.');
    } finally {
      await input.close();
    }

    ArchiveFile? find(String name) {
      for (final f in zip.files) {
        if (f.isFile && f.name == name) return f;
      }
      return null;
    }

    final mr = find('modrinth.index.json');
    if (mr != null) {
      final json = jsonDecode(utf8.decode(mr.content as List<int>)) as Map<String, dynamic>;
      return (plan: parseModrinth(json), archive: archive);
    }
    final cf = find('manifest.json');
    if (cf != null) {
      final json = jsonDecode(utf8.decode(cf.content as List<int>)) as Map<String, dynamic>;
      final m = parseCurseForge(json);
      status?.call('Resolving ${m.files.length} CurseForge files...');
      final files = await _resolveCurseForge(m.files);
      return (
        plan: ModpackPlan(
          name: m.name,
          mcVersion: m.mc,
          loader: m.loader,
          loaderVersion: m.loaderVersion,
          files: files,
          overrideDirs: [m.overrides],
        ),
        archive: archive,
      );
    }
    throw const ContentException('Unsupported modpack: no modrinth.index.json or manifest.json found.');
  }

  Future<List<PackFile>> _resolveCurseForge(List<({int project, int file})> refs) async {
    if (!ContentConfig.curseForgeEnabled) {
      throw const ContentException('CurseForge modpacks need a CurseForge API key in this build.');
    }
    final out = <PackFile>[];
    for (var i = 0; i < refs.length; i += 100) {
      final chunk = refs.sublist(i, i + 100 > refs.length ? refs.length : i + 100);
      final res = await _client.post(
        Uri.https('api.curseforge.com', '/v1/mods/files'),
        headers: {
          'x-api-key': ContentConfig.curseForgeApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': ContentConfig.userAgent(_appVersion),
        },
        body: jsonEncode({'fileIds': [for (final r in chunk) r.file]}),
      );
      if (res.statusCode != 200) {
        throw ContentException('CurseForge answered HTTP ${res.statusCode} while resolving pack files.');
      }
      final data = ((jsonDecode(utf8.decode(res.bodyBytes)) as Map)['data'] as List).cast<Map>();
      for (final f in data) {
        final id = (f['id'] as num).toInt();
        final name = f['fileName'] as String? ?? '$id.jar';
        final url = f['downloadUrl'] as String? ??
            'https://edge.forgecdn.net/files/${id ~/ 1000}/${id % 1000}/$name';
        String? sha1;
        for (final h in (f['hashes'] as List? ?? const []).cast<Map>()) {
          if (h['algo'] == 1) sha1 = h['value'] as String?;
        }
        // CurseForge mixes mods, resource packs and shaders in one manifest; route by file type.
        final isZip = name.toLowerCase().endsWith('.zip');
        final folder = isZip ? 'resourcepacks' : 'mods';
        out.add(PackFile(path: '$folder/$name', urls: [url], sha1: sha1));
      }
    }
    return out;
  }

  /// Downloads the plan's files into [instanceDir] and applies the archive's overrides.
  Future<void> install({
    required ModpackPlan plan,
    required File archive,
    required Directory instanceDir,
    required int threads,
    void Function(int done, int total)? onProgress,
  }) async {
    await instanceDir.create(recursive: true);
    final total = plan.files.length;
    var done = 0;
    onProgress?.call(0, total);
    await runPool(plan.files, threads, (file) async {
      final segments = safeSegments(file.path);
      if (segments == null) throw ContentException('Unsafe path in modpack: ${file.path}');
      final dest = File(p.joinAll([instanceDir.path, ...segments]));
      if (!p.isWithin(instanceDir.path, dest.path)) {
        throw ContentException('Unsafe path in modpack: ${file.path}');
      }
      Object? last;
      var ok = false;
      for (final url in file.urls) {
        try {
          await _downloader.download(url, dest, expectedSha1: file.sha1);
          ok = true;
          break;
        } catch (e) {
          last = e;
        }
      }
      if (!ok) throw ContentException('Could not download ${file.path}: $last');
      done++;
      onProgress?.call(done, total);
    });

    // Overrides: configs, scripts, options... later folders win.
    final input = InputFileStream(archive.path);
    try {
      final zip = ZipDecoder().decodeBuffer(input);
      for (final dir in plan.overrideDirs) {
        final prefix = '$dir/';
        for (final entry in zip.files) {
          if (!entry.isFile || !entry.name.startsWith(prefix)) continue;
          final segments = safeSegments(entry.name.substring(prefix.length));
          if (segments == null) continue;
          final dest = File(p.joinAll([instanceDir.path, ...segments]));
          if (!p.isWithin(instanceDir.path, dest.path)) continue;
          await dest.parent.create(recursive: true);
          await dest.writeAsBytes(entry.content as List<int>);
        }
      }
    } finally {
      await input.close();
    }
  }
}
