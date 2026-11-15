import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/account.dart';
import '../models/account_secrets.dart';
import '../services/secret_store.dart';

/// Persists accounts: public fields in SharedPreferences, tokens in the secure store.
class AccountRepository {
  AccountRepository({required SharedPreferences prefs, required SecretStore secrets})
      : _prefs = prefs,
        _secrets = secrets;

  final SharedPreferences _prefs;
  final SecretStore _secrets;

  String _secretKey(String id) => 'nuvio.secrets.$id';

  List<Account> load() {
    final raw = _prefs.getString(AppConstants.prefsAccounts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) Account.fromJson(e),
      ].where((a) => a.id.isNotEmpty).toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> save(List<Account> accounts) => _prefs.setString(
        AppConstants.prefsAccounts,
        jsonEncode([for (final a in accounts) a.toJson()]),
      );

  String? loadSelectedId() => _prefs.getString(AppConstants.prefsSelectedAccount);

  Future<void> saveSelectedId(String? id) async {
    if (id == null) {
      await _prefs.remove(AppConstants.prefsSelectedAccount);
    } else {
      await _prefs.setString(AppConstants.prefsSelectedAccount, id);
    }
  }

  Future<AccountSecrets> readSecrets(String id) async =>
      AccountSecrets.fromJsonString(await _secrets.read(_secretKey(id)));

  Future<void> writeSecrets(String id, AccountSecrets secrets) =>
      _secrets.write(_secretKey(id), secrets.toJsonString());

  Future<void> deleteSecrets(String id) => _secrets.delete(_secretKey(id));
}
