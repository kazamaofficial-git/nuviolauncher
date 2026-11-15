import 'package:flutter/foundation.dart';

import '../../core/utils/version_compare.dart';
import '../../data/models/announcement.dart';
import '../../data/models/release_info.dart';
import '../../data/services/api_client.dart';
import '../../data/services/news_service.dart';

/// Announcements and update checks.
class NewsController extends ChangeNotifier {
  NewsController({required NewsService service, required this.currentVersion})
      : _service = service;

  final NewsService _service;
  final String currentVersion;

  List<Announcement> _announcements = const [];
  ReleaseInfo? _latest;
  bool _loading = false;
  String? _error;

  List<Announcement> get announcements => _announcements;
  ReleaseInfo? get latest => _latest;
  bool get loading => _loading;
  String? get error => _error;

  /// The latest release when it is newer than the running app.
  ReleaseInfo? get update {
    final latest = _latest;
    if (latest == null) return null;
    return isNewerVersion(latest.version, currentVersion) ? latest : null;
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    String? error;
    try {
      _announcements = await _service.fetchAnnouncements();
    } on ApiException catch (e) {
      error = e.message;
    }
    try {
      _latest = await _service.fetchLatestRelease();
    } on ApiException catch (e) {
      error ??= e.message;
    }

    _error = error;
    _loading = false;
    notifyListeners();
  }
}
