import 'dart:convert';

/// Per-account secrets, kept in the platform secure store only.
class AccountSecrets {
  const AccountSecrets({
    this.refreshToken,
    this.mcAccessToken,
    this.mcExpiresAt,
    this.nuvioToken,
  });

  factory AccountSecrets.fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const AccountSecrets();
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const AccountSecrets();
      return AccountSecrets(
        refreshToken: json['refreshToken'] as String?,
        mcAccessToken: json['mcAccessToken'] as String?,
        mcExpiresAt: DateTime.tryParse(json['mcExpiresAt'] as String? ?? ''),
        nuvioToken: json['nuvioToken'] as String?,
      );
    } on FormatException {
      return const AccountSecrets();
    }
  }

  /// Microsoft OAuth refresh token.
  final String? refreshToken;

  /// Minecraft Services access token and its expiry.
  final String? mcAccessToken;
  final DateTime? mcExpiresAt;

  /// Nuvio website access token.
  final String? nuvioToken;

  AccountSecrets copyWith({
    String? refreshToken,
    String? mcAccessToken,
    DateTime? mcExpiresAt,
    String? nuvioToken,
  }) =>
      AccountSecrets(
        refreshToken: refreshToken ?? this.refreshToken,
        mcAccessToken: mcAccessToken ?? this.mcAccessToken,
        mcExpiresAt: mcExpiresAt ?? this.mcExpiresAt,
        nuvioToken: nuvioToken ?? this.nuvioToken,
      );

  String toJsonString() => jsonEncode({
        'refreshToken': refreshToken,
        'mcAccessToken': mcAccessToken,
        'mcExpiresAt': mcExpiresAt?.toUtc().toIso8601String(),
        'nuvioToken': nuvioToken,
      });
}
