import '../../core/constants/app_constants.dart';

/// User preferences persisted as a single JSON blob.
class AppSettings {
  const AppSettings({
    this.gameDir = '',
    this.javaPath = '',
    this.defaultRamMb = AppConstants.defaultRamMb,
    this.accentValue,
  });

  /// Custom game root; empty means "use the default folder".
  final String gameDir;

  /// Custom Java executable; empty means auto-detect.
  final String javaPath;
  final int defaultRamMb;

  /// ARGB value of the custom accent (Nuvio Plus), or null for the default.
  final int? accentValue;

  AppSettings copyWith({
    String? gameDir,
    String? javaPath,
    int? defaultRamMb,
  }) =>
      AppSettings(
        gameDir: gameDir ?? this.gameDir,
        javaPath: javaPath ?? this.javaPath,
        defaultRamMb: defaultRamMb ?? this.defaultRamMb,
        accentValue: accentValue,
      );

  /// Returns a copy with a new accent (pass null to reset).
  AppSettings withAccent(int? value) => AppSettings(
        gameDir: gameDir,
        javaPath: javaPath,
        defaultRamMb: defaultRamMb,
        accentValue: value,
      );

  Map<String, dynamic> toJson() => {
        'gameDir': gameDir,
        'javaPath': javaPath,
        'defaultRamMb': defaultRamMb,
        'accentValue': accentValue,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        gameDir: json['gameDir'] as String? ?? '',
        javaPath: json['javaPath'] as String? ?? '',
        defaultRamMb: (json['defaultRamMb'] as num?)?.toInt() ?? AppConstants.defaultRamMb,
        accentValue: (json['accentValue'] as num?)?.toInt(),
      );
}
