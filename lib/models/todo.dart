class TodoItem {
  TodoItem({required this.id, required this.text, this.done = false});

  final String id;
  String text;
  bool done;
}

/// A to-do list. Private to its [ownerId] unless the owner adds people to
/// [sharedWith]; those members can then see it, tick items and add items,
/// but only the owner can delete the list or change who it's shared with.
class TodoList {
  TodoList({
    required this.id,
    required this.ownerId,
    required this.title,
    List<TodoItem>? items,
    Set<String>? sharedWith,
  }) : items = items ?? [],
       sharedWith = sharedWith ?? <String>{};

  final String id;
  final String ownerId;
  String title;
  final List<TodoItem> items;
  final Set<String> sharedWith;

  bool canView(String userId) => ownerId == userId || sharedWith.contains(userId);

  int get doneCount => items.where((i) => i.done).length;
}
