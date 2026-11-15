import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../models/auth_exception.dart';
import '../../models/device_code.dart';
import '../../models/nuvio_profile.dart';
import 'device_poll.dart';

enum NuvioPollStatus { pending, approved, denied, expired }

class NuvioPollResult {
  const NuvioPollResult(this.status, {this.accessToken, this.profile});

  final NuvioPollStatus status;
  final String? accessToken;
  final NuvioProfile? profile;
}

/// Nuvio website account (device link), see docs/ACCOUNTS.md section 2.
class NuvioAuthService {
  NuvioAuthService({
    required http.Client client,
    String? baseUrl,
    Future<void> Function(Duration)? delay,
    DateTime Function()? clock,
  })  : _client = client,
        baseUrl = baseUrl ?? AppConstants.apiBase,
        _delay = delay ?? ((d) => Future<void>.delayed(d)),
        _clock = clock ?? DateTime.now;

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String baseUrl;
  final Future<void> Function(Duration) _delay;
  final DateTime Function() _clock;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path');
  }

  Future<DeviceCode> start() async {
    final res = await _send(
      () => _client.post(_uri('/api/account/device/start'), headers: _headers, body: '{}'),
    );
    final json = _json(res);
    final deviceCode = json['deviceCode'];
    final userCode = json['userCode'];
    final url = json['verificationUrl'];
    if (json['ok'] != true || deviceCode is! String || userCode is! String || url is! String) {
      throw AuthException(
        AuthErrorKind.failed,
        json['message'] as String? ?? 'Could not start the Nuvio sign-in (HTTP ${res.statusCode}).',
      );
    }
    return DeviceCode(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUrl: url,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 600,
      interval: (json['interval'] as num?)?.toInt() ?? 3,
    );
  }

  Future<NuvioPollResult> poll(String deviceCode) async {
    final res = await _send(() => _client.post(
          _uri('/api/account/device/poll'),
          headers: _headers,
          body: jsonEncode({'deviceCode': deviceCode}),
        ));
    final json = _json(res);
    if (json['ok'] == true) {
      final status = json['status'];
      if (status == 'pending') return const NuvioPollResult(NuvioPollStatus.pending);
      final token = json['accessToken'];
      final profile = json['profile'];
      if (status == 'approved' && token is String && profile is Map<String, dynamic>) {
        return NuvioPollResult(
          NuvioPollStatus.approved,
          accessToken: token,
          profile: NuvioProfile.fromJson(profile),
        );
      }
    }
    switch (json['code']) {
      case 'ACCESS_DENIED':
        return const NuvioPollResult(NuvioPollStatus.denied);
      case 'DEVICE_CODE_EXPIRED':
        return const NuvioPollResult(NuvioPollStatus.expired);
    }
    throw AuthException(
      AuthErrorKind.failed,
      json['message'] as String? ?? 'Nuvio sign-in failed (HTTP ${res.statusCode}).',
    );
  }

  /// Polls until approved; throws [AuthException] for denied/expired/cancelled.
  Future<NuvioPollResult> waitForApproval(DeviceCode code, {AuthCancelToken? cancel}) async {
    final interval = code.interval < 1 ? 3 : code.interval;
    final deadline = _clock().add(Duration(seconds: code.expiresIn));
    while (true) {
      await sleepCancellable(Duration(seconds: interval), _delay, cancel);
      if (cancel?.isCancelled ?? false) throw const AuthException.cancelled();
      if (_clock().isAfter(deadline)) {
        throw const AuthException(AuthErrorKind.expired, 'The sign-in code expired. Start again.');
      }
      final r = await poll(code.deviceCode);
      switch (r.status) {
        case NuvioPollStatus.pending:
          break;
        case NuvioPollStatus.approved:
          return r;
        case NuvioPollStatus.denied:
          throw const AuthException(AuthErrorKind.denied, 'Sign-in was denied on the website.');
        case NuvioPollStatus.expired:
          throw const AuthException(AuthErrorKind.expired, 'The sign-in code expired. Start again.');
      }
    }
  }

  /// Validates the token; HTTP 401 means the account needs to sign in again.
  Future<NuvioProfile> me(String accessToken) async {
    final res = await _send(() => _client.get(
          _uri('/api/account/me'),
          headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
        ));
    if (res.statusCode == 401) throw const AuthException.needsRelogin();
    final json = _json(res);
    final profile = json['profile'];
    if (res.statusCode != 200 || json['ok'] != true || profile is! Map<String, dynamic>) {
      throw AuthException(
        AuthErrorKind.failed,
        json['message'] as String? ?? 'Could not verify the Nuvio account (HTTP ${res.statusCode}).',
      );
    }
    return NuvioProfile.fromJson(profile);
  }

  /// Revokes the token on the server.
  Future<void> logout(String accessToken) async {
    await _send(() => _client.post(
          _uri('/api/account/logout'),
          headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
          body: '{}',
        ));
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } catch (_) {
      throw const AuthException.network();
    }
  }

  Map<String, dynamic> _json(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
