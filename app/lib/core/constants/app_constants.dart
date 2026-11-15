/// Static and compile-time configuration for the launcher.
abstract final class AppConstants {
  static const String appName = 'Nuvio Launcher';
  static const String developer = 'Kazama Tech';

  /// Website / API base URL. Override with
  /// `--dart-define=NUVIO_API_BASE=https://your-domain`.
  static const String apiBase = String.fromEnvironment(
    'NUVIO_API_BASE',
    defaultValue: 'http://localhost:3000',
  );

  /// Azure application (client) id for Microsoft login. Override with
  /// `--dart-define=MS_CLIENT_ID=<id>`; empty disables Microsoft login.
  static const String msClientId = String.fromEnvironment('MS_CLIENT_ID');

  static const Duration apiTimeout = Duration(seconds: 15);

  // Licensing rules (see docs/API.md).
  static const String plusFeature = 'plus';
  static const int freeInstanceLimit = 3;
  static const Duration offlineGrace = Duration(days: 7);
  static const Duration revalidateInterval = Duration(hours: 24);

  // Minecraft endpoints.
  static const String versionManifestUrl =
      'https://launcher.mojang.com/mc/game/version_manifest_v2.json';
  static const String resourcesBase = 'https://resources.download.minecraft.net';
  static const String librariesBase = 'https://libraries.minecraft.net/';

  // Game defaults.
  static const int minRamMb = 1024;
  static const int maxRamMb = 16384;
  static const int ramStepMb = 512;
  static const int defaultRamMb = 2048;
  /// Parallel download workers: Free vs Nuvio Plus.
  static const int freeDownloadThreads = 4;
  static const int plusDownloadThreads = 16;
  static const List<String> renderers = [
    'Auto',
    'OpenGL (native)',
    'Zink (Vulkan)',
    'GL4ES',
  ];

  // SharedPreferences keys.
  static const String prefsSettings = 'nuvio.settings';
  static const String prefsInstances = 'nuvio.instances';
  static const String prefsSelectedInstance = 'nuvio.selectedInstance';
  static const String prefsLicense = 'nuvio.license';
  static const String prefsAccounts = 'nuvio.accounts';
  static const String prefsSelectedAccount = 'nuvio.selectedAccount';
  static const String prefsDeviceId = 'nuvio.deviceId';

  /// Turns a relative API path (or absolute URL) into an absolute URL.
  static String resolveUrl(String urlOrPath) {
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    final base = apiBase.endsWith('/')
        ? apiBase.substring(0, apiBase.length - 1)
        : apiBase;
    final path = urlOrPath.startsWith('/') ? urlOrPath : '/$urlOrPath';
    return '$base$path';
  }
}
