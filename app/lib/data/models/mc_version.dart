/// Category used by the version filter chips.
enum VersionFilter { release, snapshot, old }

/// One entry of Mojang's version manifest.
class McVersion {
  const McVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.releaseTime,
    this.sha1,
  });

  final String id;

  /// Raw manifest type: release, snapshot, old_beta, old_alpha.
  final String type;
  final String url;
  final DateTime? releaseTime;
  final String? sha1;

  VersionFilter get filter {
    switch (type) {
      case 'release':
        return VersionFilter.release;
      case 'snapshot':
        return VersionFilter.snapshot;
      default:
        return VersionFilter.old;
    }
  }

  bool get isRelease => type == 'release';

  factory McVersion.fromJson(Map<String, dynamic> json) => McVersion(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'release',
        url: json['url'] as String,
        releaseTime: DateTime.tryParse(json['releaseTime'] as String? ?? ''),
        sha1: json['sha1'] as String?,
      );
}
