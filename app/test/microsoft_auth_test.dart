import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuvio_launcher/data/models/auth_exception.dart';
import 'package:nuvio_launcher/data/models/device_code.dart';
import 'package:nuvio_launcher/data/models/ms_session.dart';
import 'package:nuvio_launcher/data/services/auth/microsoft_auth_service.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

MicrosoftAuthService _service(MockClient client, {DateTime Function()? clock}) =>
    MicrosoftAuthService(
      client: client,
      clientId: 'cid',
      clock: clock,
      delay: (_) async {},
    );

const _code = DeviceCode(
  deviceCode: 'dev',
  userCode: 'ABC',
  verificationUrl: 'https://example.invalid/link',
  expiresIn: 900,
  interval: 5,
);

void main() {
  group('XSTS error mapping', () {
    test('known codes give specific messages', () {
      expect(MicrosoftAuthService.xstsErrorMessage(2148916233), contains('no Xbox account'));
      expect(MicrosoftAuthService.xstsErrorMessage(2148916235), contains('country'));
      expect(MicrosoftAuthService.xstsErrorMessage(2148916236), contains('Adult'));
      expect(MicrosoftAuthService.xstsErrorMessage(2148916237), contains('Adult'));
      expect(MicrosoftAuthService.xstsErrorMessage(2148916238), contains('child'));
    });

    test('unknown code is generic and includes the code', () {
      expect(MicrosoftAuthService.xstsErrorMessage(42), contains('42'));
      expect(MicrosoftAuthService.xstsErrorMessage(null), contains('unknown'));
    });

    test('XSTS 401 surfaces the mapped message', () async {
      final client = MockClient((req) async {
        if (req.url.host == 'user.auth.xboxlive.com') {
          return _json({
            'Token': 'xbl',
            'DisplayClaims': {
              'xui': [
                {'uhs': 'h'}
              ]
            },
          });
        }
        return _json({'XErr': 2148916233}, 401);
      });
      final s = _service(client);
      await expectLater(
        s.authenticate(const MsTokens(accessToken: 'a', refreshToken: 'r')),
        throwsA(isA<AuthException>()
            .having((e) => e.kind, 'kind', AuthErrorKind.xbox)
            .having((e) => e.message, 'message', contains('no Xbox account'))),
      );
    });
  });

  group('entitlement and profile parsing', () {
    test('detects Java license', () {
      expect(
        MicrosoftAuthService.parseOwnsJava({
          'items': [
            {'name': 'product_minecraft'},
            {'name': 'game_minecraft'},
          ]
        }),
        isTrue,
      );
      expect(MicrosoftAuthService.parseOwnsJava({'items': []}), isFalse);
      expect(
        MicrosoftAuthService.parseOwnsJava({
          'items': [
            {'name': 'something_else'}
          ]
        }),
        isFalse,
      );
      expect(MicrosoftAuthService.parseOwnsJava('nope'), isFalse);
    });

    test('parses profile with active skin and slim model', () {
      final p = MicrosoftAuthService.parseProfile({
        'id': 'abc123',
        'name': 'Steve',
        'skins': [
          {'state': 'INACTIVE', 'url': 'http://old', 'variant': 'CLASSIC'},
          {'state': 'ACTIVE', 'url': 'http://new', 'variant': 'SLIM'},
        ],
        'capes': [],
      })!;
      expect(p.name, 'Steve');
      expect(p.skinUrl, 'http://new');
      expect(p.model, 'slim');
      expect(p.capeUrl, isNull);
    });
  });

  group('device code', () {
    test('startDeviceCode parses the response', () async {
      final client = MockClient((req) async {
        expect(req.bodyFields['client_id'], 'cid');
        return _json({
          'device_code': 'dev',
          'user_code': 'XYZ',
          'verification_uri': 'https://example.invalid/link',
          'expires_in': 900,
          'interval': 5,
        });
      });
      final code = await _service(client).startDeviceCode();
      expect(code.userCode, 'XYZ');
      expect(code.interval, 5);
    });

    test('not configured throws notConfigured', () async {
      final s = MicrosoftAuthService(client: MockClient((_) async => _json({})), clientId: '');
      expect(s.isConfigured, isFalse);
      await expectLater(
        s.startDeviceCode(),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.notConfigured)),
      );
    });

    test('polling handles pending, slow_down then approval', () async {
      final answers = [
        _json({'error': 'authorization_pending'}, 400),
        _json({'error': 'slow_down'}, 400),
        _json({'access_token': 'at', 'refresh_token': 'rt'}),
      ];
      var calls = 0;
      final client = MockClient((_) async => answers[calls++]);
      final tokens = await _service(client).waitForApproval(_code);
      expect(tokens.accessToken, 'at');
      expect(tokens.refreshToken, 'rt');
      expect(calls, 3);
    });

    test('declined and expired stop polling', () async {
      final declined = MockClient((_) async => _json({'error': 'authorization_declined'}, 400));
      await expectLater(
        _service(declined).waitForApproval(_code),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.denied)),
      );
      final expired = MockClient((_) async => _json({'error': 'expired_token'}, 400));
      await expectLater(
        _service(expired).waitForApproval(_code),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.expired)),
      );
    });

    test('pollOnce maps statuses', () async {
      final r = await _service(MockClient((_) async => _json({'error': 'slow_down'}, 400)))
          .pollOnce('d');
      expect(r.status, MsPollStatus.slowDown);
    });
  });

  group('full chain', () {
    MockClient chain({required List<Map<String, String>> items, int profileStatus = 200}) =>
        MockClient((req) async {
          final host = req.url.host;
          if (host == 'login.microsoftonline.com') {
            return _json({'access_token': 'ms', 'refresh_token': 'rt2'});
          }
          if (host == 'user.auth.xboxlive.com') {
            return _json({
              'Token': 'xbl',
              'DisplayClaims': {
                'xui': [
                  {'uhs': 'uhs1'}
                ]
              },
            });
          }
          if (host == 'xsts.auth.xboxlive.com') {
            return _json({
              'Token': 'xsts',
              'DisplayClaims': {
                'xui': [
                  {'uhs': 'uhs1'}
                ]
              },
            });
          }
          if (req.url.path.contains('login_with_xbox')) {
            expect(jsonDecode(req.body)['identityToken'], 'XBL3.0 x=uhs1;xsts');
            return _json({'access_token': 'mc', 'expires_in': 86400});
          }
          if (req.url.path.contains('entitlements')) return _json({'items': items});
          return profileStatus == 404
              ? _json({'error': 'NOT_FOUND'}, 404)
              : _json({'id': 'aabb', 'name': 'Alex', 'skins': [], 'capes': []});
        });

    final now = DateTime.utc(2026, 1, 1);

    test('refresh succeeds with Java license', () async {
      final s = _service(
        chain(items: [
          {'name': 'game_minecraft'}
        ]),
        clock: () => now,
      );
      final session = await s.refresh('rt');
      expect(session.ownsJava, isTrue);
      expect(session.profile!.name, 'Alex');
      expect(session.refreshToken, 'rt2');
      expect(session.mcExpiresAt, now.add(const Duration(seconds: 86400)));
    });

    test('no license keeps the account without profile', () async {
      final session = await _service(chain(items: const [])).refresh('rt');
      expect(session.ownsJava, isFalse);
      expect(session.profile, isNull);
    });

    test('404 profile yields null profile but owns Java', () async {
      final session = await _service(
        chain(items: [
          {'name': 'product_minecraft'}
        ], profileStatus: 404),
      ).refresh('rt');
      expect(session.ownsJava, isTrue);
      expect(session.profile, isNull);
    });

    test('invalid_grant on refresh means needsRelogin', () async {
      final client = MockClient((_) async => _json({'error': 'invalid_grant'}, 400));
      await expectLater(
        _service(client).refresh('rt'),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.needsRelogin)),
      );
    });

    test('network failure maps to network error', () async {
      final client = MockClient((_) async => throw Exception('offline'));
      await expectLater(
        _service(client).refresh('rt'),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.network)),
      );
    });
  });
}
