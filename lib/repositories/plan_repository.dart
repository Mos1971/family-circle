import '../models/calendar_event.dart';
import '../models/todo.dart';

abstract class CalendarRepository {
  /// Every event on the family calendar.
  List<CalendarEvent> getShared();

  /// [userId]'s own private events.
  List<CalendarEvent> getPrivate(String userId);

  CalendarEvent? getById(String id);

  CalendarEvent add({
    required String ownerId,
    required String title,
    required DateTime date,
    int? minutesFromMidnight,
    String notes = '',
    required bool shared,
  });

  /// Only the owner (or an admin, for shared events) may delete.
  void delete(String eventId, String requestingUserId);

  /// Copies a family event onto [userId]'s private calendar.
  CalendarEvent copyToPrivate(String eventId, String userId);

  /// Publishes one of [userId]'s private events to the family calendar.
  void shareToFamily(String eventId, String userId);

  /// Pulls one of [userId]'s own shared events back to private.
  void makePrivate(String eventId, String userId);

  bool isCopiedToPrivate(String sharedEventId, String userId);

  Stream<void> get changes;
}

abstract class TodoRepository {
  /// Lists [userId] owns or that were shared with them, newest first.
  List<TodoList> getFor(String userId);
  TodoList? getById(String id);

  TodoList create({required String ownerId, required String title});
  void delete(String listId, String requestingUserId);
  void rename(String listId, String title);

  TodoItem addItem(String listId, String text);
  void toggleItem(String listId, String itemId);
  void removeItem(String listId, String itemId);

  /// Replaces the set of members the list is shared with (owner only).
  void setSharedWith(String listId, String ownerId, Set<String> userIds);

  Stream<void> get changes;
}
