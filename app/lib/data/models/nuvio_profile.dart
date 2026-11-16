/// Profile of a Nuvio website account (docs/ACCOUNTS.md, section "Profile").
class NuvioProfile {
  const NuvioProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.displayName,
    this.badge = true,
    this.model = 'classic',
    this.skinUrl,
    this.capeUrl,
  });

  factory NuvioProfile.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final name = json['name'] as String? ?? username;
    return NuvioProfile(
      id: json['id'] as String? ?? '',
      username: username,
      name: name,
      displayName: json['displayName'] as String? ?? username,
      badge: json['badge'] as bool? ?? true,
      model: json['model'] as String? ?? 'classic',
      skinUrl: json['skinUrl'] as String?,
      capeUrl: json['capeUrl'] as String?,
    );
  }

  final String id;
  final String username;

  /// In-game name, e.g. `Steve` (the badge is a logo, not text).
  final String name;

  /// UI name, e.g. `Steve`; the UI draws the Nuvio logo badge next to it.
  final String displayName;
  final bool badge;
  final String model;
  final String? skinUrl;
  final String? capeUrl;
}
