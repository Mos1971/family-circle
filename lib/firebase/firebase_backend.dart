import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../models/app_notification.dart';
import '../models/calendar_event.dart';
import '../models/comment.dart';
import '../models/direct_message.dart';
import '../models/notification_prefs.dart';
import '../models/post.dart';
import '../models/report.dart';
import '../models/todo.dart';
import '../models/user.dart';
import 'codec.dart';
import 'firebase_options.dart';

typedef Json = Map<String, dynamic>;

/// Live Firestore data mirrored into in-memory lists.
///
/// The repositories are synchronous (they were written against an in-memory
/// store), so this class listens to Firestore and keeps the same shape of
/// data in memory; repositories read from here and write straight to
/// Firestore. Firestore's local write cache makes our own writes show up in
/// the listeners immediately, so the UI feels instant.
///
/// Security is enforced by `firestore.rules`, not by this class.
class FirebaseBackend {
  FirebaseBackend._();

  static Future<FirebaseBackend> create() async {
    await Firebase.initializeApp(options: firebaseOptions);
    final backend = FirebaseBackend._();
    await backend._start();
    return backend;
  }

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ---- Cached data --------------------------------------------------------
  final List<AppUser> users = [];
  final List<Post> posts = [];
  final List<Comment> comments = [];
  final List<Announcement> announcements = [];
  final List<AppNotification> notifications = [];
  final List<ContentReport> reports = [];
  final List<DirectMessage> directMessages = [];
  final List<TodoList> todoLists = [];
  final Map<String, NotificationPrefs> prefsByUserId = {};
  List<CalendarEvent> _sharedEvents = [];
  List<CalendarEvent> _ownEvents = [];

  AppUser? currentUser;

  // ---- Change streams -----------------------------------------------------
  final userChanges = StreamController<void>.broadcast();
  final feedChanges = StreamController<void>.broadcast();
  final announcementChanges = StreamController<void>.broadcast();
  final notificationChanges = StreamController<void>.broadcast();
  final messageChanges = StreamController<void>.broadcast();
  final calendarChanges = StreamController<void>.broadcast();
  final todoChanges = StreamController<void>.broadcast();
  final authChanges = StreamController<AppUser?>.broadcast();

  StreamSubscription<DocumentSnapshot<Json>>? _userSub;
  final List<StreamSubscription<dynamic>> _dataSubs = [];
  StreamSubscription<dynamic>? _reportsSub;
  bool _dataStarted = false;
  final Completer<void> _ready = Completer<void>();

  String? get uid => auth.currentUser?.uid;

  Iterable<AppUser> get approvedMembers =>
      users.where((u) => u.status == MemberStatus.approved);

  AppUser? userById(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  NotificationPrefs prefsFor(String userId) =>
      prefsByUserId.putIfAbsent(userId, NotificationPrefs.new);

  /// Calendar events visible to the signed-in user (family + own private).
  List<CalendarEvent> get events {
    final byId = <String, CalendarEvent>{
      for (final e in _sharedEvents) e.id: e,
      for (final e in _ownEvents) e.id: e,
    };
    return byId.values.toList();
  }

  String newId(String collection) => db.collection(collection).doc().id;

  // ---- Lifecycle ----------------------------------------------------------

  Future<void> _start() async {
    auth.authStateChanges().listen(_onAuth);
    await _ready.future;
  }

  void _completeReady() {
    if (!_ready.isCompleted) _ready.complete();
  }

  void _onAuth(User? user) {
    _userSub?.cancel();
    _stopData();
    _clearCaches();
    currentUser = null;

    if (user == null) {
      authChanges.add(null);
      _completeReady();
      return;
    }
    _userSub = db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          _onUserDoc,
          onError: (Object e) {
            debugPrint('Firestore user doc: $e');
            _completeReady();
          },
        );
  }

  void _onUserDoc(DocumentSnapshot<Json> snap) {
    if (!snap.exists) {
      // Signed in but no profile yet (mid-registration) — stay signed out
      // as far as the UI is concerned until the profile is written.
      currentUser = null;
      _completeReady();
      return;
    }
    final me = userFromDoc(snap);
    prefsByUserId[me.id] = prefsFromMap(snap.data()!['prefs']);
    currentUser = me;
    if (userById(me.id) == null) users.add(me);

    if (me.isApproved) {
      _startData(me);
    } else {
      _stopData();
    }
    _completeReady();
    authChanges.add(me);
    userChanges.add(null);
  }

  void _clearCaches() {
    users.clear();
    posts.clear();
    comments.clear();
    announcements.clear();
    notifications.clear();
    reports.clear();
    directMessages.clear();
    todoLists.clear();
    prefsByUserId.clear();
    _sharedEvents = [];
    _ownEvents = [];
  }

  void _stopData() {
    for (final s in _dataSubs) {
      s.cancel();
    }
    _dataSubs.clear();
    _reportsSub?.cancel();
    _reportsSub = null;
    _dataStarted = false;
  }

  void _startData(AppUser me) {
    if (!_dataStarted) {
      _dataStarted = true;
      final id = me.id;

      listen(db.collection('users'), (s) {
        users
          ..clear()
          ..addAll(s.docs.map(userFromDoc));
        for (final d in s.docs) {
          prefsByUserId[d.id] = prefsFromMap(d.data()['prefs']);
        }
        final mine = userById(id);
        if (mine != null) currentUser = mine;
        userChanges.add(null);
      });
      listen(db.collection('posts'), (s) {
        posts
          ..clear()
          ..addAll(s.docs.map(postFromDoc));
        feedChanges.add(null);
      });
      listen(db.collection('comments'), (s) {
        comments
          ..clear()
          ..addAll(s.docs.map(commentFromDoc));
        feedChanges.add(null);
      });
      listen(db.collection('announcements'), (s) {
        announcements
          ..clear()
          ..addAll(s.docs.map(announcementFromDoc));
        announcementChanges.add(null);
      });
      listen(
        db.collection('notifications').where('userId', isEqualTo: id),
        (s) {
          notifications
            ..clear()
            ..addAll(s.docs.map(notificationFromDoc));
          notificationChanges.add(null);
        },
      );
      listen(
        db.collection('messages').where('participants', arrayContains: id),
        (s) {
          directMessages
            ..clear()
            ..addAll(s.docs.map(messageFromDoc));
          messageChanges.add(null);
        },
      );
      listen(
        db.collection('events').where('shared', isEqualTo: true),
        (s) {
          _sharedEvents = s.docs.map(eventFromDoc).toList();
          calendarChanges.add(null);
        },
      );
      listen(
        db.collection('events').where('ownerId', isEqualTo: id),
        (s) {
          _ownEvents = s.docs.map(eventFromDoc).toList();
          calendarChanges.add(null);
        },
      );
      listen(
        db.collection('todoLists').where('members', arrayContains: id),
        (s) {
          todoLists
            ..clear()
            ..addAll(s.docs.map(todoFromDoc));
          todoChanges.add(null);
        },
      );
    }

    // Reports are admin-only, and admin status can change at runtime.
    if (me.isAdmin && _reportsSub == null) {
      _reportsSub = db
          .collection('reports')
          .snapshots()
          .listen(
            (s) {
              reports
                ..clear()
                ..addAll(s.docs.map(reportFromDoc));
              feedChanges.add(null);
            },
            onError: (Object e) => debugPrint('Firestore reports: $e'),
          );
    } else if (!me.isAdmin && _reportsSub != null) {
      _reportsSub!.cancel();
      _reportsSub = null;
      reports.clear();
    }
  }

  void listen(
    Query<Json> query,
    void Function(QuerySnapshot<Json>) onData,
  ) {
    _dataSubs.add(
      query.snapshots().listen(
        onData,
        onError: (Object e) => debugPrint('Firestore ${query.parameters}: $e'),
      ),
    );
  }

  // ---- Auth actions -------------------------------------------------------

  Future<AppUser> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = AppUser(
      id: cred.user!.uid,
      firstName: firstName,
      familyName: familyName,
      email: email,
      status: MemberStatus.pending,
      joinDate: DateTime.now(),
    );
    try {
      await db.collection('users').doc(user.id).set(userToMap(user));
    } catch (e) {
      // Don't leave an account with no profile behind.
      await cred.user!.delete();
      rethrow;
    }
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
    return authChanges.stream
        .firstWhere((u) => u != null)
        .timeout(const Duration(seconds: 15))
        .then((u) => u!);
  }

  Future<void> logout() => auth.signOut();

  // ---- Shared write helpers ----------------------------------------------

  /// Best-effort in-app notification. Never throws — a failed notification
  /// must not break the action that triggered it.
  void notify({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
  }) {
    final n = AppNotification(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    db
        .collection('notifications')
        .add(notificationToMap(n))
        .then<void>(
          (_) {},
          onError: (Object e) => debugPrint('notify failed: $e'),
        );
  }

  void notifyAdmins({
    required AppNotificationType type,
    required String title,
    required String body,
  }) {
    for (final admin in users.where((u) => u.isAdmin && u.isApproved)) {
      if (admin.id == uid) continue;
      notify(userId: admin.id, type: type, title: title, body: body);
    }
  }
}
