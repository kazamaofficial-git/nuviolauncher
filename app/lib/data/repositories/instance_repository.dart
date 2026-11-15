import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/instance.dart';

/// Persists game instances and the selected instance id.
class InstanceRepository {
  InstanceRepository(this._prefs);

  final SharedPreferences _prefs;

  List<Instance> load() {
    final raw = _prefs.getString(AppConstants.prefsInstances);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map(Instance.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Instance> items) => _prefs.setString(
        AppConstants.prefsInstances,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );

  String? loadSelected() => _prefs.getString(AppConstants.prefsSelectedInstance);

  Future<void> saveSelected(String? id) => id == null
      ? _prefs.remove(AppConstants.prefsSelectedInstance)
      : _prefs.setString(AppConstants.prefsSelectedInstance, id);
}
