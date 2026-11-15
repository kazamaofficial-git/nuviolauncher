import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuvio_launcher/data/models/account.dart';
import 'package:nuvio_launcher/data/models/account_secrets.dart';
import 'package:nuvio_launcher/data/models/auth_exception.dart';
import 'package:nuvio_launcher/data/models/launch_auth.dart';
import 'package:nuvio_launcher/data/repositories/account_repository.dart';
import 'package:nuvio_launcher/data/services/auth/microsoft_auth_service.dart';
import 'package:nuvio_launcher/data/services/auth/nuvio_auth_service.dart';
import 'package:nuvio_launcher/data/services/secret_store.dart';
import 'package:nuvio_launcher/features/accounts/accounts_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Future<(AccountsController, AccountRepository, MemorySecretStore)> _setup(
  MockClient client,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final secrets = MemorySecretStore();
  final repo = AccountRepository(prefs: prefs, secrets: secrets);
  final controller = AccountsController(
    repository: repo,
    microsoft: MicrosoftAuthService(client: client, clientId: 'cid', delay: (_) async {}),
    nuvio: NuvioAuthService(client: client, baseUrl: 'https://site.invalid'),
    apiBase: 'https://site.invalid/',
  );
  return (controller, repo, secrets);
}

void main() {
  final offlineClient = MockClient((_) async => throw Exception('offline'));

  group('Account JSON', () {
    test('round-trips every field', () {
      final a = Account(
        id: 'nuvio-1',
        type: AccountType.nuvio,
        name: '[Nuvio]Steve',
        displayName: '[Nuvio] Steve',
        uuid: 'aabbccddeeff00112233445566778899',
        skinUrl: 'https://site.invalid/api/textures/x.png',
        model: 'slim',
        ownsJava: false,
        needsRelogin: true,
        lastRefresh: DateTime.utc(2026, 11, 1, 12),
      );
      final b = Account.fromJson(jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
      expect(b.id, a.id);
      expect(b.type, AccountType.nuvio);
      expect(b.name, a.name);
      expect(b.shownName, '[Nuvio] Steve');
      expect(b.uuid, a.uuid);
      expect(b.skinUrl, a.skinUrl);
      expect(b.model, 'slim');
      expect(b.ownsJava, isFalse);
      expect(b.needsRelogin, isTrue);
      expect(b.lastRefresh, a.lastRefresh);
    });

    test('secrets round-trip and tolerate garbage', () {
      final s = AccountSecrets(
        refreshToken: 'r',
        mcAccessToken: 'm',
        mcExpiresAt: DateTime.utc(2026, 1, 1),
        nuvioToken: 'n',
      );
      final back = AccountSecrets.fromJsonString(s.toJsonString());
      expect(back.refreshToken, 'r');
      expect(back.mcExpiresAt, DateTime.utc(2026, 1, 1));
      expect(AccountSecrets.fromJsonString('{bad').refreshToken, isNull);
    });

    test('repository keeps tokens out of shared preferences', () async {
      final (_, repo, secrets) = await _setup(offlineClient);
      await repo.save([Account.local('Steve')]);
      await repo.writeSecrets('x', const AccountSecrets(refreshToken: 'secret-rt'));
      expect(repo.load().single.name, 'Steve');
      expect((await repo.readSecrets('x')).refreshToken, 'secret-rt');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().any((k) => (prefs.get(k) ?? '').toString().contains('secret-rt')),
          isFalse);
      expect(secrets.data, isNotEmpty);
    });
  });

  group('LaunchAuth', () {
    test('local', () {
      final a = LaunchAuth.local(Account.local('Steve'));
      expect(a.userType, 'legacy');
      expect(a.accessToken, '0');
      expect(a.uuid.length, 32);
      expect(a.yggdrasilRoot, isNull);
    });

    test('microsoft', () {
      const acc = Account(
        id: 'ms-1',
        type: AccountType.microsoft,
        name: 'Alex',
        uuid: 'aabbccddeeff00112233445566778899',
      );
      final a = LaunchAuth.microsoft(acc, 'mc-token');
      expect(a.userType, 'msa');
      expect(a.accessToken, 'mc-token');
      expect(a.extraJvmArgs, isEmpty);
    });

    test('nuvio uses authlib-injector', () {
      const acc = Account(
        id: 'nuvio-1',
        type: AccountType.nuvio,
        name: '[Nuvio]Steve',
        uuid: 'aabbccddeeff00112233445566778899',
      );
      final a = LaunchAuth.nuvio(acc, 'tok', 'https://site.invalid/');
      expect(a.userType, 'mojang');
      expect(a.username, '[Nuvio]Steve');
      expect(a.yggdrasilRoot, 'https://site.invalid/api/yggdrasil');
      expect(a.extraJvmArgs, contains('-Dauthlibinjector.side=client'));
      expect(a.needsAuthlibInjector, isTrue);
    });
  });

  group('prepareForLaunch', () {
    test('no account selected', () async {
      final (c, _, _) = await _setup(offlineClient);
      await expectLater(
        c.prepareForLaunch(),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.noAccount)),
      );
    });

    test('local account works offline and validates names', () async {
      final (c, _, _) = await _setup(offlineClient);
      await expectLater(c.addLocal('ab'), throwsA(isA<AuthException>()));
      await c.addLocal('Steve_1');
      final auth = await c.prepareForLaunch();
      expect(auth.username, 'Steve_1');
      expect(auth.userType, 'legacy');
    });

    test('needs re-login is reported', () async {
      final (c, repo, _) = await _setup(offlineClient);
      await repo.save([
        const Account(
          id: 'ms-1',
          type: AccountType.microsoft,
          name: 'Alex',
          uuid: 'aa',
          needsRelogin: true,
        ),
      ]);
      await repo.saveSelectedId('ms-1');
      await c.init();
      await expectLater(
        c.prepareForLaunch(),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.needsRelogin)),
      );
    });

    test('Microsoft account without Java license is blocked', () async {
      final client = MockClient((req) async {
        final host = req.url.host;
        if (host == 'login.microsoftonline.com') {
          return _json({'access_token': 'ms', 'refresh_token': 'rt'});
        }
        if (host.endsWith('xboxlive.com')) {
          return _json({
            'Token': 't',
            'DisplayClaims': {
              'xui': [
                {'uhs': 'h'}
              ]
            },
          });
        }
        if (req.url.path.contains('login_with_xbox')) {
          return _json({'access_token': 'mc', 'expires_in': 86400});
        }
        return _json({'items': []});
      });
      final (c, repo, _) = await _setup(client);
      await repo.save([
        const Account(
          id: 'ms-1',
          type: AccountType.microsoft,
          name: 'Alex',
          uuid: 'aa',
          ownsJava: false,
        ),
      ]);
      await repo.saveSelectedId('ms-1');
      await repo.writeSecrets('ms-1', const AccountSecrets(refreshToken: 'rt'));
      await c.init();
      await expectLater(
        c.prepareForLaunch(),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.noJava)),
      );
    });

    test('Nuvio offline throws a network error; 401 marks needsRelogin', () async {
      final (c, repo, _) = await _setup(offlineClient);
      await repo.save([
        const Account(id: 'nuvio-1', type: AccountType.nuvio, name: '[Nuvio]S', uuid: 'aa'),
      ]);
      await repo.saveSelectedId('nuvio-1');
      await repo.writeSecrets('nuvio-1', const AccountSecrets(nuvioToken: 'tok'));
      await c.init();
      await expectLater(
        c.prepareForLaunch(),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.network)),
      );

      final (c2, repo2, _) =
          await _setup(MockClient((_) async => _json({'ok': false, 'code': 'TOKEN_INVALID'}, 401)));
      await repo2.save([
        const Account(id: 'nuvio-1', type: AccountType.nuvio, name: '[Nuvio]S', uuid: 'aa'),
      ]);
      await repo2.saveSelectedId('nuvio-1');
      await repo2.writeSecrets('nuvio-1', const AccountSecrets(nuvioToken: 'tok'));
      await c2.init();
      await expectLater(
        c2.prepareForLaunch(),
        throwsA(isA<AuthException>().having((e) => e.kind, 'kind', AuthErrorKind.needsRelogin)),
      );
      expect(c2.selected!.needsRelogin, isTrue);
    });
  });
}
