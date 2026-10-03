import '../models/notification_prefs.dart';

abstract class NotificationPrefsRepository {
  NotificationPrefs getFor(String userId);
  void update(String userId, void Function(NotificationPrefs prefs) mutate);
  Stream<void> get changes;
}
