enum ReactionType { like, love, laugh, celebrate }

extension ReactionTypeX on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.celebrate:
        return '🎉';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.laugh:
        return 'Haha';
      case ReactionType.celebrate:
        return 'Celebrate';
    }
  }
}
