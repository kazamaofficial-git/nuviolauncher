import '../../core/constants/app_constants.dart';

/// Licence details returned by the server.
class LicenseInfo {
  const LicenseInfo({
    required this.keyMasked,
    required this.plan,
    required this.features,
    required this.expiresAt,
    required this.maxDevices,
    required this.devicesUsed,
  });

  final String keyMasked;
  final String plan;
  final List<String> features;
  final DateTime? expiresAt;
  final int maxDevices;
  final int devicesUsed;

  Map<String, dynamic> toJson() => {
        'keyMasked': keyMasked,
        'plan': plan,
        'features': features,
        'expiresAt': expiresAt?.toIso8601String(),
        'maxDevices': maxDevices,
        'devicesUsed': devicesUsed,
      };

  factory LicenseInfo.fromJson(Map<String, dynamic> json) => LicenseInfo(
        keyMasked: json['keyMasked'] as String? ?? '',
        plan: json['plan'] as String? ?? 'plus',
        features: (json['features'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
        maxDevices: (json['maxDevices'] as num?)?.toInt() ?? 1,
        devicesUsed: (json['devicesUsed'] as num?)?.toInt() ?? 1,
      );
}

/// Coarse licence status shown in the UI.
enum LicenseStatus { none, active, expired, needsRevalidation }

/// A stored licence together with the time it was last verified online.
class LicenseState {
  const LicenseState({required this.key, required this.info, required this.checkedAt});

  /// Full licence key as entered by the user.
  final String key;
  final LicenseInfo info;
  final DateTime checkedAt;

  /// True while the last successful check is within the offline grace period.
  bool isGraceValid(DateTime now, {Duration grace = AppConstants.offlineGrace}) =>
      now.difference(checkedAt) <= grace;

  bool isExpired(DateTime now) =>
      info.expiresAt != null && now.isAfter(info.expiresAt!);

  /// Whether [feature] may be used right now.
  bool grantsFeature(String feature, DateTime now) =>
      !isExpired(now) && isGraceValid(now) && info.features.contains(feature);

  LicenseStatus statusAt(DateTime now) {
    if (isExpired(now)) return LicenseStatus.expired;
    if (!isGraceValid(now)) return LicenseStatus.needsRevalidation;
    return LicenseStatus.active;
  }

  LicenseState copyWith({LicenseInfo? info, DateTime? checkedAt}) => LicenseState(
        key: key,
        info: info ?? this.info,
        checkedAt: checkedAt ?? this.checkedAt,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'info': info.toJson(),
        'checkedAt': checkedAt.toIso8601String(),
      };

  static LicenseState? fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String?;
    final info = json['info'];
    final checked = DateTime.tryParse(json['checkedAt'] as String? ?? '');
    if (key == null || info is! Map<String, dynamic> || checked == null) return null;
    return LicenseState(key: key, info: LicenseInfo.fromJson(info), checkedAt: checked);
  }
}
