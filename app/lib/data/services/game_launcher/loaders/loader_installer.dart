import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../models/instance.dart';
import '../downloader.dart';
import '../game_launcher.dart';

/// Result of preparing a loader: the id and parsed JSON of the loader's version profile.
class LoaderProfile {
  const LoaderProfile({required this.id, required this.json});

  final String id;
  final Map<String, dynamic> json;
}

/// Resolves, installs and returns the version profile of a mod loader for a Minecraft version.
///
/// * Fabric / Quilt: the meta servers serve a ready-made profile JSON.
/// * Forge / NeoForge: the official installer is downloaded and run headless (`--installClient`).
class LoaderInstaller {
  LoaderInstaller({required http.Client client, required this.userAgent})
      : _client = client,
        _downloader = Downloader(client);

  final http.Client _client;
  final Downloader _downloader;
  final String userAgent;

  Future<LoaderProfile> prepare({
    required LoaderType loader,
    required String mcVersion,
    required String gameRoot,
    required String java,
    required void Function(String) report,
    void Function(String line)? log,
    String? loaderVersion,
  }) {
    switch (loader) {
      case LoaderType.fabric:
        return _metaProfile(
          'https://meta.fabricmc.net/v2/versions/loader',
          mcVersion, gameRoot, report, 'Fabric', loaderVersion,
        );
      case LoaderType.quilt:
        return _metaProfile(
          'https://meta.quiltmc.org/v3/versions/loader',
          mcVersion, gameRoot, report, 'Quilt', loaderVersion,
        );
      case LoaderType.forge:
        return _forge(mcVersion, gameRoot, java, report, log, loaderVersion);
      case LoaderType.neoforge:
        return _neoforge(mcVersion, gameRoot, java, report, log, loaderVersion);
      case LoaderType.vanilla:
        throw const LaunchException('Vanilla needs no loader.');
    }
  }

  Future<dynamic> _getJson(String url) async {
    final res = await _client
        .get(Uri.parse(url), headers: {'User-Agent': userAgent})
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw LaunchException('Request failed (HTTP ${res.statusCode}): $url');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // ── Fabric / Quilt ─────────────────────────────────────────

  Future<LoaderProfile> _metaProfile(
    String base,
    String mc,
    String root,
    void Function(String) report,
    String label,
    String? pinned,
  ) async {
    report('Looking up $label loader for $mc...');
    String loaderVersion;
    if (pinned != null && pinned.isNotEmpty) {
      loaderVersion = pinned;
    } else {
      final list = await _getJson('$base/$mc') as List;
      if (list.isEmpty) throw LaunchException('$label does not support Minecraft $mc yet.');
      final entries = list.cast<Map<String, dynamic>>();
      final pick = entries.firstWhere(
        (e) => (e['loader'] as Map)['stable'] == true,
        orElse: () => entries.first,
      );
      loaderVersion = (pick['loader'] as Map)['version'] as String;
    }
    final profile = await _getJson('$base/$mc/$loaderVersion/profile/json') as Map<String, dynamic>;
    final id = profile['id'] as String;
    final dir = Directory(p.join(root, 'versions', id));
    await dir.create(recursive: true);
    await File(p.join(dir.path, '$id.json')).writeAsString(jsonEncode(profile));
    return LoaderProfile(id: id, json: profile);
  }

  // ── Forge ──────────────────────────────────────────────────

  Future<LoaderProfile> _forge(
    String mc,
    String root,
    String java,
    void Function(String) report,
    void Function(String)? log,
    String? pinned,
  ) async {
    report('Looking up Forge for $mc...');
    String? version = pinned != null && pinned.isNotEmpty ? pinned : null;
    if (version == null) {
      final promos = (await _getJson(
        'https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json',
      ) as Map<String, dynamic>)['promos'] as Map<String, dynamic>;
      version = (promos['$mc-recommended'] ?? promos['$mc-latest']) as String?;
    }
    if (version == null) throw LaunchException('Forge does not support Minecraft $mc.');
    final full = '$mc-$version';
    final url = 'https://maven.minecraftforge.net/net/minecraftforge/forge/$full/forge-$full-installer.jar';
    return _runInstaller(
      root: root,
      java: java,
      installerUrl: url,
      installerName: 'forge-$full-installer.jar',
      matches: (dir) => dir.contains(version) && dir.toLowerCase().contains('forge'),
      label: 'Forge $version',
      report: report,
      log: log,
    );
  }

  // ── NeoForge ───────────────────────────────────────────────

  /// `1.21.1` -> `21.1.`, `1.21` -> `21.0.` (NeoForge's versioning since 1.20.2).
  static String? neoforgePrefix(String mc) {
    final parts = mc.split('.');
    if (parts.length < 2 || parts[0] != '1') return null;
    final minor = int.tryParse(parts[1]);
    if (minor == null) return null;
    final patch = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (minor < 20 || (minor == 20 && patch < 2)) return null;
    return '$minor.$patch.';
  }

  Future<LoaderProfile> _neoforge(
    String mc,
    String root,
    String java,
    void Function(String) report,
    void Function(String)? log,
    String? pinned,
  ) async {
    final prefix = neoforgePrefix(mc);
    if (prefix == null) {
      throw LaunchException('NeoForge supports Minecraft 1.20.2 and newer (selected: $mc).');
    }
    report('Looking up NeoForge for $mc...');
    String version;
    if (pinned != null && pinned.isNotEmpty) {
      version = pinned;
    } else {
      final data = await _getJson(
        'https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge',
      ) as Map<String, dynamic>;
      final all = (data['versions'] as List).cast<String>().where((v) => v.startsWith(prefix)).toList();
      if (all.isEmpty) throw LaunchException('NeoForge does not support Minecraft $mc yet.');
      version = all.lastWhere((v) => !v.contains('beta'), orElse: () => all.last);
    }
    final url = 'https://maven.neoforged.net/releases/net/neoforged/neoforge/$version/neoforge-$version-installer.jar';
    return _runInstaller(
      root: root,
      java: java,
      installerUrl: url,
      installerName: 'neoforge-$version-installer.jar',
      matches: (dir) => dir == 'neoforge-$version',
      label: 'NeoForge $version',
      report: report,
      log: log,
    );
  }

  // ── Installer runner ───────────────────────────────────────

  Future<LoaderProfile> _runInstaller({
    required String root,
    required String java,
    required String installerUrl,
    required String installerName,
    required bool Function(String dirName) matches,
    required String label,
    required void Function(String) report,
    void Function(String)? log,
  }) async {
    final versionsDir = Directory(p.join(root, 'versions'));
    await versionsDir.create(recursive: true);

    Future<String?> findInstalled() async {
      await for (final e in versionsDir.list()) {
        if (e is! Directory) continue;
        final name = p.basename(e.path);
        if (matches(name) && await File(p.join(e.path, '$name.json')).exists()) return name;
      }
      return null;
    }

    var id = await findInstalled();
    if (id == null) {
      report('Downloading $label installer...');
      final installer = File(p.join(root, 'installers', installerName));
      await _downloader.ensure(DownloadTask(url: installerUrl, dest: installer));

      // The installer insists on a launcher_profiles.json next to `versions/`.
      final profiles = File(p.join(root, 'launcher_profiles.json'));
      if (!await profiles.exists()) await profiles.writeAsString('{"profiles":{}}');

      report('Installing $label (this can take a few minutes)...');
      final process = await Process.start(
        java,
        ['-jar', installer.path, '--installClient', root],
        workingDirectory: root,
      );
      final lines = <String>[];
      void sink(String l) {
        lines.add(l);
        if (lines.length > 40) lines.removeAt(0);
        log?.call(l);
      }
      const dec = Utf8Decoder(allowMalformed: true);
      final a = process.stdout.transform(dec).transform(const LineSplitter()).forEach(sink);
      final b = process.stderr.transform(dec).transform(const LineSplitter()).forEach(sink);
      final code = await process.exitCode;
      await Future.wait([a, b]);
      if (code != 0) {
        throw LaunchException('$label installer failed (exit $code). ${lines.isEmpty ? '' : lines.last}');
      }
      id = await findInstalled();
      if (id == null) throw LaunchException('$label installed, but its version profile was not found.');
    }
    final json = jsonDecode(await File(p.join(versionsDir.path, id, '$id.json')).readAsString())
        as Map<String, dynamic>;
    return LoaderProfile(id: id, json: json);
  }
}
