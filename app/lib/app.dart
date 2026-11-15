import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/platform_utils.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/instance_repository.dart';
import 'data/repositories/license_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/auth/microsoft_auth_service.dart';
import 'data/services/auth/nuvio_auth_service.dart';
import 'data/services/secret_store.dart';
import 'data/services/game_launcher/desktop_game_launcher.dart';
import 'data/services/game_launcher/game_launcher.dart';
import 'data/services/game_launcher/unsupported_game_launcher.dart';
import 'data/services/license_service.dart';
import 'data/services/mojang_service.dart';
import 'data/services/news_service.dart';
import 'features/accounts/accounts_controller.dart';
import 'features/content/content_controller.dart';
import 'features/home/launch_controller.dart';
import 'features/instances/instances_controller.dart';
import 'features/license/license_controller.dart';
import 'features/news/news_controller.dart';
import 'features/settings/settings_controller.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/navigation_controller.dart';
import 'features/versions/versions_controller.dart';
import 'features/wallpaper/wallpaper_background.dart';
import 'features/wallpaper/wallpaper_controller.dart';

/// Root widget: wires repositories, services and controllers together.
class NuvioApp extends StatefulWidget {
  const NuvioApp({super.key, required this.prefs, required this.packageInfo});

  final SharedPreferences prefs;
  final PackageInfo packageInfo;

  @override
  State<NuvioApp> createState() => _NuvioAppState();
}

class _NuvioAppState extends State<NuvioApp> {
  late final SettingsController _settings;
  late final LicenseController _license;
  late final InstancesController _instances;
  late final VersionsController _versions;
  late final NewsController _news;
  late final AccountsController _accounts;
  late final LaunchController _launch;
  late final NavigationController _navigation;
  late final ContentController _content;
  late final WallpaperController _wallpaper;

  @override
  void initState() {
    super.initState();
    final api = ApiClient();
    final version = widget.packageInfo.version;

    _settings = SettingsController(SettingsRepository(widget.prefs));
    _license = LicenseController(
      repository: LicenseRepository(widget.prefs),
      service: LicenseService(api),
      appVersion: version,
    );
    _instances = InstancesController(
      repository: InstanceRepository(widget.prefs),
      license: _license,
    );
    _versions = VersionsController(MojangService());
    _news = NewsController(service: NewsService(api), currentVersion: version);
    _navigation = NavigationController();
    final httpClient = http.Client();
    _accounts = AccountsController(
      repository: AccountRepository(prefs: widget.prefs, secrets: SecureSecretStore()),
      microsoft: MicrosoftAuthService(client: httpClient),
      nuvio: NuvioAuthService(client: httpClient),
    );

    final GameLauncher launcher =
        (isDesktopPlatform && !Platform.isAndroid)
            ? DesktopGameLauncher(launcherVersion: version)
            : UnsupportedGameLauncher();
    _launch = LaunchController(
      launcher: launcher,
      settings: _settings,
      instances: _instances,
      versions: _versions,
      license: _license,
      accounts: _accounts,
    );

    _content = ContentController(
      instances: _instances,
      settings: _settings,
      appVersion: version,
      client: httpClient,
    );
    _wallpaper = WallpaperController(widget.prefs);

    _accounts.init();
    _license.init();
    _news.refresh();
  }

  @override
  void dispose() {
    _wallpaper.dispose();
    _content.dispose();
    _launch.dispose();
    _accounts.dispose();
    _navigation.dispose();
    _news.dispose();
    _versions.dispose();
    _instances.dispose();
    _license.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PackageInfo>.value(value: widget.packageInfo),
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
        ChangeNotifierProvider<LicenseController>.value(value: _license),
        ChangeNotifierProvider<InstancesController>.value(value: _instances),
        ChangeNotifierProvider<VersionsController>.value(value: _versions),
        ChangeNotifierProvider<NewsController>.value(value: _news),
        ChangeNotifierProvider<AccountsController>.value(value: _accounts),
        ChangeNotifierProvider<LaunchController>.value(value: _launch),
        ChangeNotifierProvider<NavigationController>.value(value: _navigation),
        ChangeNotifierProvider<ContentController>.value(value: _content),
        ChangeNotifierProvider<WallpaperController>.value(value: _wallpaper),
      ],
      child: Consumer2<SettingsController, LicenseController>(
        builder: (context, settings, license, _) {
          final custom = settings.settings.accentValue;
          final accent =
              license.hasPlus && custom != null ? Color(custom) : AppColors.neon;
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(accent),
            builder: (context, child) =>
                WallpaperBackground(child: child ?? const SizedBox.shrink()),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
