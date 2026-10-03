import 'reaction.dart';

enum PostType { normal, milestone, welcome }

class Post {
  Post({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.type = PostType.normal,
    Map<ReactionType, Set<String>>? reactions,
    this.reportedCount = 0,
    this.hidden = false,
  }) : reactions = reactions ?? {for (final r in ReactionType.values) r: <String>{}};

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final PostType type;
  final Map<ReactionType, Set<String>> reactions;
  int reportedCount;
  bool hidden;

  int get totalReactions =>
      reactions.values.fold(0, (sum, users) => sum + users.length);

  bool reactedByUser(String userId) =>
      reactions.values.any((users) => users.contains(userId));

  ReactionType? userReaction(String userId) {
    for (final entry in reactions.entries) {
      if (entry.value.contains(userId)) return entry.key;
    }
    return null;
  }
}
