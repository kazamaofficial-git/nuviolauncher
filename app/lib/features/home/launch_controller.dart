import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/services/game_launcher/game_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/auth_exception.dart';
import '../accounts/accounts_controller.dart';
import '../instances/instances_controller.dart';
import '../license/license_controller.dart';
import '../settings/settings_controller.dart';
import '../versions/versions_controller.dart';

/// Drives the launch pipeline and exposes progress/log state to the UI.
class LaunchController extends ChangeNotifier {
  LaunchController({
    required this.launcher,
    required SettingsController settings,
    required InstancesController instances,
    required VersionsController versions,
    required LicenseController license,
    required AccountsController accounts,
  })  : _license = license,
        _accounts = accounts,
        _settings = settings,
        _instances = instances,
        _versions = versions;

  static const int _maxLogLines = 400;

  final GameLauncher launcher;
  final SettingsController _settings;
  final InstancesController _instances;
  final VersionsController _versions;
  final LicenseController _license;
  final AccountsController _accounts;

  final List<String> _logs = [];
  bool _busy = false;
  bool _gameRunning = false;
  double? _progress;
  String _status = '';
  String? _error;

  List<String> get logs => List.unmodifiable(_logs);
  bool get isBusy => _busy;
  bool get isGameRunning => _gameRunning;
  double? get progress => _progress;
  String get status => _status;
  String? get error => _error;

  Future<void> play() async {
    if (_busy) return;
    final instance = _instances.selected;
    if (instance == null) {
      _error = 'Create an instance first.';
      notifyListeners();
      return;
    }

    _busy = true;
    _gameRunning = false;
    _error = null;
    _progress = null;
    _status = 'Preparing...';
    _logs.clear();
    notifyListeners();

    try {
      _status = 'Checking account...';
      notifyListeners();
      final auth = await _accounts.prepareForLaunch();
      final version = await _versions.findById(instance.versionId);
      if (version == null) {
        throw StateError('Version ${instance.versionId} was not found in the manifest.');
      }
      final root = await _settings.resolveGameRoot();
      final s = _settings.settings;
      final request = LaunchRequest(
        instance: instance,
        version: version,
        auth: auth,
        gameRoot: root,
        javaPath: s.javaPath.trim().isEmpty ? null : s.javaPath.trim(),
        downloadThreads: _license.hasPlus
            ? AppConstants.plusDownloadThreads
            : AppConstants.freeDownloadThreads,
      );

      final done = Completer<void>();
      launcher.launch(request).listen(
            (event) => _onEvent(event, instance.id),
            onDone: () {
              if (!done.isCompleted) done.complete();
            },
            onError: (Object e) {
              _error = e.toString();
              if (!done.isCompleted) done.complete();
            },
          );
      await done.future;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      _gameRunning = false;
      _progress = null;
      notifyListeners();
    }
  }

  Future<void> stop() => launcher.stop();

  void _onEvent(LaunchEvent event, String instanceId) {
    if (event.isLog) {
      _logs.add(event.message);
      if (_logs.length > _maxLogLines) _logs.removeRange(0, _logs.length - _maxLogLines);
    } else {
      _status = event.message;
      _progress = event.progress;
      switch (event.phase) {
        case LaunchPhase.running:
          if (!_gameRunning) unawaited(_instances.markPlayed(instanceId));
          _gameRunning = true;
        case LaunchPhase.failed:
          _error = event.message;
        case LaunchPhase.finished:
          _gameRunning = false;
        case LaunchPhase.preparing:
        case LaunchPhase.downloading:
        case LaunchPhase.launching:
          break;
      }
    }
    notifyListeners();
  }
}
