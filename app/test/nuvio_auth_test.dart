import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuvio_launcher/data/models/auth_exception.dart';
import 'package:nuvio_launcher/data/models/device_code.dart';
import 'package:nuvio_launcher/data/services/auth/nuvio_auth_service.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _profile = {
  'id': 'aabbccddeeff00112233445566778899',
  'username': 'Steve',
  'name': '[Nuvio]Steve',
  'displayName': '[Nuvio] Steve',
  'badge': true,
  'model': 'slim',
  'skinUrl': null,
  'capeUrl': null,
};

NuvioAuthService _service(MockClient client) =>
    NuvioAuthService(client: client, baseUrl: 'https://site.invalid', delay: (_) async {});

const _code = DeviceCode(
  deviceCode: 'dev',
  userCode: 'ABCD-EFGH',
  verificationUrl: 'https://site.invalid/account/link?code=ABCD-EFGH',
  expiresIn: 600,
  interval: 3,
);

void main() {
  test('start parses the device code', () async {
    final client = MockClient((req) async {
      expect(req.url.toString(), 'https://site.invalid/api/account/device/start');
      return _json({
        'ok': true,
        'deviceCode': 'dev',
        'userCode': 'ABCD-EFGH',
        'verificationUrl': 'https://site.invalid/account/link?code=ABCD-EFGH',
        'expiresIn': 600,
        'interval': 3,
      });
    });
    final code = await _service(client).start();
    expect(code.userCode, 'ABCD-EFGH');
    expect(code.expiresIn, 600);
  });

  test('poll states', () async {
    Future<NuvioPollStatus> poll(http.Response r) async =>
        (await _service(MockClient((_) async => r)).poll('d')).status;

    expect(await poll(_json({'ok': true, 'status': 'pending'})), NuvioPollStatus.pending);
    expect(
      await poll(_json({'ok': false, 'code': 'ACCESS_DENIED', 'message': 'x'}, 403)),
      NuvioPollStatus.denied,
    );
    expect(
      await poll(_json({'ok': false, 'code': 'DEVICE_CODE_EXPIRED', 'message': 'x'}, 410)),
      NuvioPollStatus.expired,
    );
    final approved = await _service(MockClient((_) async => _json({
          'ok': true,
          'status': 'approved',
          'accessToken': 'tok',
          'profile': _profile,
        }))).poll('d');
    expect(approved.status, NuvioPollStatus.approved);
    expect(approved.accessToken, 'tok');
    expect(approved.profile!.displayName, '[Nuvio] Steve');
    expect(approved.profile!.model, 'slim');
  });

  test('waitForApproval loops until approved', () async {
    var n = 0;
    final client = MockClient((_) async {
      n++;
      if (n < 3) return _json({'ok': true, 'status': 'pending'});
      return _json({'ok': true, 'status': 'approved', 'accessToken': 't', 'profile': _profile});
    });
    final r = await _service(client).waitForApproval(_code);
    expect(r.accessToken, 't');
    expect(n, 3);
  });

  test('waitForApproval throws on denied', () async {
    final client = MockClient(
      (_) async => _json({'ok': false, 'code': 'ACCESS_DENIED', 'message': 'no'}, 403),
    );
    await expectLater(
      _service(client).waitForApproval(_code),
      throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.denied)),
    );
  });

  test('me: ok, 401 and network', () async {
    final ok = MockClient((req) async {
      expect(req.headers['Authorization'], 'Bearer tok');
      return _json({'ok': true, 'profile': _profile});
    });
    expect((await _service(ok).me('tok')).username, 'Steve');

    final unauthorized =
        MockClient((_) async => _json({'ok': false, 'code': 'TOKEN_INVALID'}, 401));
    await expectLater(
      _service(unauthorized).me('tok'),
      throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.needsRelogin)),
    );

    final offline = MockClient((_) async => throw Exception('down'));
    await expectLater(
      _service(offline).me('tok'),
      throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.network)),
    );
  });
}
