import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../models/app_notification.dart';
import '../models/calendar_event.dart';
import '../models/circle.dart';
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
  Circle? circle;
  StreamSubscription<DocumentSnapshot<Json>>? _circleSub;

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

  /// A collection inside the signed-in user's circle. All shared data lives
  /// under `circles/{circleId}/...` so circles are fully separate.
  CollectionReference<Json> col(String name) =>
      db.collection('circles').doc(currentUser!.circleId).collection(name);

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
    _circleSub?.cancel();
    _circleSub = null;
    _stopData();
    _clearCaches();
    currentUser = null;
    circle = null;

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
    _watchCircle(me.circleId);

    if (me.isApproved) {
      _startData(me);
    } else {
      _stopData();
    }
    _completeReady();
    authChanges.add(me);
    userChanges.add(null);
  }

  /// Keeps the circle's name and invite code up to date (readable even
  /// while the member is still waiting for approval).
  void _watchCircle(String circleId) {
    if (circleId.isEmpty || circle?.id == circleId && _circleSub != null)
      return;
    _circleSub?.cancel();
    _circleSub = db.collection('circles').doc(circleId).snapshots().listen((s) {
      circle = s.exists ? circleFromDoc(s) : null;
      userChanges.add(null);
    }, onError: (Object e) => debugPrint('Firestore circle: $e'));
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

      listen(db.collection('users').where('circleId', isEqualTo: me.circleId), (
        s,
      ) {
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
      listen(col('posts'), (s) {
        posts
          ..clear()
          ..addAll(s.docs.map(postFromDoc));
        feedChanges.add(null);
      });
      listen(col('comments'), (s) {
        comments
          ..clear()
          ..addAll(s.docs.map(commentFromDoc));
        feedChanges.add(null);
      });
      listen(col('announcements'), (s) {
        announcements
          ..clear()
          ..addAll(s.docs.map(announcementFromDoc));
        announcementChanges.add(null);
      });
      listen(col('notifications').where('userId', isEqualTo: id), (s) {
        notifications
          ..clear()
          ..addAll(s.docs.map(notificationFromDoc));
        notificationChanges.add(null);
      });
      listen(col('messages').where('participants', arrayContains: id), (s) {
        directMessages
          ..clear()
          ..addAll(s.docs.map(messageFromDoc));
        messageChanges.add(null);
      });
      listen(col('events').where('shared', isEqualTo: true), (s) {
        _sharedEvents = s.docs.map(eventFromDoc).toList();
        calendarChanges.add(null);
      });
      listen(col('events').where('ownerId', isEqualTo: id), (s) {
        _ownEvents = s.docs.map(eventFromDoc).toList();
        calendarChanges.add(null);
      });
      listen(col('todoLists').where('members', arrayContains: id), (s) {
        todoLists
          ..clear()
          ..addAll(s.docs.map(todoFromDoc));
        todoChanges.add(null);
      });
    }

    // Reports are admin-only, and admin status can change at runtime.
    if (me.isAdmin && _reportsSub == null) {
      _reportsSub = col('reports').snapshots().listen((s) {
        reports
          ..clear()
          ..addAll(s.docs.map(reportFromDoc));
        feedChanges.add(null);
      }, onError: (Object e) => debugPrint('Firestore reports: $e'));
    } else if (!me.isAdmin && _reportsSub != null) {
      _reportsSub!.cancel();
      _reportsSub = null;
      reports.clear();
    }
  }

  void listen(Query<Json> query, void Function(QuerySnapshot<Json>) onData) {
    _dataSubs.add(
      query.snapshots().listen(
        onData,
        onError: (Object e) => debugPrint('Firestore ${query.parameters}: $e'),
      ),
    );
  }

  // ---- Auth actions -------------------------------------------------------

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _randomCode(int length) {
    final r = Random.secure();
    return List.generate(
      length,
      (_) => _codeAlphabet[r.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Two ways in:
  ///  * **Join** an existing circle with its invite code — you become a
  ///    pending member until that circle's admin approves you.
  ///  * **Create** a new circle with a one-time licence code — you become its
  ///    admin straight away.
  Future<AppUser> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
    String? inviteCode,
    String? licenseCode,
    String? circleName,
  }) async {
    final joining = (inviteCode ?? '').trim().isNotEmpty;
    final creating = (licenseCode ?? '').trim().isNotEmpty;
    if (joining == creating) {
      throw Exception(
        'Enter an invite code to join, or a licence code to start a circle.',
      );
    }

    late final String circleId;
    String? license;
    String? newCode;
    if (joining) {
      final code = inviteCode!.trim().toUpperCase();
      final snap = await db.collection('inviteCodes').doc(code).get();
      if (!snap.exists) {
        throw Exception(
          'That invite code isn\'t valid. Please check it with your circle admin.',
        );
      }
      circleId = snap.data()!['circleId'] as String;
    } else {
      if ((circleName ?? '').trim().isEmpty) {
        throw Exception('Please give your circle a name.');
      }
      license = licenseCode!.trim().toUpperCase();
      final snap = await db.collection('licenses').doc(license).get();
      if (!snap.exists || snap.data()!['used'] == true) {
        throw Exception(
          'That licence code isn\'t valid or has already been used.',
        );
      }
      circleId = db.collection('circles').doc().id;
      // Find an invite code nobody else has.
      do {
        newCode = _randomCode(8);
      } while ((await db.collection('inviteCodes').doc(newCode).get()).exists);
    }

    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      id: uid,
      firstName: firstName,
      familyName: familyName,
      circleId: circleId,
      email: email,
      role: creating ? MemberRole.admin : MemberRole.member,
      status: creating ? MemberStatus.approved : MemberStatus.pending,
      joinDate: DateTime.now(),
    );
    try {
      if (joining) {
        await db.collection('users').doc(uid).set(userToMap(user));
      } else {
        final batch = db.batch();
        batch.set(db.collection('circles').doc(circleId), {
          'name': circleName!.trim(),
          'ownerId': uid,
          'code': newCode,
          'licenseCode': license,
          'createdAt': Timestamp.now(),
        });
        batch.set(db.collection('inviteCodes').doc(newCode), {
          'circleId': circleId,
        });
        batch.update(db.collection('licenses').doc(license), {
          'used': true,
          'circleId': circleId,
          'usedBy': uid,
          'usedAt': Timestamp.now(),
        });
        batch.set(db.collection('users').doc(uid), userToMap(user));
        await batch.commit();
      }
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
    col('notifications')
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
