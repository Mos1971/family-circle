import '../../models/app_notification.dart';
import '../../models/calendar_event.dart';
import '../../models/todo.dart';
import '../plan_repository.dart';
import 'mock_backend.dart';

class MockCalendarRepository implements CalendarRepository {
  MockCalendarRepository(this._backend);

  final MockBackend _backend;

  @override
  List<CalendarEvent> getShared() =>
      _backend.events.where((e) => e.shared).toList(growable: false);

  @override
  List<CalendarEvent> getPrivate(String userId) => _backend.events
      .where((e) => !e.shared && e.ownerId == userId)
      .toList(growable: false);

  @override
  CalendarEvent? getById(String id) {
    for (final e in _backend.events) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  CalendarEvent add({
    required String ownerId,
    required String title,
    required DateTime date,
    int? minutesFromMidnight,
    String notes = '',
    required bool shared,
  }) {
    final event = CalendarEvent(
      id: _backend.newId(),
      ownerId: ownerId,
      title: title,
      date: DateTime(date.year, date.month, date.day),
      minutesFromMidnight: minutesFromMidnight,
      notes: notes,
      shared: shared,
    );
    _backend.events.add(event);
    if (shared) _notifyFamilyOfEvent(event);
    _backend.calendarChanges.add(null);
    return event;
  }

  void _notifyFamilyOfEvent(CalendarEvent event) {
    final owner = _backend.userById(event.ownerId);
    for (final m in _backend.approvedMembers) {
      if (m.id == event.ownerId || !_backend.prefsFor(m.id).calendarOn) {
        continue;
      }
      _backend.notifications.insert(
        0,
        AppNotification(
          id: _backend.newId(),
          userId: m.id,
          type: AppNotificationType.event,
          title: '📅 New family event',
          body: '${owner?.firstName ?? 'Someone'} added "${event.title}".',
          createdAt: DateTime.now(),
        ),
      );
    }
    _backend.notificationChanges.add(null);
  }

  @override
  void delete(String eventId, String requestingUserId) {
    final event = getById(eventId);
    if (event == null) return;
    final requester = _backend.userById(requestingUserId);
    final allowed =
        event.ownerId == requestingUserId ||
        (event.shared && (requester?.isAdmin ?? false));
    if (!allowed) return;
    _backend.events.removeWhere((e) => e.id == eventId);
    _backend.calendarChanges.add(null);
  }

  @override
  CalendarEvent copyToPrivate(String eventId, String userId) {
    final source = getById(eventId)!;
    final existing = _backend.events.where(
      (e) => e.copiedFromId == eventId && e.ownerId == userId,
    );
    if (existing.isNotEmpty) return existing.first;
    final copy = CalendarEvent(
      id: _backend.newId(),
      ownerId: userId,
      title: source.title,
      date: source.date,
      minutesFromMidnight: source.minutesFromMidnight,
      notes: source.notes,
      copiedFromId: source.id,
    );
    _backend.events.add(copy);
    _backend.calendarChanges.add(null);
    return copy;
  }

  @override
  void shareToFamily(String eventId, String userId) {
    final e = getById(eventId);
    if (e == null || e.ownerId != userId || e.shared) return;
    e.shared = true;
    _notifyFamilyOfEvent(e);
    _backend.calendarChanges.add(null);
  }

  @override
  void makePrivate(String eventId, String userId) {
    final e = getById(eventId);
    if (e == null || e.ownerId != userId) return;
    e.shared = false;
    _backend.calendarChanges.add(null);
  }

  @override
  bool isCopiedToPrivate(String sharedEventId, String userId) =>
      _backend.events.any(
        (e) => e.copiedFromId == sharedEventId && e.ownerId == userId,
      );

  @override
  Stream<void> get changes => _backend.calendarChanges.stream;
}

class MockTodoRepository implements TodoRepository {
  MockTodoRepository(this._backend);

  final MockBackend _backend;

  @override
  List<TodoList> getFor(String userId) => _backend.todoLists
      .where((l) => l.canView(userId))
      .toList(growable: false)
      .reversed
      .toList(growable: false);

  @override
  TodoList? getById(String id) {
    for (final l in _backend.todoLists) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  TodoList create({required String ownerId, required String title}) {
    final list = TodoList(id: _backend.newId(), ownerId: ownerId, title: title);
    _backend.todoLists.add(list);
    _backend.todoChanges.add(null);
    return list;
  }

  @override
  void delete(String listId, String requestingUserId) {
    final l = getById(listId);
    if (l == null || l.ownerId != requestingUserId) return;
    _backend.todoLists.removeWhere((x) => x.id == listId);
    _backend.todoChanges.add(null);
  }

  @override
  void rename(String listId, String title) {
    getById(listId)?.title = title;
    _backend.todoChanges.add(null);
  }

  @override
  TodoItem addItem(String listId, String text) {
    final item = TodoItem(id: _backend.newId(), text: text);
    getById(listId)?.items.add(item);
    _backend.todoChanges.add(null);
    return item;
  }

  @override
  void toggleItem(String listId, String itemId) {
    final list = getById(listId);
    if (list == null) return;
    for (final i in list.items) {
      if (i.id == itemId) i.done = !i.done;
    }
    _backend.todoChanges.add(null);
  }

  @override
  void removeItem(String listId, String itemId) {
    getById(listId)?.items.removeWhere((i) => i.id == itemId);
    _backend.todoChanges.add(null);
  }

  @override
  void setSharedWith(String listId, String ownerId, Set<String> userIds) {
    final list = getById(listId);
    if (list == null || list.ownerId != ownerId) return;
    final added = userIds.difference(list.sharedWith);
    list.sharedWith
      ..clear()
      ..addAll(userIds.where((id) => id != ownerId));
    final owner = _backend.userById(ownerId);
    for (final id in added) {
      if (!_backend.prefsFor(id).listsOn) continue;
      _backend.notifications.insert(
        0,
        AppNotification(
          id: _backend.newId(),
          userId: id,
          type: AppNotificationType.todo,
          title: '✅ List shared with you',
          body: '${owner?.firstName ?? 'Someone'} shared "${list.title}".',
          createdAt: DateTime.now(),
        ),
      );
    }
    _backend.notificationChanges.add(null);
    _backend.todoChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.todoChanges.stream;
}
