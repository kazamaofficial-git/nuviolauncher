import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/platform_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nuvio is landscape-only on every platform.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  if (isDesktopPlatform) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1180, 700),
      minimumSize: Size(900, 560),
      center: true,
      title: AppConstants.appName,
      backgroundColor: AppColors.background,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  runApp(NuvioApp(prefs: prefs, packageInfo: packageInfo));
}
