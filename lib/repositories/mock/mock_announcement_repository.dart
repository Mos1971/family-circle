import '../../models/announcement.dart';
import '../../models/app_notification.dart';
import '../announcement_repository.dart';
import 'mock_backend.dart';

class MockAnnouncementRepository implements AnnouncementRepository {
  MockAnnouncementRepository(this._backend);

  final MockBackend _backend;

  @override
  List<Announcement> getAll() =>
      _backend.announcements.toList(growable: false)..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

  @override
  Announcement create({
    required String title,
    required String body,
    required String authorId,
    bool pinned = false,
  }) {
    final announcement = Announcement(
      id: _backend.newId(),
      title: title,
      body: body,
      authorId: authorId,
      createdAt: DateTime.now(),
      pinned: pinned,
    );
    _backend.announcements.insert(0, announcement);
    _backend.announcementChanges.add(null);

    for (final member in _backend.approvedMembers) {
      if (!_backend.prefsFor(member.id).announcementsOn) continue;
      _backend.notifications.insert(
        0,
        AppNotification(
          id: _backend.newId(),
          userId: member.id,
          type: AppNotificationType.announcement,
          title: '📢 Family Circle',
          body: title,
          createdAt: DateTime.now(),
        ),
      );
    }
    _backend.notificationChanges.add(null);
    return announcement;
  }

  @override
  void update(String id, {String? title, String? body}) {
    for (final a in _backend.announcements) {
      if (a.id == id) {
        if (title != null) a.title = title;
        if (body != null) a.body = body;
        break;
      }
    }
    _backend.announcementChanges.add(null);
  }

  @override
  void delete(String id) {
    _backend.announcements.removeWhere((a) => a.id == id);
    _backend.announcementChanges.add(null);
  }

  @override
  void setPinned(String id, bool pinned) {
    for (final a in _backend.announcements) {
      if (a.id == id) {
        a.pinned = pinned;
        break;
      }
    }
    _backend.announcementChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.announcementChanges.stream;
}
