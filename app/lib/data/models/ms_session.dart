/// Minecraft profile returned by `/minecraft/profile`.
class McProfile {
  const McProfile({
    required this.id,
    required this.name,
    this.skinUrl,
    this.capeUrl,
    this.model = 'classic',
  });

  /// 32 hex characters, no dashes.
  final String id;
  final String name;
  final String? skinUrl;
  final String? capeUrl;

  /// `classic` or `slim`.
  final String model;
}

/// OAuth tokens from the Microsoft identity platform.
class MsTokens {
  const MsTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Result of a full Microsoft -> Xbox -> Minecraft sign-in.
class MsSession {
  const MsSession({
    required this.refreshToken,
    required this.mcAccessToken,
    required this.mcExpiresAt,
    required this.ownsJava,
    required this.xboxUserHash,
    this.profile,
  });

  final String refreshToken;
  final String mcAccessToken;
  final DateTime mcExpiresAt;

  /// False when the account has no Minecraft Java Edition entitlement.
  final bool ownsJava;

  /// Xbox user hash (stable per account, used as an id when there is no profile).
  final String xboxUserHash;

  /// Null when the account owns the game but has not created a profile yet.
  final McProfile? profile;
}
