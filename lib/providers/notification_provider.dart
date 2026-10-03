import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final NotificationRepository _repo;

  List<AppNotification> getFor(String userId) => _repo.getFor(userId);
  int unreadCountFor(String userId) => _repo.unreadCountFor(userId);
  void markRead(String id) => _repo.markRead(id);
  void markAllRead(String userId) => _repo.markAllRead(userId);
}
