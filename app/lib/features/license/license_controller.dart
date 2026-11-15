import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_utils.dart';
import '../../data/models/license_state.dart';
import '../../data/repositories/license_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/license_service.dart';

/// Manages licence activation, periodic re-validation and the offline grace period.
class LicenseController extends ChangeNotifier {
  LicenseController({
    required LicenseRepository repository,
    required LicenseService service,
    required String appVersion,
    DateTime Function()? clock,
  })  : _repository = repository,
        _service = service,
        _appVersion = appVersion,
        _clock = clock ?? DateTime.now;

  final LicenseRepository _repository;
  final LicenseService _service;
  final String _appVersion;
  final DateTime Function() _clock;

  LicenseState? _state;
  bool _busy = false;
  String? _message;
  Timer? _timer;

  LicenseState? get state => _state;
  bool get busy => _busy;

  /// Last error / info message for the licence page.
  String? get message => _message;

  LicenseStatus get status =>
      _state == null ? LicenseStatus.none : _state!.statusAt(_clock());

  /// Whether Nuvio Plus features are currently usable.
  bool get hasPlus =>
      _state?.grantsFeature(AppConstants.plusFeature, _clock()) ?? false;

  /// Loads the stored licence and starts background re-validation.
  Future<void> init() async {
    _state = _repository.load();
    notifyListeners();
    if (_state != null) unawaited(revalidate());
    _timer = Timer.periodic(AppConstants.revalidateInterval, (_) => revalidate());
  }

  Future<bool> activate(String rawKey) async {
    final key = rawKey.trim().toUpperCase();
    if (key.isEmpty) {
      _message = 'Enter your licence key.';
      notifyListeners();
      return false;
    }
    _busy = true;
    _message = null;
    notifyListeners();
    try {
      final info = await _service.activate(
        key: key,
        deviceId: _repository.deviceId,
        deviceName: Platform.localHostname,
        platform: platformName,
        appVersion: _appVersion,
      );
      _state = LicenseState(key: key, info: info, checkedAt: _clock());
      await _repository.save(_state!);
      _message = 'Licence activated. Thank you for supporting Nuvio!';
      return true;
    } on ApiException catch (e) {
      _message = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Re-checks the stored licence. Network failures keep the cached state
  /// (the grace period applies); definitive server rejections clear it.
  Future<void> revalidate() async {
    final current = _state;
    if (current == null) return;
    try {
      final info = await _service.validate(
        key: current.key,
        deviceId: _repository.deviceId,
        appVersion: _appVersion,
      );
      _state = current.copyWith(info: info, checkedAt: _clock());
      await _repository.save(_state!);
      _message = null;
    } on ApiException catch (e) {
      if (!e.isNetwork && e.code != 'RATE_LIMITED' && e.code != 'SERVER_ERROR') {
        _state = null;
        await _repository.clear();
        _message = e.message;
      }
    }
    notifyListeners();
  }

  Future<void> deactivate() async {
    final current = _state;
    if (current == null) return;
    _busy = true;
    _message = null;
    notifyListeners();
    try {
      await _service.deactivate(key: current.key, deviceId: _repository.deviceId);
      _state = null;
      await _repository.clear();
      _message = 'Licence removed from this device.';
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _message = 'Connect to the internet to free this device slot.';
      } else {
        _state = null;
        await _repository.clear();
        _message = e.message;
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
