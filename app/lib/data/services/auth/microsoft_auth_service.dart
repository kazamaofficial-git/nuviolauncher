import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../models/auth_exception.dart';
import '../../models/device_code.dart';
import '../../models/ms_session.dart';
import 'device_poll.dart';

enum MsPollStatus { pending, slowDown, approved, declined, expired }

class MsPollResult {
  const MsPollResult(this.status, [this.tokens]);

  final MsPollStatus status;
  final MsTokens? tokens;
}

/// Microsoft -> Xbox Live -> XSTS -> Minecraft Services (docs/ACCOUNTS.md, section 1).
class MicrosoftAuthService {
  MicrosoftAuthService({
    required http.Client client,
    String? clientId,
    DateTime Function()? clock,
    Future<void> Function(Duration)? delay,
  })  : _client = client,
        clientId = clientId ?? AppConstants.msClientId,
        _clock = clock ?? DateTime.now,
        _delay = delay ?? ((d) => Future<void>.delayed(d));

  static const String _deviceCodeUrl =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode';
  static const String _tokenUrl =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';
  static const String _xblUrl = 'https://user.auth.xboxlive.com/user/authenticate';
  static const String _xstsUrl = 'https://xsts.auth.xboxlive.com/xsts/authorize';
  static const String _mcLoginUrl =
      'https://api.minecraftservices.com/authentication/login_with_xbox';
  static const String _entitlementsUrl =
      'https://api.minecraftservices.com/entitlements/mcstore';
  static const String _profileUrl = 'https://api.minecraftservices.com/minecraft/profile';
  static const String _scope = 'XboxLive.signin offline_access';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;
  final String clientId;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _delay;

  bool get isConfigured => clientId.trim().isNotEmpty;

  // ---------------------------------------------------------------- parsing

  /// Maps an XSTS `XErr` code to a user-facing message (Indonesian + English).
  static String xstsErrorMessage(int? code) {
    switch (code) {
      case 2148916233:
        return 'This Microsoft account has no Xbox account. Create one at xbox.com, then try again. '
            '/ Akun Microsoft ini belum punya akun Xbox. Buat dulu di xbox.com, lalu coba lagi.';
      case 2148916235:
        return 'Xbox Live is not available in your country/region. '
            '/ Xbox Live tidak tersedia di negara/wilayah Anda.';
      case 2148916236:
      case 2148916237:
        return 'Adult verification is required on the Xbox account (xbox.com). '
            '/ Akun Xbox perlu verifikasi usia dewasa (xbox.com).';
      case 2148916238:
        return 'This is a child account. Add it to a Microsoft Family before signing in. '
            '/ Ini akun anak. Tambahkan ke Microsoft Family terlebih dahulu.';
      default:
        return 'Xbox sign-in failed (error ${code ?? 'unknown'}). '
            '/ Login Xbox gagal (kode ${code ?? 'tidak diketahui'}).';
    }
  }

  /// True when the `/entitlements/mcstore` response lists Minecraft Java Edition.
  static bool parseOwnsJava(Object? json) {
    if (json is! Map) return false;
    final items = json['items'];
    if (items is! List) return false;
    for (final item in items) {
      if (item is! Map) continue;
      final name = item['name'];
      if (name is String &&
          (name.contains('product_minecraft') || name.contains('game_minecraft'))) {
        return true;
      }
    }
    return false;
  }

  /// Parses a `/minecraft/profile` response.
  static McProfile? parseProfile(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    Map? pick(Object? list) {
      if (list is! List) return null;
      Map? first;
      for (final e in list) {
        if (e is! Map) continue;
        first ??= e;
        if (e['state'] == 'ACTIVE') return e;
      }
      return first;
    }

    final skin = pick(json['skins']);
    final cape = pick(json['capes']);
    final variant = (skin?['variant'] as String?)?.toLowerCase();
    return McProfile(
      id: id.replaceAll('-', ''),
      name: name,
      skinUrl: skin?['url'] as String?,
      capeUrl: cape?['url'] as String?,
      model: variant == 'slim' ? 'slim' : 'classic',
    );
  }

  // ------------------------------------------------------------- device code

  Future<DeviceCode> startDeviceCode() async {
    _requireConfigured();
    final res = await _send(() => _client.post(
          Uri.parse(_deviceCodeUrl),
          body: {'client_id': clientId, 'scope': _scope},
        ));
    final json = _json(res);
    final deviceCode = json['device_code'];
    final userCode = json['user_code'];
    final uri = json['verification_uri'];
    if (res.statusCode != 200 ||
        deviceCode is! String ||
        userCode is! String ||
        uri is! String) {
      throw AuthException(
        AuthErrorKind.failed,
        'Microsoft sign-in could not be started${_desc(json)}',
      );
    }
    return DeviceCode(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUrl: uri,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 900,
      interval: (json['interval'] as num?)?.toInt() ?? 5,
    );
  }

  /// One poll of the token endpoint.
  Future<MsPollResult> pollOnce(String deviceCode) async {
    final res = await _send(() => _client.post(
          Uri.parse(_tokenUrl),
          body: {
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
            'client_id': clientId,
            'device_code': deviceCode,
          },
        ));
    final json = _json(res);
    final access = json['access_token'];
    if (res.statusCode == 200 && access is String) {
      return MsPollResult(
        MsPollStatus.approved,
        MsTokens(
          accessToken: access,
          refreshToken: json['refresh_token'] as String? ?? '',
        ),
      );
    }
    switch (json['error']) {
      case 'authorization_pending':
        return const MsPollResult(MsPollStatus.pending);
      case 'slow_down':
        return const MsPollResult(MsPollStatus.slowDown);
      case 'authorization_declined':
        return const MsPollResult(MsPollStatus.declined);
      case 'expired_token':
      case 'bad_verification_code':
        return const MsPollResult(MsPollStatus.expired);
      default:
        throw AuthException(AuthErrorKind.failed, 'Microsoft sign-in failed${_desc(json)}');
    }
  }

  /// Polls until the user approves, declines, the code expires or [cancel] fires.
  Future<MsTokens> waitForApproval(DeviceCode code, {AuthCancelToken? cancel}) async {
    var interval = code.interval < 1 ? 5 : code.interval;
    final deadline = _clock().add(Duration(seconds: code.expiresIn));
    while (true) {
      await sleepCancellable(Duration(seconds: interval), _delay, cancel);
      if (cancel?.isCancelled ?? false) throw const AuthException.cancelled();
      if (_clock().isAfter(deadline)) {
        throw const AuthException(
          AuthErrorKind.expired,
          'The sign-in code expired. Start again.',
        );
      }
      final r = await pollOnce(code.deviceCode);
      switch (r.status) {
        case MsPollStatus.pending:
          break;
        case MsPollStatus.slowDown:
          interval += 5;
        case MsPollStatus.approved:
          return r.tokens!;
        case MsPollStatus.declined:
          throw const AuthException(AuthErrorKind.denied, 'Sign-in was declined.');
        case MsPollStatus.expired:
          throw const AuthException(
            AuthErrorKind.expired,
            'The sign-in code expired. Start again.',
          );
      }
    }
  }

  // ------------------------------------------------------------- full chain

  /// Xbox Live -> XSTS -> Minecraft -> entitlement -> profile.
  Future<MsSession> authenticate(MsTokens tokens) async {
    final xbl = await _xboxLive(tokens.accessToken);
    final xsts = await _xsts(xbl);
    final mc = await _minecraftLogin(xsts.uhs, xsts.token);
    final owns = await _checkJava(mc.token);
    final profile = owns ? await _fetchProfile(mc.token) : null;
    return MsSession(
      refreshToken: tokens.refreshToken,
      mcAccessToken: mc.token,
      mcExpiresAt: _clock().add(Duration(seconds: mc.expiresIn)),
      ownsJava: owns,
      xboxUserHash: xsts.uhs,
      profile: profile,
    );
  }

  /// Exchanges [refreshToken] and repeats the Xbox/Minecraft chain.
  Future<MsSession> refresh(String refreshToken) async {
    _requireConfigured();
    final res = await _send(() => _client.post(
          Uri.parse(_tokenUrl),
          body: {
            'grant_type': 'refresh_token',
            'client_id': clientId,
            'refresh_token': refreshToken,
            'scope': _scope,
          },
        ));
    final json = _json(res);
    final access = json['access_token'];
    if (res.statusCode != 200 || access is! String) {
      final err = json['error'];
      if (err == 'invalid_grant' || err == 'interaction_required') {
        throw const AuthException.needsRelogin();
      }
      throw AuthException(AuthErrorKind.failed, 'Could not refresh the session${_desc(json)}');
    }
    return authenticate(MsTokens(
      accessToken: access,
      refreshToken: json['refresh_token'] as String? ?? refreshToken,
    ));
  }

  /// False when Minecraft Services rejects [mcToken] (HTTP 401).
  Future<bool> isTokenValid(String mcToken) async {
    final res = await _send(() => _client.get(
          Uri.parse(_profileUrl),
          headers: {'Authorization': 'Bearer $mcToken'},
        ));
    return res.statusCode != 401;
  }

  // ------------------------------------------------------------------ steps

  Future<({String token, String uhs})> _xboxLive(String msAccessToken) async {
    final res = await _send(() => _client.post(
          Uri.parse(_xblUrl),
          headers: _jsonHeaders,
          body: jsonEncode({
            'Properties': {
              'AuthMethod': 'RPS',
              'SiteName': 'user.auth.xboxlive.com',
              'RpsTicket': 'd=$msAccessToken',
            },
            'RelyingParty': 'http://auth.xboxlive.com',
            'TokenType': 'JWT',
          }),
        ));
    final json = _json(res);
    final claims = _claims(json);
    final token = json['Token'];
    if (res.statusCode != 200 || token is! String || claims == null) {
      throw AuthException(
        AuthErrorKind.xbox,
        'Xbox Live sign-in failed (HTTP ${res.statusCode}). '
        '/ Login Xbox Live gagal (HTTP ${res.statusCode}).',
      );
    }
    return (token: token, uhs: claims);
  }

  Future<({String token, String uhs})> _xsts(({String token, String uhs}) xbl) async {
    final res = await _send(() => _client.post(
          Uri.parse(_xstsUrl),
          headers: _jsonHeaders,
          body: jsonEncode({
            'Properties': {
              'SandboxId': 'RETAIL',
              'UserTokens': [xbl.token],
            },
            'RelyingParty': 'rp://api.minecraftservices.com/',
            'TokenType': 'JWT',
          }),
        ));
    final json = _json(res);
    if (res.statusCode == 401) {
      throw AuthException(
        AuthErrorKind.xbox,
        xstsErrorMessage((json['XErr'] as num?)?.toInt()),
      );
    }
    final token = json['Token'];
    final uhs = _claims(json);
    if (res.statusCode != 200 || token is! String || uhs == null) {
      throw AuthException(
        AuthErrorKind.xbox,
        'Xbox authorization failed (HTTP ${res.statusCode}). '
        '/ Otorisasi Xbox gagal (HTTP ${res.statusCode}).',
      );
    }
    return (token: token, uhs: uhs);
  }

  Future<({String token, int expiresIn})> _minecraftLogin(String uhs, String xsts) async {
    final res = await _send(() => _client.post(
          Uri.parse(_mcLoginUrl),
          headers: _jsonHeaders,
          body: jsonEncode({'identityToken': 'XBL3.0 x=$uhs;$xsts'}),
        ));
    final json = _json(res);
    final token = json['access_token'];
    if (res.statusCode == 403) {
      throw const AuthException(
        AuthErrorKind.failed,
        'Minecraft rejected this launcher app registration (not approved by Mojang yet).',
      );
    }
    if (res.statusCode != 200 || token is! String) {
      throw AuthException(
        AuthErrorKind.failed,
        'Minecraft login failed (HTTP ${res.statusCode}).',
      );
    }
    return (token: token, expiresIn: (json['expires_in'] as num?)?.toInt() ?? 86400);
  }

  Future<bool> _checkJava(String mcToken) async {
    final res = await _send(() => _client.get(
          Uri.parse(_entitlementsUrl),
          headers: {'Authorization': 'Bearer $mcToken'},
        ));
    if (res.statusCode != 200) {
      throw AuthException(
        AuthErrorKind.failed,
        'Could not check the Minecraft license (HTTP ${res.statusCode}).',
      );
    }
    return parseOwnsJava(_json(res));
  }

  Future<McProfile?> _fetchProfile(String mcToken) async {
    final res = await _send(() => _client.get(
          Uri.parse(_profileUrl),
          headers: {'Authorization': 'Bearer $mcToken'},
        ));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw AuthException(
        AuthErrorKind.failed,
        'Could not load the Minecraft profile (HTTP ${res.statusCode}).',
      );
    }
    return parseProfile(_json(res));
  }

  // ---------------------------------------------------------------- helpers

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void _requireConfigured() {
    if (!isConfigured) {
      throw const AuthException(
        AuthErrorKind.notConfigured,
        'Microsoft login is not configured in this build.',
      );
    }
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

  String? _claims(Map<String, dynamic> json) {
    final claims = json['DisplayClaims'];
    if (claims is! Map) return null;
    final xui = claims['xui'];
    if (xui is! List || xui.isEmpty || xui.first is! Map) return null;
    final uhs = (xui.first as Map)['uhs'];
    return uhs is String ? uhs : null;
  }

  String _desc(Map<String, dynamic> json) {
    final d = json['error_description'];
    return d is String && d.isNotEmpty ? ': ${d.split('\n').first}' : '.';
  }
}
