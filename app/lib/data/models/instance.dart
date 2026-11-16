/// Mod loader a game instance is configured for.
/// All loaders are resolved to their newest stable version when the instance launches.
enum LoaderType {
  vanilla('Vanilla', true),
  fabric('Fabric', true),
  forge('Forge', true),
  neoforge('NeoForge', true),
  quilt('Quilt', true);

  const LoaderType(this.label, this.isSupported);

  final String label;
  final bool isSupported;

  static LoaderType parse(String? value) => LoaderType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LoaderType.vanilla,
      );
}

/// A configured game profile (version + settings).
class Instance {
  const Instance({
    required this.id,
    required this.name,
    required this.versionId,
    required this.loader,
    required this.renderer,
    required this.ramMb,
    required this.jvmArgs,
    required this.createdAt,
    this.lastPlayed,
    this.loaderVersion,
  });

  final String id;
  final String name;
  final String versionId;
  final LoaderType loader;
  final String renderer;
  final int ramMb;
  final String jvmArgs;
  final DateTime createdAt;
  final DateTime? lastPlayed;

  /// Pinned loader version (e.g. from a modpack); null = newest stable.
  final String? loaderVersion;

  Instance copyWith({
    String? name,
    String? versionId,
    LoaderType? loader,
    String? renderer,
    int? ramMb,
    String? jvmArgs,
    DateTime? lastPlayed,
    String? loaderVersion,
  }) =>
      Instance(
        id: id,
        name: name ?? this.name,
        versionId: versionId ?? this.versionId,
        loader: loader ?? this.loader,
        renderer: renderer ?? this.renderer,
        ramMb: ramMb ?? this.ramMb,
        jvmArgs: jvmArgs ?? this.jvmArgs,
        createdAt: createdAt,
        lastPlayed: lastPlayed ?? this.lastPlayed,
        loaderVersion: loaderVersion ?? this.loaderVersion,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'versionId': versionId,
        'loader': loader.name,
        'renderer': renderer,
        'ramMb': ramMb,
        'jvmArgs': jvmArgs,
        'createdAt': createdAt.toIso8601String(),
        'lastPlayed': lastPlayed?.toIso8601String(),
        'loaderVersion': loaderVersion,
      };

  factory Instance.fromJson(Map<String, dynamic> json) => Instance(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Instance',
        versionId: json['versionId'] as String,
        loader: LoaderType.parse(json['loader'] as String?),
        renderer: json['renderer'] as String? ?? 'Auto',
        ramMb: (json['ramMb'] as num?)?.toInt() ?? 2048,
        jvmArgs: json['jvmArgs'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? ''),
        loaderVersion: json['loaderVersion'] as String?,
      );
}
