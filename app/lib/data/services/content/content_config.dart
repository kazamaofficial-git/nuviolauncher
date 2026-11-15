/// Compile-time configuration of the content providers.
abstract final class ContentConfig {
  /// Set with `--dart-define=CURSEFORGE_API_KEY=...`.
  static const String curseForgeApiKey = String.fromEnvironment('CURSEFORGE_API_KEY');

  static bool get curseForgeEnabled => curseForgeApiKey.isNotEmpty;

  /// `KazamaTech/NuvioLauncher/<version>` as required by Modrinth.
  static String userAgent(String appVersion) =>
      'KazamaTech/NuvioLauncher/$appVersion';
}
