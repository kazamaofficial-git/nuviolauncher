import 'account.dart';

/// Everything the game process needs to authenticate a player.
class LaunchAuth {
  const LaunchAuth({
    required this.username,
    required this.uuid,
    required this.accessToken,
    required this.userType,
    this.extraJvmArgs = const [],
    this.authlibInjectorPath,
    this.yggdrasilRoot,
  });

  /// Offline account: offline UUID, dummy token, `legacy` user type.
  factory LaunchAuth.local(Account account) => LaunchAuth(
        username: account.name,
        uuid: account.uuid,
        accessToken: '0',
        userType: 'legacy',
      );

  /// Real Minecraft session obtained through Microsoft/Xbox.
  factory LaunchAuth.microsoft(Account account, String mcAccessToken) => LaunchAuth(
        username: account.name,
        uuid: account.uuid,
        accessToken: mcAccessToken,
        userType: 'msa',
      );

  /// Nuvio account: authenticates against the website's Yggdrasil server
  /// through authlib-injector. The launcher downloads the injector and puts
  /// `-javaagent:<jar>=<yggdrasilRoot>` before the classpath.
  factory LaunchAuth.nuvio(Account account, String accessToken, String apiBase) {
    final base = apiBase.endsWith('/') ? apiBase.substring(0, apiBase.length - 1) : apiBase;
    return LaunchAuth(
      username: account.name,
      uuid: account.uuid,
      accessToken: accessToken,
      userType: 'mojang',
      extraJvmArgs: const ['-Dauthlibinjector.side=client'],
      yggdrasilRoot: '$base/api/yggdrasil',
    );
  }

  final String username;

  /// 32 hex characters, no dashes.
  final String uuid;
  final String accessToken;

  /// `msa`, `mojang` or `legacy`.
  final String userType;

  /// JVM arguments added before the classpath arguments.
  final List<String> extraJvmArgs;

  /// Already-known authlib-injector jar; when null and [yggdrasilRoot] is set
  /// the launcher downloads it.
  final String? authlibInjectorPath;

  /// Yggdrasil API root (`<NUVIO_API_BASE>/api/yggdrasil`), Nuvio accounts only.
  final String? yggdrasilRoot;

  bool get needsAuthlibInjector => yggdrasilRoot != null;
}
