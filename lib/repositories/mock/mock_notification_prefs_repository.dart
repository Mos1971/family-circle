import '../../models/notification_prefs.dart';
import '../notification_prefs_repository.dart';
import 'mock_backend.dart';

class MockNotificationPrefsRepository implements NotificationPrefsRepository {
  MockNotificationPrefsRepository(this._backend);

  final MockBackend _backend;

  @override
  NotificationPrefs getFor(String userId) => _backend.prefsFor(userId);

  @override
  void update(String userId, void Function(NotificationPrefs prefs) mutate) {
    mutate(_backend.prefsFor(userId));
    _backend.notificationChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.notificationChanges.stream;
}
