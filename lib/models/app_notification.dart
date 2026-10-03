enum AppNotificationType {
  announcement,
  comment,
  reaction,
  community,
  message,
  event,
  todo,
}

/// An in-app notification. Real OS-level push (FCM) is deferred until a
/// Firebase project is wired up.
class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  String get emoji {
    switch (type) {
      case AppNotificationType.announcement:
        return '📢';
      case AppNotificationType.comment:
        return '💬';
      case AppNotificationType.reaction:
        return '❤️';
      case AppNotificationType.community:
        return '👋';
      case AppNotificationType.message:
        return '✉️';
      case AppNotificationType.event:
        return '📅';
      case AppNotificationType.todo:
        return '✅';
    }
  }
}
