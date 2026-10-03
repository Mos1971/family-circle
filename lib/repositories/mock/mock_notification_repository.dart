import '../../models/app_notification.dart';
import '../notification_repository.dart';
import 'mock_backend.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._backend);

  final MockBackend _backend;

  @override
  List<AppNotification> getFor(String userId) => _backend.notifications
      .where((n) => n.userId == userId)
      .toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  int unreadCountFor(String userId) =>
      getFor(userId).where((n) => !n.read).length;

  @override
  void notify({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
  }) {
    _backend.notifications.insert(
      0,
      AppNotification(
        id: _backend.newId(),
        userId: userId,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    _backend.notificationChanges.add(null);
  }

  @override
  void notifyMany({
    required Iterable<String> userIds,
    required AppNotificationType type,
    required String title,
    required String body,
  }) {
    for (final id in userIds) {
      _backend.notifications.insert(
        0,
        AppNotification(
          id: _backend.newId(),
          userId: id,
          type: type,
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
      );
    }
    _backend.notificationChanges.add(null);
  }

  @override
  void markRead(String notificationId) {
    for (final n in _backend.notifications) {
      if (n.id == notificationId) {
        n.read = true;
        break;
      }
    }
    _backend.notificationChanges.add(null);
  }

  @override
  void markAllRead(String userId) {
    for (final n in _backend.notifications) {
      if (n.userId == userId) n.read = true;
    }
    _backend.notificationChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.notificationChanges.stream;
}
