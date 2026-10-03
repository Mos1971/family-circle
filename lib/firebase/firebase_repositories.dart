import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../models/app_notification.dart';
import '../models/calendar_event.dart';
import '../models/comment.dart';
import '../models/direct_message.dart';
import '../models/notification_prefs.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/report.dart';
import '../models/todo.dart';
import '../models/user.dart';
import '../repositories/admin_repository.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/feed_repository.dart';
import '../repositories/message_repository.dart';
import '../repositories/notification_prefs_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/plan_repository.dart';
import '../repositories/user_repository.dart';
import 'codec.dart';
import 'firebase_backend.dart';

/// Fire-and-forget Firestore write that logs instead of throwing, so a
/// rejected write (e.g. by security rules) can't crash the UI.
void _write(Future<void> future, String what) {
  future.then<void>(
    (_) {},
    onError: (Object e) => debugPrint('Firestore write failed ($what): $e'),
  );
}

String _friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address doesn\'t look right.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account with that email already exists. Try logging in.';
    case 'weak-password':
      return 'Please choose a longer password (at least 6 characters).';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    default:
      return e.message ?? 'Something went wrong. Please try again.';
  }
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._b);
  final FirebaseBackend _b;

  @override
  AppUser? get currentUser => _b.currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _b.authChanges.stream;

  @override
  Future<AppUser> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
    required String verificationNote,
  }) async {
    try {
      return await _b.register(
        firstName: firstName,
        familyName: familyName,
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _b.login(email, password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  @override
  Future<void> logout() => _b.logout();

  @override
  Future<AppUser> loginAsDemo(String userId) =>
      throw UnsupportedError('Demo login is only available in mock mode.');
}

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository(this._b);
  final FirebaseBackend _b;

  DocumentReference<Json> _doc(String id) => _b.db.collection('users').doc(id);

  @override
  List<AppUser> getAll() => List.unmodifiable(_b.users);

  @override
  AppUser? getById(String id) => _b.userById(id);

  @override
  List<AppUser> getPendingApproval() => _b.users
      .where((u) => u.status == MemberStatus.pending)
      .toList(growable: false);

  @override
  void approve(String userId) {
    final user = _b.userById(userId);
    if (user == null) return;
    _write(_doc(userId).update({'status': 'approved'}), 'approve');

    // Welcome post on the feed, authored as the new member.
    final family = user.familyName.isEmpty ? '' : ' (${user.familyName})';
    final post = Post(
      id: '',
      authorId: userId,
      text: '👋 Welcome to Family Circle, ${user.firstName}$family!',
      createdAt: DateTime.now(),
      type: PostType.welcome,
    );
    _write(_b.db.collection('posts').add(postToMap(post)), 'welcome post');

    for (final m in _b.approvedMembers) {
      if (m.id == userId || !_b.prefsFor(m.id).communityOn) continue;
      _b.notify(
        userId: m.id,
        type: AppNotificationType.community,
        title: 'New member 👋',
        body: '${user.firstName} just joined Family Circle.',
      );
    }
  }

  @override
  void reject(String userId) =>
      _write(_doc(userId).update({'status': 'rejected'}), 'reject');

  // Profiles can't be deleted (rules), so removal = rejected status, which
  // locks the person out of everything.
  @override
  void remove(String userId) => reject(userId);

  @override
  void updateProfile(String userId, {String? bio}) {
    if (bio == null) return;
    _write(_doc(userId).update({'bio': bio}), 'profile');
  }

  @override
  List<AppUser> getAdmins() =>
      _b.users.where((u) => u.isAdmin).toList(growable: false);

  @override
  bool promoteToAdmin(String userId) {
    final user = _b.userById(userId);
    if (user == null || user.isAdmin) return false;
    if (getAdmins().length >= kMaxAdmins) return false;
    _write(_doc(userId).update({'role': 'admin'}), 'promote');
    _b.notify(
      userId: userId,
      type: AppNotificationType.community,
      title: '🛡️ You\'re now a Family Circle admin',
      body:
          'You\'ve been made an admin of Family Circle. You can now '
          'moderate the feed, post announcements and approve new members '
          'from the admin dashboard.',
    );
    return true;
  }

  @override
  void demoteToMember(String userId) {
    final user = _b.userById(userId);
    if (user == null || !user.isAdmin) return;
    if (getAdmins().length <= 1) return;
    _write(_doc(userId).update({'role': 'member'}), 'demote');
  }

  @override
  Stream<void> get changes => _b.userChanges.stream;
}

class FirebaseFeedRepository implements FeedRepository {
  FirebaseFeedRepository(this._b);
  final FirebaseBackend _b;

  @override
  List<Post> getPosts() => _b.posts.where((p) => !p.hidden).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Post? getPost(String id) {
    for (final p in _b.posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Post createPost({
    required String authorId,
    required String text,
    PostType type = PostType.normal,
  }) {
    final ref = _b.db.collection('posts').doc();
    final post = Post(
      id: ref.id,
      authorId: authorId,
      text: text,
      createdAt: DateTime.now(),
      type: type,
    );
    _write(ref.set(postToMap(post)), 'create post');
    _write(
      _b.db.collection('users').doc(authorId).update({
        'postCount': FieldValue.increment(1),
      }),
      'post count',
    );
    return post;
  }

  @override
  void deletePost(String postId, String requestingUserId) {
    final post = getPost(postId);
    if (post == null) return;
    final requester = _b.userById(requestingUserId);
    final allowed =
        post.authorId == requestingUserId || (requester?.isAdmin ?? false);
    if (!allowed) return;
    _write(_b.db.collection('posts').doc(postId).delete(), 'delete post');
    // Only admins may delete other people's comments, so tidy up for them.
    if (requester?.isAdmin ?? false) {
      for (final c in _b.comments.where((c) => c.postId == postId)) {
        _write(_b.db.collection('comments').doc(c.id).delete(), 'comment');
      }
    }
  }

  @override
  void toggleReaction(String postId, String userId, ReactionType type) {
    final post = getPost(postId);
    if (post == null) return;
    final already = post.reactions[type]!.contains(userId);
    // One reaction per member per post: remove from every type, then add to
    // the chosen one unless they were toggling it off.
    final update = <String, Object?>{
      for (final t in ReactionType.values)
        'reactions.${t.name}': (t == type && !already)
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
    };
    _write(
      _b.db.collection('posts').doc(postId).update(update),
      'reaction',
    );
    if (!already && post.authorId != userId) {
      final author = _b.userById(post.authorId);
      if (author != null && _b.prefsFor(author.id).reactionsOn) {
        _b.notify(
          userId: author.id,
          type: AppNotificationType.reaction,
          title: '${type.emoji} New reaction',
          body: 'Someone reacted "${type.label}" to your post.',
        );
      }
    }
  }

  @override
  List<Comment> getComments(String postId) =>
      _b.comments.where((c) => c.postId == postId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Comment addComment({
    required String postId,
    required String authorId,
    required String text,
    String? parentCommentId,
  }) {
    final ref = _b.db.collection('comments').doc();
    final comment = Comment(
      id: ref.id,
      postId: postId,
      authorId: authorId,
      text: text,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );
    _write(ref.set(commentToMap(comment)), 'comment');

    final post = getPost(postId);
    if (post != null && post.authorId != authorId) {
      final author = _b.userById(post.authorId);
      if (author != null && _b.prefsFor(author.id).commentsOn) {
        _b.notify(
          userId: author.id,
          type: AppNotificationType.comment,
          title: '💬 New comment',
          body: 'Someone commented on your post.',
        );
      }
    }
    return comment;
  }

  @override
  void reportPost(String postId, String reporterId) {
    _write(
      _b.db.collection('posts').doc(postId).update({
        'reportedCount': FieldValue.increment(1),
      }),
      'report count',
    );
    _addReport(ReportedContentType.post, postId, reporterId);
    _b.notifyAdmins(
      type: AppNotificationType.community,
      title: 'Post reported',
      body: 'A member has reported a post for review.',
    );
  }

  @override
  void reportComment(String commentId, String reporterId) {
    _addReport(ReportedContentType.comment, commentId, reporterId);
    _b.notifyAdmins(
      type: AppNotificationType.community,
      title: 'Comment reported',
      body: 'A member has reported a comment for review.',
    );
  }

  void _addReport(ReportedContentType type, String contentId, String by) {
    final report = ContentReport(
      id: '',
      contentType: type,
      contentId: contentId,
      reporterId: by,
      createdAt: DateTime.now(),
    );
    _write(_b.db.collection('reports').add(reportToMap(report)), 'report');
  }

  @override
  List<ContentReport> getOpenReports() =>
      _b.reports.where((r) => !r.resolved).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  void resolveReport(String reportId, {required bool removeContent}) {
    ContentReport? report;
    for (final r in _b.reports) {
      if (r.id == reportId) report = r;
    }
    if (report == null) return;
    _write(
      _b.db.collection('reports').doc(reportId).update({'resolved': true}),
      'resolve report',
    );
    if (!removeContent) return;
    if (report.contentType == ReportedContentType.post) {
      _write(
        _b.db.collection('posts').doc(report.contentId).delete(),
        'remove post',
      );
      for (final c in _b.comments.where((c) => c.postId == report!.contentId)) {
        _write(_b.db.collection('comments').doc(c.id).delete(), 'comment');
      }
    } else {
      _write(
        _b.db.collection('comments').doc(report.contentId).delete(),
        'remove comment',
      );
    }
  }

  @override
  Stream<void> get changes => _b.feedChanges.stream;
}

class FirebaseAnnouncementRepository implements AnnouncementRepository {
  FirebaseAnnouncementRepository(this._b);
  final FirebaseBackend _b;

  DocumentReference<Json> _doc(String id) =>
      _b.db.collection('announcements').doc(id);

  @override
  List<Announcement> getAll() => _b.announcements.toList()
    ..sort((a, b) {
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
    final ref = _b.db.collection('announcements').doc();
    final a = Announcement(
      id: ref.id,
      title: title,
      body: body,
      authorId: authorId,
      createdAt: DateTime.now(),
      pinned: pinned,
    );
    _write(ref.set(announcementToMap(a)), 'announcement');
    for (final m in _b.approvedMembers) {
      if (m.id == authorId || !_b.prefsFor(m.id).announcementsOn) continue;
      _b.notify(
        userId: m.id,
        type: AppNotificationType.announcement,
        title: '📢 Family Circle',
        body: title,
      );
    }
    return a;
  }

  @override
  void update(String id, {String? title, String? body}) => _write(
    _doc(id).update({
      if (title != null) 'title': title,
      if (body != null) 'body': body,
    }),
    'announcement update',
  );

  @override
  void delete(String id) => _write(_doc(id).delete(), 'announcement delete');

  @override
  void setPinned(String id, bool pinned) =>
      _write(_doc(id).update({'pinned': pinned}), 'pin');

  @override
  Stream<void> get changes => _b.announcementChanges.stream;
}

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository(this._b);
  final FirebaseBackend _b;

  @override
  List<AppNotification> getFor(String userId) =>
      _b.notifications.where((n) => n.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  int unreadCountFor(String userId) =>
      getFor(userId).where((n) => !n.read).length;

  @override
  void notify({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
  }) => _b.notify(userId: userId, type: type, title: title, body: body);

  @override
  void notifyMany({
    required Iterable<String> userIds,
    required AppNotificationType type,
    required String title,
    required String body,
  }) {
    for (final id in userIds) {
      _b.notify(userId: id, type: type, title: title, body: body);
    }
  }

  @override
  void markRead(String notificationId) => _write(
    _b.db.collection('notifications').doc(notificationId).update({
      'read': true,
    }),
    'mark read',
  );

  @override
  void markAllRead(String userId) {
    final batch = _b.db.batch();
    var any = false;
    for (final n in getFor(userId).where((n) => !n.read)) {
      batch.update(_b.db.collection('notifications').doc(n.id), {'read': true});
      any = true;
    }
    if (any) _write(batch.commit(), 'mark all read');
  }

  @override
  Stream<void> get changes => _b.notificationChanges.stream;
}

class FirebaseNotificationPrefsRepository
    implements NotificationPrefsRepository {
  FirebaseNotificationPrefsRepository(this._b);
  final FirebaseBackend _b;

  @override
  NotificationPrefs getFor(String userId) => _b.prefsFor(userId);

  @override
  void update(String userId, void Function(NotificationPrefs prefs) mutate) {
    final prefs = _b.prefsFor(userId);
    mutate(prefs);
    _b.notificationChanges.add(null);
    _write(
      _b.db.collection('users').doc(userId).update({
        'prefs': prefsToMap(prefs),
      }),
      'prefs',
    );
  }

  @override
  Stream<void> get changes => _b.notificationChanges.stream;
}

class FirebaseAdminRepository implements AdminRepository {
  FirebaseAdminRepository(this._b);
  final FirebaseBackend _b;

  @override
  FamilyStats getStats() => FamilyStats(
    approvedMemberCount: _b.users
        .where((u) => u.status == MemberStatus.approved)
        .length,
    pendingMemberCount: _b.users
        .where((u) => u.status == MemberStatus.pending)
        .length,
    postCount: _b.posts.where((p) => !p.hidden).length,
    openReportCount: _b.reports.where((r) => !r.resolved).length,
  );
}

class FirebaseMessageRepository implements MessageRepository {
  FirebaseMessageRepository(this._b);
  final FirebaseBackend _b;

  @override
  List<ConversationSummary> getConversations(String userId) {
    final byOther = <String, List<DirectMessage>>{};
    for (final m in _b.directMessages) {
      if (!m.involves(userId)) continue;
      byOther.putIfAbsent(m.otherParty(userId), () => []).add(m);
    }
    final rows = byOther.entries.map((e) {
      final msgs = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return ConversationSummary(
        otherUserId: e.key,
        lastMessage: msgs.last,
        unreadCount: msgs
            .where((m) => m.recipientId == userId && !m.read)
            .length,
      );
    }).toList();
    rows.sort(
      (a, b) => b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt),
    );
    return rows;
  }

  @override
  List<DirectMessage> getThread(String userId, String otherUserId) =>
      _b.directMessages
          .where((m) => m.between(userId, otherUserId))
          .toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  DirectMessage send({
    required String senderId,
    required String recipientId,
    required String text,
  }) {
    final recipient = _b.userById(recipientId);
    if (recipient == null || recipient.status != MemberStatus.approved) {
      throw StateError('That member is not available to message.');
    }
    final ref = _b.db.collection('messages').doc();
    final message = DirectMessage(
      id: ref.id,
      senderId: senderId,
      recipientId: recipientId,
      text: text,
      createdAt: DateTime.now(),
    );
    _write(ref.set(messageToMap(message)), 'send message');

    if (_b.prefsFor(recipientId).messagesOn) {
      final sender = _b.userById(senderId);
      _b.notify(
        userId: recipientId,
        type: AppNotificationType.message,
        title: '✉️ ${sender?.firstName ?? 'Someone'} sent you a message',
        body: text,
      );
    }
    return message;
  }

  @override
  void markThreadRead(String userId, String otherUserId) {
    final unread = _b.directMessages.where(
      (m) => m.recipientId == userId && m.senderId == otherUserId && !m.read,
    );
    if (unread.isEmpty) return;
    final batch = _b.db.batch();
    for (final m in unread) {
      batch.update(_b.db.collection('messages').doc(m.id), {'read': true});
    }
    _write(batch.commit(), 'mark thread read');
  }

  @override
  int unreadCountFor(String userId) =>
      _b.directMessages.where((m) => m.recipientId == userId && !m.read).length;

  @override
  Stream<void> get changes => _b.messageChanges.stream;
}

class FirebaseCalendarRepository implements CalendarRepository {
  FirebaseCalendarRepository(this._b);
  final FirebaseBackend _b;

  DocumentReference<Json> _doc(String id) => _b.db.collection('events').doc(id);

  @override
  List<CalendarEvent> getShared() =>
      _b.events.where((e) => e.shared).toList(growable: false);

  @override
  List<CalendarEvent> getPrivate(String userId) => _b.events
      .where((e) => !e.shared && e.ownerId == userId)
      .toList(growable: false);

  @override
  CalendarEvent? getById(String id) {
    for (final e in _b.events) {
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
    final ref = _b.db.collection('events').doc();
    final event = CalendarEvent(
      id: ref.id,
      ownerId: ownerId,
      title: title,
      date: DateTime(date.year, date.month, date.day),
      minutesFromMidnight: minutesFromMidnight,
      notes: notes,
      shared: shared,
    );
    _write(ref.set(eventToMap(event)), 'add event');
    if (shared) _notifyFamily(event);
    return event;
  }

  void _notifyFamily(CalendarEvent event) {
    final owner = _b.userById(event.ownerId);
    for (final m in _b.approvedMembers) {
      if (m.id == event.ownerId || !_b.prefsFor(m.id).calendarOn) continue;
      _b.notify(
        userId: m.id,
        type: AppNotificationType.event,
        title: '📅 New family event',
        body: '${owner?.firstName ?? 'Someone'} added "${event.title}".',
      );
    }
  }

  @override
  void delete(String eventId, String requestingUserId) {
    final event = getById(eventId);
    if (event == null) return;
    final requester = _b.userById(requestingUserId);
    final allowed =
        event.ownerId == requestingUserId ||
        (event.shared && (requester?.isAdmin ?? false));
    if (!allowed) return;
    _write(_doc(eventId).delete(), 'delete event');
  }

  @override
  CalendarEvent copyToPrivate(String eventId, String userId) {
    final source = getById(eventId)!;
    for (final e in _b.events) {
      if (e.copiedFromId == eventId && e.ownerId == userId) return e;
    }
    final ref = _b.db.collection('events').doc();
    final copy = CalendarEvent(
      id: ref.id,
      ownerId: userId,
      title: source.title,
      date: source.date,
      minutesFromMidnight: source.minutesFromMidnight,
      notes: source.notes,
      copiedFromId: source.id,
    );
    _write(ref.set(eventToMap(copy)), 'copy event');
    return copy;
  }

  @override
  void shareToFamily(String eventId, String userId) {
    final e = getById(eventId);
    if (e == null || e.ownerId != userId || e.shared) return;
    _write(_doc(eventId).update({'shared': true}), 'share event');
    _notifyFamily(e);
  }

  @override
  void makePrivate(String eventId, String userId) {
    final e = getById(eventId);
    if (e == null || e.ownerId != userId) return;
    _write(_doc(eventId).update({'shared': false}), 'unshare event');
  }

  @override
  bool isCopiedToPrivate(String sharedEventId, String userId) => _b.events.any(
    (e) => e.copiedFromId == sharedEventId && e.ownerId == userId,
  );

  @override
  Stream<void> get changes => _b.calendarChanges.stream;
}

class FirebaseTodoRepository implements TodoRepository {
  FirebaseTodoRepository(this._b);
  final FirebaseBackend _b;

  DocumentReference<Json> _doc(String id) =>
      _b.db.collection('todoLists').doc(id);

  @override
  List<TodoList> getFor(String userId) =>
      _b.todoLists.where((l) => l.canView(userId)).toList().reversed.toList();

  @override
  TodoList? getById(String id) {
    for (final l in _b.todoLists) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  TodoList create({required String ownerId, required String title}) {
    final ref = _b.db.collection('todoLists').doc();
    final list = TodoList(id: ref.id, ownerId: ownerId, title: title);
    _write(ref.set(todoToMap(list)), 'create list');
    return list;
  }

  @override
  void delete(String listId, String requestingUserId) {
    final l = getById(listId);
    if (l == null || l.ownerId != requestingUserId) return;
    _write(_doc(listId).delete(), 'delete list');
  }

  @override
  void rename(String listId, String title) =>
      _write(_doc(listId).update({'title': title}), 'rename list');

  /// Items live in one array field, so edits are done in a transaction to
  /// avoid two people overwriting each other's changes.
  void _editItems(String listId, void Function(List<Map> items) edit) {
    _write(
      _b.db.runTransaction((tx) async {
        final snap = await tx.get(_doc(listId));
        if (!snap.exists) return;
        final items = List<Map>.from(
          (snap.data()!['items'] as List? ?? const []).map(
            (i) => Map.from(i as Map),
          ),
        );
        edit(items);
        tx.update(_doc(listId), {'items': items});
      }),
      'edit list items',
    );
  }

  @override
  TodoItem addItem(String listId, String text) {
    final item = TodoItem(id: _b.newId('todoLists'), text: text);
    _editItems(
      listId,
      (items) => items.add({'id': item.id, 'text': text, 'done': false}),
    );
    return item;
  }

  @override
  void toggleItem(String listId, String itemId) => _editItems(listId, (items) {
    for (final i in items) {
      if (i['id'] == itemId) i['done'] = !(i['done'] == true);
    }
  });

  @override
  void removeItem(String listId, String itemId) =>
      _editItems(listId, (items) => items.removeWhere((i) => i['id'] == itemId));

  @override
  void setSharedWith(String listId, String ownerId, Set<String> userIds) {
    final list = getById(listId);
    if (list == null || list.ownerId != ownerId) return;
    final shared = userIds.where((id) => id != ownerId).toSet();
    final added = shared.difference(list.sharedWith);
    _write(
      _doc(listId).update({
        'sharedWith': shared.toList(),
        'members': [ownerId, ...shared],
      }),
      'share list',
    );
    final owner = _b.userById(ownerId);
    for (final id in added) {
      if (!_b.prefsFor(id).listsOn) continue;
      _b.notify(
        userId: id,
        type: AppNotificationType.todo,
        title: '✅ List shared with you',
        body: '${owner?.firstName ?? 'Someone'} shared "${list.title}".',
      );
    }
  }

  @override
  Stream<void> get changes => _b.todoChanges.stream;
}
