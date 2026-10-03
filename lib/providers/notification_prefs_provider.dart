import 'package:flutter/foundation.dart';

import '../models/notification_prefs.dart';
import '../repositories/notification_prefs_repository.dart';

class NotificationPrefsProvider extends ChangeNotifier {
  NotificationPrefsProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final NotificationPrefsRepository _repo;

  NotificationPrefs getFor(String userId) => _repo.getFor(userId);

  void update(String userId, void Function(NotificationPrefs prefs) mutate) {
    _repo.update(userId, mutate);
  }
}
