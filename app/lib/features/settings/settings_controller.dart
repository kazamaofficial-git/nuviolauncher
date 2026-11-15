import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/app_settings.dart';
import '../../data/repositories/settings_repository.dart';

/// Holds and persists user settings.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository) : _settings = _repository.load();

  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  Future<void> update(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }

  /// Folder that contains versions, libraries, assets and instances.
  Future<String> resolveGameRoot() async {
    final custom = _settings.gameDir.trim();
    final path = custom.isNotEmpty
        ? custom
        : p.join((await getApplicationDocumentsDirectory()).path, 'NuvioLauncher');
    await Directory(path).create(recursive: true);
    return path;
  }

  /// Folder of one instance: `<game root>/instances/<id>`.
  Future<String> resolveInstanceDir(String instanceId) async {
    final root = await resolveGameRoot();
    return p.join(root, 'instances', instanceId);
  }
}
