import '../models/announcement.dart';
import '../models/release_info.dart';
import 'api_client.dart';

/// Reads announcements and release metadata from the website API.
class NewsService {
  NewsService(this._api);

  final ApiClient _api;

  Future<List<Announcement>> fetchAnnouncements() async {
    final json = await _api.getJson('/api/announcements');
    final items = json['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Announcement.fromJson)
        .toList();
  }

  Future<ReleaseInfo> fetchLatestRelease() async {
    final json = await _api.getJson('/api/releases/latest');
    return ReleaseInfo.fromJson(json);
  }
}
