import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/async_pool.dart';
import '../../../core/utils/shell_split.dart';
import '../../models/instance.dart';
import '../../models/rule_environment.dart';
import '../../models/version_detail.dart';
import 'authlib_injector.dart';
import 'downloader.dart';
import 'game_launcher.dart';
import 'java_locator.dart';
import 'launch_args.dart';

/// Real launch pipeline for desktop: downloads everything a vanilla version
/// needs (client, libraries, assets), extracts natives, builds the command
/// line and starts Java with the selected account's credentials.
class DesktopGameLauncher implements GameLauncher {
  DesktopGameLauncher({required String launcherVersion, http.Client? client})
      : this._(launcherVersion, client ?? http.Client());

  DesktopGameLauncher._(this.launcherVersion, http.Client client)
      : _client = client,
        _downloader = Downloader(client);

  final String launcherVersion;
  final http.Client _client;
  final Downloader _downloader;

  Process? _process;
  bool _cancelRequested = false;

  @override
  bool get isSupported => true;

  @override
  Stream<LaunchEvent> launch(LaunchRequest request) {
    final controller = StreamController<LaunchEvent>();
    _cancelRequested = false;
    unawaited(() async {
      try {
        await _run(request, controller.add);
      } on LaunchException catch (e) {
        controller.add(LaunchEvent.failed(e.message));
      } catch (e) {
        controller.add(LaunchEvent.failed('Unexpected error: $e'));
      } finally {
        _process = null;
        await controller.close();
      }
    }());
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _cancelRequested = true;
    _process?.kill();
  }

  void _checkCancelled() {
    if (_cancelRequested) throw const LaunchException('Launch cancelled.');
  }

  Future<void> _run(LaunchRequest req, void Function(LaunchEvent) emit) async {
    final instance = req.instance;
    if (instance.loader != LoaderType.vanilla) {
      throw LaunchException(
        '${instance.loader.label} support is coming soon. Use a Vanilla instance for now.',
      );
    }

    emit(LaunchEvent.status(LaunchPhase.preparing, 'Looking for Java...'));
    final java = await JavaLocator.find(configured: req.javaPath);
    if (java == null) {
      throw const LaunchException(
        'Java was not found. Install a JDK/JRE or set the Java path in Settings.',
      );
    }

    final env = RuleEnvironment.current();
    final root = req.gameRoot;
    final versionId = req.version.id;
    final versionDir = Directory(p.join(root, 'versions', versionId));
    await versionDir.create(recursive: true);

    // 1. Version metadata.
    emit(LaunchEvent.status(LaunchPhase.preparing, 'Fetching version metadata...'));
    final jsonFile = File(p.join(versionDir.path, '$versionId.json'));
    await _downloader.ensure(DownloadTask(
      url: req.version.url,
      dest: jsonFile,
      sha1: req.version.sha1,
    ));
    final detail = VersionDetail.fromJson(
      jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>,
    );
    if (detail.inheritsFrom != null) {
      throw const LaunchException('Modded version profiles are not supported yet.');
    }
    _checkCancelled();

    // 2. Java compatibility.
    final major = await JavaLocator.detectMajor(java);
    if (major != null && major < detail.javaMajor) {
      throw LaunchException(
        'Minecraft $versionId needs Java ${detail.javaMajor} or newer, but Java $major was found.',
      );
    }

    // 3. Plan downloads.
    final tasks = <String, DownloadTask>{};
    void add(DownloadTask t) => tasks[t.dest.path] = t;

    final clientRef = detail.clientDownload;
    if (clientRef == null) {
      throw const LaunchException('This version has no client download.');
    }
    final clientJar = File(p.join(versionDir.path, '$versionId.jar'));
    add(DownloadTask(
      url: clientRef.url,
      dest: clientJar,
      sha1: clientRef.sha1,
      size: clientRef.size,
    ));

    final classpath = <String>[];
    final nativeJars = <_NativeJar>[];
    for (final lib in detail.libraries.where((l) => l.isAllowed(env))) {
      final art = lib.artifact;
      if (art != null && art.url.isNotEmpty) {
        final file = File(p.join(root, 'libraries', art.path));
        add(DownloadTask(url: art.url, dest: file, sha1: art.sha1, size: art.size));
        classpath.add(file.path);
        if (lib.isNativeArtifact) nativeJars.add(_NativeJar(file, lib.extractExclude));
      }
      final nat = lib.nativeClassifierRef(env);
      if (nat != null && nat.url.isNotEmpty) {
        final file = File(p.join(root, 'libraries', nat.path));
        add(DownloadTask(url: nat.url, dest: file, sha1: nat.sha1, size: nat.size));
        nativeJars.add(_NativeJar(file, lib.extractExclude));
      }
    }
    classpath.add(clientJar.path);

    // 4. Asset index.
    emit(LaunchEvent.status(LaunchPhase.preparing, 'Fetching asset index...'));
    final assetsDir = p.join(root, 'assets');
    final indexFile = File(p.join(assetsDir, 'indexes', '${detail.assetIndex.id}.json'));
    await _downloader.ensure(DownloadTask(
      url: detail.assetIndex.url,
      dest: indexFile,
      sha1: detail.assetIndex.sha1,
      size: detail.assetIndex.size,
    ));
    final index = jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final objects = (index['objects'] as Map<String, dynamic>? ?? const {});
    final objectFiles = <String, File>{}; // asset name -> object file
    objects.forEach((name, value) {
      final obj = value as Map<String, dynamic>;
      final hash = obj['hash'] as String;
      final file = File(p.join(assetsDir, 'objects', hash.substring(0, 2), hash));
      objectFiles[name] = file;
      add(DownloadTask(
        url: '${AppConstants.resourcesBase}/${hash.substring(0, 2)}/$hash',
        dest: file,
        sha1: hash,
        size: (obj['size'] as num?)?.toInt(),
      ));
    });

    // 5. Download everything (bounded concurrency).
    final total = tasks.length;
    var done = 0;
    emit(LaunchEvent.status(LaunchPhase.downloading, 'Checking $total files...', progress: 0));
    await runPool(tasks.values, req.downloadThreads, (task) async {
      _checkCancelled();
      await _downloader.ensure(task);
      done++;
      if (done % 8 == 0 || done == total) {
        emit(LaunchEvent.status(
          LaunchPhase.downloading,
          'Downloading files ($done / $total)',
          progress: done / total,
        ));
      }
    });

    // 6. Natives (old-style classifier jars and new-style native artifacts).
    final nativesDir = Directory(p.join(versionDir.path, 'natives'));
    if (await nativesDir.exists()) await nativesDir.delete(recursive: true);
    await nativesDir.create(recursive: true);
    for (final jar in nativeJars) {
      await _extractNatives(jar, nativesDir);
    }

    // 7. Legacy / virtual assets.
    var gameAssets = assetsDir;
    final instanceDir = Directory(p.join(root, 'instances', instance.id));
    await instanceDir.create(recursive: true);
    if (index['virtual'] == true) {
      gameAssets = p.join(assetsDir, 'virtual', 'legacy');
      await _mirrorAssets(objectFiles, gameAssets);
    }
    if (index['map_to_resources'] == true) {
      await _mirrorAssets(objectFiles, p.join(instanceDir.path, 'resources'));
    }
    _checkCancelled();

    // 8. Command line.
    final separator = Platform.isWindows ? ';' : ':';
    final auth = req.auth;
    final authJvm = <String>[];
    final yggdrasil = auth.yggdrasilRoot;
    if (yggdrasil != null) {
      // Nuvio account: authlib-injector must come before the classpath args.
      var agentPath = auth.authlibInjectorPath;
      if (agentPath == null) {
        emit(LaunchEvent.status(LaunchPhase.preparing, 'Preparing authlib-injector...'));
        final jar = await AuthlibInjector(client: _client)
            .ensure(Directory(p.join(root, 'authlib-injector')));
        agentPath = jar.path;
      }
      authJvm.add('-javaagent:$agentPath=$yggdrasil');
    }
    authJvm.addAll(auth.extraJvmArgs);
    _checkCancelled();
    final vars = <String, String>{
      'auth_player_name': auth.username,
      'version_name': versionId,
      'game_directory': instanceDir.path,
      'assets_root': assetsDir,
      'assets_index_name': detail.assetIndex.id,
      'game_assets': gameAssets,
      'auth_uuid': auth.uuid,
      'auth_access_token': auth.accessToken,
      'auth_session': auth.accessToken,
      'auth_xuid': '',
      'clientid': '',
      'user_type': auth.userType,
      'user_properties': '{}',
      'version_type': detail.type,
      'launcher_name': 'NuvioLauncher',
      'launcher_version': launcherVersion,
      'natives_directory': nativesDir.path,
      'library_directory': p.join(root, 'libraries'),
      'classpath_separator': separator,
      'primary_jar': clientJar.path,
      'classpath': classpath.join(separator),
    };

    final ram = instance.ramMb;
    final args = LaunchArgsBuilder.build(
      detail: detail,
      env: env,
      vars: vars,
      extraJvmArgs: [
        ...authJvm,
        '-Xms${ram ~/ 2}M',
        '-Xmx${ram}M',
        '-Dlog4j2.formatMsgNoLookups=true',
        ...splitArguments(instance.jvmArgs),
      ],
    );

    // 9. Launch.
    emit(LaunchEvent.status(LaunchPhase.launching, 'Starting Minecraft $versionId...'));
    final process = await Process.start(java, args, workingDirectory: instanceDir.path);
    _process = process;
    emit(LaunchEvent.status(LaunchPhase.running, 'Minecraft is running'));

    const decoder = Utf8Decoder(allowMalformed: true);
    final outDone = process.stdout
        .transform(decoder)
        .transform(const LineSplitter())
        .forEach((line) => emit(LaunchEvent.log(line)));
    final errDone = process.stderr
        .transform(decoder)
        .transform(const LineSplitter())
        .forEach((line) => emit(LaunchEvent.log(line)));
    final code = await process.exitCode;
    await Future.wait([outDone, errDone]);
    emit(LaunchEvent.finished(code));
  }

  Future<void> _extractNatives(_NativeJar jar, Directory target) async {
    final archive = ZipDecoder().decodeBytes(await jar.file.readAsBytes());
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name;
      if (name.startsWith('META-INF')) continue;
      if (jar.exclude.any((e) => name.startsWith(e))) continue;
      final lower = name.toLowerCase();
      final isNative = lower.endsWith('.dll') ||
          lower.endsWith('.so') ||
          lower.endsWith('.dylib') ||
          lower.endsWith('.jnilib');
      if (!isNative) continue;
      final out = File(p.join(target.path, p.basename(name)));
      await out.writeAsBytes(entry.content as List<int>);
    }
  }

  Future<void> _mirrorAssets(Map<String, File> objectFiles, String targetRoot) async {
    for (final entry in objectFiles.entries) {
      final dest = File(p.join(targetRoot, entry.key));
      if (await dest.exists()) continue;
      await dest.parent.create(recursive: true);
      await entry.value.copy(dest.path);
    }
  }
}

class _NativeJar {
  const _NativeJar(this.file, this.exclude);

  final File file;
  final List<String> exclude;
}
