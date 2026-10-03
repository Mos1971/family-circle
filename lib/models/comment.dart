class Comment {
  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.parentCommentId,
  });

  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final String? parentCommentId;

  bool get isReply => parentCommentId != null;
}
