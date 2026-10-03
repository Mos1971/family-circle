import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';
import '../models/todo.dart';
import '../repositories/plan_repository.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final CalendarRepository _repo;

  /// "My calendar" can overlay the family calendar so everything shows in one
  /// place. Kept here so the choice survives tab switches.
  bool overlayFamily = true;

  void setOverlayFamily(bool v) {
    overlayFamily = v;
    notifyListeners();
  }

  List<CalendarEvent> getShared() => _repo.getShared();
  List<CalendarEvent> getPrivate(String userId) => _repo.getPrivate(userId);
  CalendarEvent? getById(String id) => _repo.getById(id);

  /// Events on [day], sorted all-day first then by time.
  List<CalendarEvent> onDay(List<CalendarEvent> events, DateTime day) {
    final list = events
        .where(
          (e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day,
        )
        .toList();
    list.sort(
      (a, b) => (a.minutesFromMidnight ?? -1).compareTo(
        b.minutesFromMidnight ?? -1,
      ),
    );
    return list;
  }

  CalendarEvent add({
    required String ownerId,
    required String title,
    required DateTime date,
    int? minutesFromMidnight,
    String notes = '',
    required bool shared,
  }) => _repo.add(
    ownerId: ownerId,
    title: title,
    date: date,
    minutesFromMidnight: minutesFromMidnight,
    notes: notes,
    shared: shared,
  );

  void delete(String eventId, String userId) => _repo.delete(eventId, userId);
  CalendarEvent copyToPrivate(String eventId, String userId) =>
      _repo.copyToPrivate(eventId, userId);
  void shareToFamily(String eventId, String userId) =>
      _repo.shareToFamily(eventId, userId);
  void makePrivate(String eventId, String userId) =>
      _repo.makePrivate(eventId, userId);
  bool isCopiedToPrivate(String id, String userId) =>
      _repo.isCopiedToPrivate(id, userId);
}

class TodoProvider extends ChangeNotifier {
  TodoProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final TodoRepository _repo;

  List<TodoList> getFor(String userId) => _repo.getFor(userId);
  TodoList? getById(String id) => _repo.getById(id);

  TodoList create({required String ownerId, required String title}) =>
      _repo.create(ownerId: ownerId, title: title);
  void delete(String listId, String userId) => _repo.delete(listId, userId);
  void rename(String listId, String title) => _repo.rename(listId, title);

  TodoItem addItem(String listId, String text) => _repo.addItem(listId, text);
  void toggleItem(String listId, String itemId) =>
      _repo.toggleItem(listId, itemId);
  void removeItem(String listId, String itemId) =>
      _repo.removeItem(listId, itemId);

  void setSharedWith(String listId, String ownerId, Set<String> ids) =>
      _repo.setSharedWith(listId, ownerId, ids);
}
