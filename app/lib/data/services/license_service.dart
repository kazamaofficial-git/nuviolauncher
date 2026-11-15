import '../models/license_state.dart';
import 'api_client.dart';

/// Talks to the `/api/license/*` endpoints.
class LicenseService {
  LicenseService(this._api);

  final ApiClient _api;

  Future<LicenseInfo> activate({
    required String key,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String appVersion,
  }) async {
    final json = await _api.postJson('/api/license/activate', {
      'key': key,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'appVersion': appVersion,
    });
    return _parse(json);
  }

  Future<LicenseInfo> validate({
    required String key,
    required String deviceId,
    required String appVersion,
  }) async {
    final json = await _api.postJson('/api/license/validate', {
      'key': key,
      'deviceId': deviceId,
      'appVersion': appVersion,
    });
    return _parse(json);
  }

  Future<void> deactivate({required String key, required String deviceId}) async {
    await _api.postJson('/api/license/deactivate', {'key': key, 'deviceId': deviceId});
  }

  LicenseInfo _parse(Map<String, dynamic> json) {
    final license = json['license'];
    if (license is! Map<String, dynamic>) {
      throw const ApiException(code: 'SERVER_ERROR', message: 'Malformed licence response.');
    }
    return LicenseInfo.fromJson(license);
  }
}
