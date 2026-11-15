/// A news item from `/api/announcements`.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;

  /// `info`, `warning` or `success`.
  final String level;
  final DateTime? createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        level: json['level'] as String? ?? 'info',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
