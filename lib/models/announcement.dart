class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.createdAt,
    this.pinned = false,
  });

  final String id;
  String title;
  String body;
  final String authorId;
  final DateTime createdAt;
  bool pinned;
}
