import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementProvider extends ChangeNotifier {
  AnnouncementProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final AnnouncementRepository _repo;

  List<Announcement> getAll() => _repo.getAll();

  Announcement create({
    required String title,
    required String body,
    required String authorId,
    bool pinned = false,
  }) => _repo.create(title: title, body: body, authorId: authorId, pinned: pinned);

  void update(String id, {String? title, String? body}) =>
      _repo.update(id, title: title, body: body);

  void delete(String id) => _repo.delete(id);

  void setPinned(String id, bool pinned) => _repo.setPinned(id, pinned);
}
