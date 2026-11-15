import 'package:flutter/foundation.dart';

import '../../data/models/mc_version.dart';
import '../../data/services/mojang_service.dart';

/// Loads Mojang's manifest and exposes a filtered/searchable view.
class VersionsController extends ChangeNotifier {
  VersionsController(this._service);

  final MojangService _service;

  List<McVersion> _all = const [];
  Future<void>? _inflight;
  bool _loading = false;
  String? _error;
  String _query = '';
  final Set<VersionFilter> _filters = {VersionFilter.release};

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  Set<VersionFilter> get filters => Set.unmodifiable(_filters);
  List<McVersion> get releases => _all.where((v) => v.isRelease).toList();

  List<McVersion> get visible {
    final q = _query.trim().toLowerCase();
    return _all
        .where((v) => _filters.contains(v.filter))
        .where((v) => q.isEmpty || v.id.toLowerCase().contains(q))
        .toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void toggleFilter(VersionFilter filter) {
    if (!_filters.remove(filter)) _filters.add(filter);
    notifyListeners();
  }

  Future<void> ensureLoaded() {
    if (_all.isNotEmpty) return Future.value();
    return _inflight ??= _load();
  }

  Future<void> refresh() => _inflight ??= _load();

  Future<McVersion?> findById(String id) async {
    await ensureLoaded();
    for (final v in _all) {
      if (v.id == id) return v;
    }
    return null;
  }

  Future<void> _load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _service.fetchVersions();
    } catch (e) {
      _error = 'Could not load the version list. Check your connection.';
    } finally {
      _loading = false;
      _inflight = null;
      notifyListeners();
    }
  }
}
