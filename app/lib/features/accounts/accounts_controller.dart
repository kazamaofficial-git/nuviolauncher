import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/offline_uuid.dart';
import '../../data/models/account.dart';
import '../../data/models/account_secrets.dart';
import '../../data/models/auth_exception.dart';
import '../../data/models/device_code.dart';
import '../../data/models/launch_auth.dart';
import '../../data/models/ms_session.dart';
import '../../data/models/nuvio_profile.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/services/auth/device_poll.dart';
import '../../data/services/auth/microsoft_auth_service.dart';
import '../../data/services/auth/nuvio_auth_service.dart';

/// Derived state of an account, shown as a status chip.
enum AccountHealth { ok, checking, needsRelogin, noJava, noProfile, offline }

/// Holds all accounts, the selected one, and prepares auth for launching.
class AccountsController extends ChangeNotifier {
  AccountsController({
    required AccountRepository repository,
    required MicrosoftAuthService microsoft,
    required NuvioAuthService nuvio,
    String? apiBase,
    DateTime Function()? clock,
  })  : _repository = repository,
        _microsoft = microsoft,
        _nuvio = nuvio,
        _apiBase = apiBase ?? AppConstants.apiBase,
        _clock = clock ?? DateTime.now;

  static const Duration _refreshMargin = Duration(minutes: 5);

  final AccountRepository _repository;
  final MicrosoftAuthService _microsoft;
  final NuvioAuthService _nuvio;
  final String _apiBase;
  final DateTime Function() _clock;

  List<Account> _accounts = [];
  String? _selectedId;
  final Set<String> _busy = {};
  final Set<String> _offline = {};
  final Map<String, String> _errors = {};

  List<Account> get accounts => List.unmodifiable(_accounts);
  String? get selectedId => _selectedId;
  bool get microsoftConfigured => _microsoft.isConfigured;

  Account? get selected {
    for (final a in _accounts) {
      if (a.id == _selectedId) return a;
    }
    return null;
  }

  String? errorOf(String id) => _errors[id];

  AccountHealth healthOf(Account a) {
    if (_busy.contains(a.id)) return AccountHealth.checking;
    if (a.needsRelogin) return AccountHealth.needsRelogin;
    if (a.type == AccountType.microsoft) {
      if (!a.ownsJava) return AccountHealth.noJava;
      if (a.uuid.isEmpty) return AccountHealth.noProfile;
    }
    if (_offline.contains(a.id)) return AccountHealth.offline;
    return AccountHealth.ok;
  }

  // ------------------------------------------------------------------ init

  /// Loads stored accounts, then refreshes them in the background.
  Future<void> init() async {
    _accounts = _repository.load();
    final stored = _repository.loadSelectedId();
    _selectedId = _accounts.any((a) => a.id == stored)
        ? stored
        : (_accounts.isEmpty ? null : _accounts.first.id);
    notifyListeners();
    unawaited(refreshAll());
  }

  Future<void> refreshAll() async {
    for (final a in List<Account>.of(_accounts)) {
      if (a.type != AccountType.local) await refreshAccount(a.id);
    }
  }

  Account? _find(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> refreshAccount(String id) async {
    final acc = _find(id);
    if (acc == null || acc.type == AccountType.local || _busy.contains(id)) return;
    _busy.add(id);
    _errors.remove(id);
    notifyListeners();
    try {
      if (acc.type == AccountType.microsoft) {
        await _refreshMicrosoft(acc);
      } else {
        await _refreshNuvio(acc);
      }
      _offline.remove(id);
    } on AuthException catch (e) {
      await _handleRefreshError(id, e);
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }

  Future<void> _handleRefreshError(String id, AuthException e) async {
    if (e.kind == AuthErrorKind.needsRelogin) {
      _errors.remove(id);
      await _markRelogin(id);
    } else if (e.kind == AuthErrorKind.network) {
      _offline.add(id);
      _errors[id] = e.message;
    } else {
      _errors[id] = e.message;
    }
  }

  Future<void> _markRelogin(String id) async {
    final a = _find(id);
    if (a != null && !a.needsRelogin) await _put(a.copyWith(needsRelogin: true));
  }

  // ---------------------------------------------------------------- adding

  /// Device-code sign-in with Microsoft. [onCode] receives the code to display.
  Future<Account> addMicrosoft({
    required void Function(DeviceCode code) onCode,
    AuthCancelToken? cancel,
  }) async {
    final code = await _microsoft.startDeviceCode();
    onCode(code);
    final tokens = await _microsoft.waitForApproval(code, cancel: cancel);
    final session = await _microsoft.authenticate(tokens);
    if (cancel?.isCancelled ?? false) throw const AuthException.cancelled();
    final profile = session.profile;
    final id = 'ms-${profile?.id ?? session.xboxUserHash}';
    await _repository.writeSecrets(
      id,
      AccountSecrets(
        refreshToken: session.refreshToken,
        mcAccessToken: session.mcAccessToken,
        mcExpiresAt: session.mcExpiresAt,
      ),
    );
    final account = _fromSession(id, session, _find(id));
    await _upsert(account);
    return account;
  }

  /// Device link with the Nuvio website.
  Future<Account> addNuvio({
    required void Function(DeviceCode code) onCode,
    AuthCancelToken? cancel,
  }) async {
    final code = await _nuvio.start();
    onCode(code);
    final result = await _nuvio.waitForApproval(code, cancel: cancel);
    final profile = result.profile!;
    final id = 'nuvio-${profile.id}';
    await _repository.writeSecrets(id, AccountSecrets(nuvioToken: result.accessToken));
    final account = _fromNuvio(id, profile);
    await _upsert(account);
    return account;
  }

  /// Offline account; the username must be 3-16 letters, digits or underscore.
  Future<Account> addLocal(String username) async {
    final name = username.trim();
    if (!isValidUsername(name)) {
      throw const AuthException(
        AuthErrorKind.failed,
        'Username must be 3-16 characters: letters, digits or underscore.',
      );
    }
    final account = Account.local(name);
    await _upsert(account);
    return account;
  }

  Future<void> _upsert(Account account) async {
    final i = _accounts.indexWhere((a) => a.id == account.id);
    final next = List<Account>.of(_accounts);
    if (i >= 0) {
      next[i] = account;
    } else {
      next.add(account);
    }
    _accounts = next;
    _selectedId = account.id;
    _offline.remove(account.id);
    _errors.remove(account.id);
    await _repository.save(_accounts);
    await _repository.saveSelectedId(_selectedId);
    notifyListeners();
  }

  Future<void> _put(Account account) async {
    final i = _accounts.indexWhere((a) => a.id == account.id);
    if (i < 0) return;
    final next = List<Account>.of(_accounts);
    next[i] = account;
    _accounts = next;
    await _repository.save(_accounts);
    notifyListeners();
  }

  Account _fromSession(String id, MsSession s, Account? previous) {
    final p = s.profile;
    return Account(
      id: id,
      type: AccountType.microsoft,
      name: p?.name ?? previous?.name ?? 'Microsoft account',
      uuid: p?.id ?? previous?.uuid ?? '',
      skinUrl: p?.skinUrl ?? previous?.skinUrl,
      model: p?.model ?? previous?.model ?? 'classic',
      ownsJava: s.ownsJava,
      needsRelogin: false,
      lastRefresh: _clock(),
    );
  }

  Account _fromNuvio(String id, NuvioProfile p) => Account(
        id: id,
        type: AccountType.nuvio,
        name: p.name,
        displayName: p.displayName,
        uuid: p.id,
        skinUrl: p.skinUrl,
        model: p.model,
        needsRelogin: false,
        lastRefresh: _clock(),
      );

  // ------------------------------------------------------ select / remove

  Future<void> select(String id) async {
    if (_find(id) == null || _selectedId == id) return;
    _selectedId = id;
    notifyListeners();
    await _repository.saveSelectedId(id);
  }

  Future<void> remove(String id) async {
    final acc = _find(id);
    if (acc == null) return;
    if (acc.type == AccountType.nuvio) {
      final token = (await _repository.readSecrets(id)).nuvioToken;
      if (token != null && token.isNotEmpty) {
        try {
          await _nuvio.logout(token);
        } catch (_) {
          // Best effort: the account is removed locally either way.
        }
      }
    }
    await _repository.deleteSecrets(id);
    _accounts = _accounts.where((a) => a.id != id).toList();
    _offline.remove(id);
    _errors.remove(id);
    if (_selectedId == id) {
      _selectedId = _accounts.isEmpty ? null : _accounts.first.id;
      await _repository.saveSelectedId(_selectedId);
    }
    await _repository.save(_accounts);
    notifyListeners();
  }

  // ---------------------------------------------------------------- launch

  /// Validates/refreshes the selected account and returns launch credentials.
  /// Throws [AuthException] with a user-facing message when launching is impossible.
  Future<LaunchAuth> prepareForLaunch() async {
    final acc = selected;
    if (acc == null) {
      throw const AuthException(
        AuthErrorKind.noAccount,
        'No account selected. Open Accounts and add or select one before playing.',
      );
    }
    switch (acc.type) {
      case AccountType.local:
        return LaunchAuth.local(acc);
      case AccountType.microsoft:
        return _prepareMicrosoft(acc);
      case AccountType.nuvio:
        return _prepareNuvio(acc);
    }
  }

  Future<LaunchAuth> _prepareMicrosoft(Account acc) async {
    if (acc.needsRelogin) throw const AuthException.needsRelogin();
    var secrets = await _repository.readSecrets(acc.id);
    var token = secrets.mcAccessToken;
    var expiry = secrets.mcExpiresAt;
    var refresh = !acc.ownsJava ||
        token == null ||
        token.isEmpty ||
        expiry == null ||
        expiry.difference(_clock()) < _refreshMargin;

    if (!refresh) {
      try {
        if (!await _microsoft.isTokenValid(token!)) refresh = true;
      } on AuthException catch (e) {
        if (e.kind != AuthErrorKind.network) rethrow;
        // Offline with a still-valid token: launch with the stored one.
      }
    }

    if (refresh) {
      try {
        await _refreshMicrosoft(acc);
        secrets = await _repository.readSecrets(acc.id);
        token = secrets.mcAccessToken;
        expiry = secrets.mcExpiresAt;
      } on AuthException catch (e) {
        if (e.kind == AuthErrorKind.needsRelogin) {
          await _markRelogin(acc.id);
          rethrow;
        }
        final stillValid = e.kind == AuthErrorKind.network &&
            acc.ownsJava &&
            token != null &&
            expiry != null &&
            expiry.isAfter(_clock());
        if (!stillValid) rethrow;
      }
    }

    final account = _find(acc.id) ?? acc;
    if (account.needsRelogin) throw const AuthException.needsRelogin();
    if (!account.ownsJava) {
      throw const AuthException(
        AuthErrorKind.noJava,
        'This Microsoft account has no Minecraft Java Edition license, so it cannot launch the game. '
        'Select another account or buy Java Edition. / Akun ini tidak punya lisensi Minecraft Java Edition.',
      );
    }
    if (account.uuid.isEmpty || token == null || token.isEmpty) {
      throw const AuthException(
        AuthErrorKind.noProfile,
        'This account has no Minecraft profile yet. Create one at minecraft.net, then refresh the account.',
      );
    }
    return LaunchAuth.microsoft(account, token);
  }

  Future<LaunchAuth> _prepareNuvio(Account acc) async {
    if (acc.needsRelogin) throw const AuthException.needsRelogin();
    final token = (await _repository.readSecrets(acc.id)).nuvioToken;
    if (token == null || token.isEmpty) {
      await _markRelogin(acc.id);
      throw const AuthException.needsRelogin();
    }
    final NuvioProfile profile;
    try {
      profile = await _nuvio.me(token);
    } on AuthException catch (e) {
      if (e.kind == AuthErrorKind.needsRelogin) await _markRelogin(acc.id);
      rethrow;
    }
    final account = _fromNuvio(acc.id, profile);
    await _put(account);
    return LaunchAuth.nuvio(account, token, _apiBase);
  }

  // ------------------------------------------------------------- refreshing

  Future<void> _refreshMicrosoft(Account acc) async {
    final secrets = await _repository.readSecrets(acc.id);
    final rt = secrets.refreshToken;
    if (rt == null || rt.isEmpty) throw const AuthException.needsRelogin();
    final session = await _microsoft.refresh(rt);
    await _repository.writeSecrets(
      acc.id,
      secrets.copyWith(
        refreshToken: session.refreshToken.isEmpty ? rt : session.refreshToken,
        mcAccessToken: session.mcAccessToken,
        mcExpiresAt: session.mcExpiresAt,
      ),
    );
    await _put(_fromSession(acc.id, session, acc));
  }

  Future<void> _refreshNuvio(Account acc) async {
    final token = (await _repository.readSecrets(acc.id)).nuvioToken;
    if (token == null || token.isEmpty) throw const AuthException.needsRelogin();
    final profile = await _nuvio.me(token);
    await _put(_fromNuvio(acc.id, profile));
  }
}
