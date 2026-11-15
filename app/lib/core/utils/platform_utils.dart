import 'dart:io';

/// True on platforms where the full desktop launch pipeline is available.
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Platform identifier used by the licensing API.
String get platformName {
  if (Platform.isWindows) return 'windows';
  if (Platform.isAndroid) return 'android';
  if (Platform.isMacOS) return 'macos';
  return 'linux';
}
