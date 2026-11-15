/// A downloadable build for one platform.
class ReleaseAsset {
  const ReleaseAsset({required this.label, required this.size, required this.url});

  final String label;
  final int? size;

  /// Relative API path such as `/api/download/windows`.
  final String url;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
        label: json['label'] as String? ?? '',
        size: (json['size'] as num?)?.toInt(),
        url: json['url'] as String? ?? '',
      );
}

/// Latest release metadata from `/api/releases/latest`.
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.prerelease,
    required this.publishedAt,
    required this.notes,
    required this.platforms,
  });

  final String version;
  final bool prerelease;
  final DateTime? publishedAt;
  final String notes;
  final Map<String, ReleaseAsset> platforms;

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final raw = json['platforms'];
    final platforms = <String, ReleaseAsset>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          platforms[key.toString()] = ReleaseAsset.fromJson(value);
        }
      });
    }
    return ReleaseInfo(
      version: json['version'] as String? ?? '0.0.0',
      prerelease: json['prerelease'] as bool? ?? false,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      notes: json['notes'] as String? ?? '',
      platforms: platforms,
    );
  }
}
