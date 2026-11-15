import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/license_state.dart';

/// Persists the activated licence and the per-install device id.
class LicenseRepository {
  LicenseRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Random id generated once per install; identifies this device to the server.
  String get deviceId {
    final existing = _prefs.getString(AppConstants.prefsDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    _prefs.setString(AppConstants.prefsDeviceId, created);
    return created;
  }

  LicenseState? load() {
    final raw = _prefs.getString(AppConstants.prefsLicense);
    if (raw == null) return null;
    try {
      return LicenseState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LicenseState state) =>
      _prefs.setString(AppConstants.prefsLicense, jsonEncode(state.toJson()));

  Future<void> clear() => _prefs.remove(AppConstants.prefsLicense);
}
