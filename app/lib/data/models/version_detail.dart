import '../../core/constants/app_constants.dart';
import 'rule_environment.dart';

/// A downloadable file with optional checksum.
class DownloadRef {
  const DownloadRef({required this.url, required this.path, this.sha1, this.size});

  final String url;
  final String path;
  final String? sha1;
  final int? size;

  factory DownloadRef.fromJson(Map<String, dynamic> json, {String? fallbackPath}) =>
      DownloadRef(
        url: json['url'] as String? ?? '',
        path: json['path'] as String? ?? fallbackPath ?? '',
        sha1: json['sha1'] as String?,
        size: (json['size'] as num?)?.toInt(),
      );
}

/// Reference to the asset index of a version.
class AssetIndexRef {
  const AssetIndexRef({required this.id, required this.url, this.sha1, this.size});

  final String id;
  final String url;
  final String? sha1;
  final int? size;

  factory AssetIndexRef.fromJson(Map<String, dynamic> json) => AssetIndexRef(
        id: json['id'] as String,
        url: json['url'] as String,
        sha1: json['sha1'] as String?,
        size: (json['size'] as num?)?.toInt(),
      );
}

/// Builds a Maven repository relative path from `group:artifact:version[:classifier]`.
String mavenPath(String name, {String? classifier}) {
  final parts = name.split(':');
  if (parts.length < 3) return name;
  final group = parts[0].replaceAll('.', '/');
  final artifact = parts[1];
  final version = parts[2];
  final cls = classifier ?? (parts.length > 3 ? parts[3] : null);
  final file = cls == null ? '$artifact-$version.jar' : '$artifact-$version-$cls.jar';
  return '$group/$artifact/$version/$file';
}

/// One entry of a version's `libraries` array.
class LibraryEntry {
  const LibraryEntry({
    required this.name,
    required this.artifact,
    required this.classifiers,
    required this.natives,
    required this.rules,
    required this.extractExclude,
  });

  final String name;
  final DownloadRef? artifact;
  final Map<String, DownloadRef> classifiers;

  /// Old-style natives map, e.g. `{windows: natives-windows}`.
  final Map<String, String> natives;
  final List<dynamic>? rules;
  final List<String> extractExclude;

  bool isAllowed(RuleEnvironment env) => rulesAllow(rules, env);

  /// New-style (1.19+) libraries whose Maven classifier starts with `natives`.
  bool get isNativeArtifact {
    final parts = name.split(':');
    return parts.length >= 4 && parts[3].startsWith('natives');
  }

  /// Old-style natives jar for the current OS, if this library has one.
  DownloadRef? nativeClassifierRef(RuleEnvironment env) {
    final key = natives[env.osName];
    if (key == null) return null;
    return classifiers[key.replaceAll(r'${arch}', env.bits)];
  }

  factory LibraryEntry.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final downloads = json['downloads'] as Map<String, dynamic>?;
    final nativesRaw = json['natives'];
    final natives = <String, String>{};
    if (nativesRaw is Map) {
      nativesRaw.forEach((k, v) => natives[k.toString()] = v.toString());
    }

    DownloadRef? artifact;
    final classifiers = <String, DownloadRef>{};
    final baseUrl = json['url'] as String? ?? AppConstants.librariesBase;

    if (downloads != null) {
      final art = downloads['artifact'];
      if (art is Map<String, dynamic>) {
        artifact = DownloadRef.fromJson(art, fallbackPath: mavenPath(name));
      }
      final cls = downloads['classifiers'];
      if (cls is Map) {
        cls.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            classifiers[k.toString()] = DownloadRef.fromJson(v);
          }
        });
      }
    } else {
      // Legacy format without a `downloads` block: derive from Maven coordinates.
      if (natives.isEmpty) {
        final path = mavenPath(name);
        artifact = DownloadRef(url: '$baseUrl$path', path: path);
      } else {
        for (final classifier in natives.values) {
          final resolved = classifier.replaceAll(r'${arch}', '64');
          final path = mavenPath(name, classifier: resolved);
          classifiers[classifier] = DownloadRef(url: '$baseUrl$path', path: path);
        }
      }
    }

    final extract = json['extract'];
    final exclude = <String>[];
    if (extract is Map && extract['exclude'] is List) {
      exclude.addAll((extract['exclude'] as List).map((e) => e.toString()));
    }

    return LibraryEntry(
      name: name,
      artifact: artifact,
      classifiers: classifiers,
      natives: natives,
      rules: json['rules'] as List<dynamic>?,
      extractExclude: exclude,
    );
  }
}

/// A JVM or game argument, optionally guarded by rules.
class ArgumentEntry {
  const ArgumentEntry({required this.values, this.rules});

  final List<String> values;
  final List<dynamic>? rules;

  static List<ArgumentEntry> parseList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <ArgumentEntry>[];
    for (final item in raw) {
      if (item is String) {
        out.add(ArgumentEntry(values: [item]));
      } else if (item is Map) {
        final value = item['value'];
        final values = value is List
            ? value.map((e) => e.toString()).toList()
            : <String>[value.toString()];
        out.add(ArgumentEntry(values: values, rules: item['rules'] as List<dynamic>?));
      }
    }
    return out;
  }
}

/// Parsed per-version JSON (`versions/<id>/<id>.json`).
class VersionDetail {
  const VersionDetail({
    required this.id,
    required this.type,
    required this.mainClass,
    required this.assetIndex,
    required this.clientDownload,
    required this.libraries,
    required this.gameArgs,
    required this.jvmArgs,
    required this.legacyGameArgs,
    required this.javaMajor,
    required this.inheritsFrom,
  });

  final String id;
  final String type;
  final String mainClass;
  final AssetIndexRef assetIndex;
  final DownloadRef? clientDownload;
  final List<LibraryEntry> libraries;
  final List<ArgumentEntry> gameArgs;
  final List<ArgumentEntry> jvmArgs;

  /// Pre-1.13 `minecraftArguments` string, if present.
  final String? legacyGameArgs;
  final int javaMajor;
  final String? inheritsFrom;

  factory VersionDetail.fromJson(Map<String, dynamic> json) {
    final assetIndex = json['assetIndex'];
    if (assetIndex is! Map<String, dynamic>) {
      throw const FormatException('Version JSON has no assetIndex');
    }
    final downloads = json['downloads'] as Map<String, dynamic>?;
    final client = downloads?['client'];
    final args = json['arguments'] as Map<String, dynamic>?;
    final javaVersion = json['javaVersion'];

    return VersionDetail(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'release',
      mainClass: json['mainClass'] as String,
      assetIndex: AssetIndexRef.fromJson(assetIndex),
      clientDownload: client is Map<String, dynamic>
          ? DownloadRef.fromJson(client, fallbackPath: '${json['id']}.jar')
          : null,
      libraries: (json['libraries'] as List<dynamic>? ?? const [])
          .map((e) => LibraryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      gameArgs: ArgumentEntry.parseList(args?['game']),
      jvmArgs: ArgumentEntry.parseList(args?['jvm']),
      legacyGameArgs: json['minecraftArguments'] as String?,
      javaMajor: javaVersion is Map ? (javaVersion['majorVersion'] as num?)?.toInt() ?? 8 : 8,
      inheritsFrom: json['inheritsFrom'] as String?,
    );
  }
}
