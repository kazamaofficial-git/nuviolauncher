import '../../core/utils/offline_uuid.dart';

/// The three kinds of accounts the launcher supports (see docs/ACCOUNTS.md).
enum AccountType {
  microsoft,
  nuvio,
  local;

  static AccountType parse(Object? value) {
    for (final t in AccountType.values) {
      if (t.name == value) return t;
    }
    return AccountType.local;
  }
}

/// A stored account. Holds no secrets (tokens live in [AccountSecrets]).
class Account {
  const Account({
    required this.id,
    required this.type,
    required this.name,
    required this.uuid,
    this.displayName,
    this.skinUrl,
    this.model = 'classic',
    this.ownsJava = true,
    this.needsRelogin = false,
    this.lastRefresh,
  });

  /// Offline account: no network, no skin, offline UUID.
  factory Account.local(String username) {
    final uuid = offlineUuid(username).replaceAll('-', '');
    return Account(
      id: 'local-$uuid',
      type: AccountType.local,
      name: username,
      uuid: uuid,
    );
  }

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String? ?? '',
        type: AccountType.parse(json['type']),
        name: json['name'] as String? ?? '',
        displayName: json['displayName'] as String?,
        uuid: json['uuid'] as String? ?? '',
        skinUrl: json['skinUrl'] as String?,
        model: json['model'] as String? ?? 'classic',
        ownsJava: json['ownsJava'] as bool? ?? true,
        needsRelogin: json['needsRelogin'] as bool? ?? false,
        lastRefresh: DateTime.tryParse(json['lastRefresh'] as String? ?? ''),
      );

  final String id;
  final AccountType type;

  /// In-game name (what `--username` receives).
  final String name;

  /// Name shown in the UI when it differs from [name] (Nuvio: `[Nuvio] Steve`).
  final String? displayName;

  /// 32 hex characters, no dashes. Empty while a Microsoft account has no profile.
  final String uuid;
  final String? skinUrl;

  /// `classic` or `slim`.
  final String model;
  final bool ownsJava;
  final bool needsRelogin;
  final DateTime? lastRefresh;

  String get shownName => (displayName == null || displayName!.isEmpty) ? name : displayName!;

  Account copyWith({
    String? name,
    String? displayName,
    String? uuid,
    String? skinUrl,
    bool clearSkinUrl = false,
    String? model,
    bool? ownsJava,
    bool? needsRelogin,
    DateTime? lastRefresh,
  }) =>
      Account(
        id: id,
        type: type,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        uuid: uuid ?? this.uuid,
        skinUrl: clearSkinUrl ? null : (skinUrl ?? this.skinUrl),
        model: model ?? this.model,
        ownsJava: ownsJava ?? this.ownsJava,
        needsRelogin: needsRelogin ?? this.needsRelogin,
        lastRefresh: lastRefresh ?? this.lastRefresh,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'displayName': displayName,
        'uuid': uuid,
        'skinUrl': skinUrl,
        'model': model,
        'ownsJava': ownsJava,
        'needsRelogin': needsRelogin,
        'lastRefresh': lastRefresh?.toUtc().toIso8601String(),
      };
}
