import '../models/app_notification.dart';

/// Fans out in-app "push" notifications. A future PushNotificationGateway
/// (FCM) would be called alongside [notify]/[notifyMany] once a Firebase
/// project exists, without changing any call sites.
abstract class NotificationRepository {
  List<AppNotification> getFor(String userId);
  int unreadCountFor(String userId);
  void notify({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
  });
  void notifyMany({
    required Iterable<String> userIds,
    required AppNotificationType type,
    required String title,
    required String body,
  });
  void markRead(String notificationId);
  void markAllRead(String userId);
  Stream<void> get changes;
}
