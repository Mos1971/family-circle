import '../models/announcement.dart';

abstract class AnnouncementRepository {
  List<Announcement> getAll();
  Announcement create({
    required String title,
    required String body,
    required String authorId,
    bool pinned = false,
  });
  void update(String id, {String? title, String? body});
  void delete(String id);
  void setPinned(String id, bool pinned);
  Stream<void> get changes;
}
