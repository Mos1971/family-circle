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

/// Where a sign-up / "add another circle" request is heading, after the
/// codes have been checked.
class _Target {
  _Target({
    required this.circleId,
    required this.circleName,
    required this.creating,
    this.license,
    this.newInviteCode,
  });

  final String circleId;
  final String circleName;
  final bool creating;
  final String? license;
  final String? newInviteCode;
}

/// Live Firestore data mirrored into in-memory lists.
///
/// The repositories are synchronous (they were written against an in-memory
/// store), so this class listens to Firestore and keeps the same shape of
/// data in memory; repositories read from here and write straight to
/// Firestore. Firestore's local write cache makes our own writes show up in
/// the listeners immediately, so the UI feels instant.
///
/// Data model:
///  * `users/{uid}` — the sign-in account: which circles the person belongs
///    to and which one is active.
///  * `circles/{cid}/members/{uid}` — the person's profile *inside* that
///    circle (name, role, approval status, preferences). One person can be in
///    many circles with a different role in each.
///  * `circles/{cid}/{posts,comments,...}` — all circle data.
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

  /// The signed-in person's profile in the *active* circle.
  AppUser? currentUser;

  /// The active circle (name, invite code).
  Circle? circle;

  /// Every circle the person belongs to, for the switcher.
  List<CircleRef> myCircles = [];

  // ---- Change streams -----------------------------------------------------
  final userChanges = StreamController<void>.broadcast();
  final feedChanges = StreamController<void>.broadcast();
  final announcementChanges = StreamController<void>.broadcast();
  final notificationChanges = StreamController<void>.broadcast();
  final messageChanges = StreamController<void>.broadcast();
  final calendarChanges = StreamController<void>.broadcast();
  final todoChanges = StreamController<void>.broadcast();
  final authChanges = StreamController<AppUser?>.broadcast();

  StreamSubscription<DocumentSnapshot<Json>>? _accountSub;
  StreamSubscription<DocumentSnapshot<Json>>? _memberSub;
  StreamSubscription<DocumentSnapshot<Json>>? _circleSub;
  final List<StreamSubscription<dynamic>> _dataSubs = [];
  StreamSubscription<dynamic>? _reportsSub;
  bool _dataStarted = false;
  String? _activeCircleId;
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

  DocumentReference<Json> get _circleDoc =>
      db.collection('circles').doc(_activeCircleId);

  /// A collection inside the active circle. All shared data lives under
  /// `circles/{circleId}/...` so circles are fully separate.
  CollectionReference<Json> col(String name) => _circleDoc.collection(name);

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
    _accountSub?.cancel();
    _accountSub = null;
    _teardownCircle();
    currentUser = null;
    myCircles = [];
    _activeCircleId = null;

    if (user == null) {
      authChanges.add(null);
      _completeReady();
      return;
    }
    _accountSub = db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          _onAccountDoc,
          onError: (Object e) {
            debugPrint('Firestore account doc: $e');
            _completeReady();
          },
        );
  }

  void _onAccountDoc(DocumentSnapshot<Json> snap) {
    if (!snap.exists) {
      // Signed in but not set up yet (mid-registration).
      _completeReady();
      return;
    }
    final data = snap.data()!;
    final names = (data['circleNames'] is Map)
        ? Map<String, dynamic>.from(data['circleNames'] as Map)
        : <String, dynamic>{};
    final ids = List<String>.from(data['circleIds'] as List? ?? const []);
    myCircles = [
      for (final id in ids)
        CircleRef(id: id, name: (names[id] as String?) ?? 'Family Circle'),
    ];
    userChanges.add(null);

    final active = (data['activeCircleId'] as String?) ?? '';
    if (active.isEmpty) {
      _completeReady();
      return;
    }
    if (active != _activeCircleId) _switchTo(active);
  }

  /// Stops listening to the current circle and clears its cached data.
  void _teardownCircle() {
    _memberSub?.cancel();
    _memberSub = null;
    _circleSub?.cancel();
    _circleSub = null;
    _stopData();
    _clearCaches();
    circle = null;
  }

  void _switchTo(String circleId) {
    _teardownCircle();
    _activeCircleId = circleId;
    final me = uid;
    if (me == null) return;

    _circleSub = _circleDoc.snapshots().listen((s) {
      circle = s.exists ? circleFromDoc(s) : null;
      userChanges.add(null);
    }, onError: (Object e) => debugPrint('Firestore circle: $e'));

    _memberSub = _circleDoc
        .collection('members')
        .doc(me)
        .snapshots()
        .listen(
          (s) => _onMemberDoc(s, circleId),
          onError: (Object e) {
            debugPrint('Firestore member doc: $e');
            _completeReady();
          },
        );
  }

  void _onMemberDoc(DocumentSnapshot<Json> snap, String circleId) {
    if (circleId != _activeCircleId) return;
    if (!snap.exists) {
      // Membership not written yet (mid-registration).
      _completeReady();
      return;
    }
    final me = userFromDoc(snap, circleId: circleId);
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
      final cid = me.circleId;

      listen(col('members'), (s) {
        users
          ..clear()
          ..addAll(s.docs.map((d) => userFromDoc(d, circleId: cid)));
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

  // ---- Joining / creating circles ----------------------------------------

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _randomCode(int length) {
    final r = Random.secure();
    return List.generate(
      length,
      (_) => _codeAlphabet[r.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Checks the code the person entered (no sign-in needed — codes can be
  /// looked up one at a time) and works out where they are heading.
  Future<_Target> _resolveTarget({
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

    if (joining) {
      final code = inviteCode!.trim().toUpperCase();
      final snap = await db.collection('inviteCodes').doc(code).get();
      if (!snap.exists) {
        throw Exception(
          'That invite code isn\'t valid. Please check it with your circle admin.',
        );
      }
      final data = snap.data()!;
      return _Target(
        circleId: data['circleId'] as String,
        circleName: (data['circleName'] as String?) ?? 'Family Circle',
        creating: false,
      );
    }

    final name = (circleName ?? '').trim();
    if (name.isEmpty) throw Exception('Please give your circle a name.');
    final license = licenseCode!.trim().toUpperCase();
    final snap = await db.collection('licenses').doc(license).get();
    if (!snap.exists || snap.data()!['used'] == true) {
      throw Exception(
        'That licence code isn\'t valid or has already been used.',
      );
    }
    String code;
    do {
      code = _randomCode(8);
    } while ((await db.collection('inviteCodes').doc(code).get()).exists);
    return _Target(
      circleId: db.collection('circles').doc().id,
      circleName: name,
      creating: true,
      license: license,
      newInviteCode: code,
    );
  }

  /// Writes the person's membership of [t] (and points their account at it).
  /// A new circle is created in the same batch when [t] is a founding.
  Future<void> _commitMembership({
    required String uid,
    required String email,
    required String firstName,
    required String familyName,
    required _Target t,
  }) async {
    final memberRef = db
        .collection('circles')
        .doc(t.circleId)
        .collection('members')
        .doc(uid);

    if (!t.creating && (await memberRef.get()).exists) {
      throw Exception('You\'re already part of that circle.');
    }

    final member = AppUser(
      id: uid,
      firstName: firstName,
      familyName: familyName,
      circleId: t.circleId,
      email: email,
      role: t.creating ? MemberRole.admin : MemberRole.member,
      status: t.creating ? MemberStatus.approved : MemberStatus.pending,
      joinDate: DateTime.now(),
    );

    final batch = db.batch();
    if (t.creating) {
      batch.set(db.collection('circles').doc(t.circleId), {
        'name': t.circleName,
        'ownerId': uid,
        'code': t.newInviteCode,
        'licenseCode': t.license,
        'createdAt': Timestamp.now(),
      });
      batch.set(db.collection('inviteCodes').doc(t.newInviteCode), {
        'circleId': t.circleId,
        'circleName': t.circleName,
      });
      batch.update(db.collection('licenses').doc(t.license), {
        'used': true,
        'circleId': t.circleId,
        'usedBy': uid,
        'usedAt': Timestamp.now(),
      });
    }
    batch.set(memberRef, userToMap(member));
    batch.set(db.collection('users').doc(uid), {
      'email': email,
      'activeCircleId': t.circleId,
      'circleIds': FieldValue.arrayUnion([t.circleId]),
      'circleNames': {t.circleId: t.circleName},
    }, SetOptions(merge: true));
    await batch.commit();
  }

  // ---- Auth actions -------------------------------------------------------

  /// Two ways in:
  ///  * **Join** an existing circle with its invite code — you become a
  ///    pending member until that circle's admin approves you.
  ///  * **Create** a new circle with a one-time licence code — you become its
  ///    admin straight away.
  ///
  /// If the email already has an account, the same password signs in and the
  /// new circle is simply added to it.
  Future<AppUser> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
    String? inviteCode,
    String? licenseCode,
    String? circleName,
  }) async {
    final target = await _resolveTarget(
      inviteCode: inviteCode,
      licenseCode: licenseCode,
      circleName: circleName,
    );

    UserCredential cred;
    var createdAccount = false;
    try {
      cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdAccount = true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      try {
        cred = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException {
        throw Exception(
          'That email already has an account. Enter its existing password to '
          'add this circle to it, or log in instead.',
        );
      }
    }

    final uid = cred.user!.uid;
    try {
      await _commitMembership(
        uid: uid,
        email: email,
        firstName: firstName,
        familyName: familyName,
        t: target,
      );
    } catch (e) {
      // Don't leave a brand-new account with nothing behind it.
      if (createdAccount) await cred.user!.delete();
      rethrow;
    }
    return AppUser(
      id: uid,
      firstName: firstName,
      familyName: familyName,
      circleId: target.circleId,
      email: email,
      role: target.creating ? MemberRole.admin : MemberRole.member,
      status: target.creating ? MemberStatus.approved : MemberStatus.pending,
      joinDate: DateTime.now(),
    );
  }

  /// For someone already signed in: join or start another circle.
  Future<void> addCircle({
    required String firstName,
    required String familyName,
    String? inviteCode,
    String? licenseCode,
    String? circleName,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Please log in first.');
    final target = await _resolveTarget(
      inviteCode: inviteCode,
      licenseCode: licenseCode,
      circleName: circleName,
    );
    await _commitMembership(
      uid: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      familyName: familyName,
      t: target,
    );
  }

  /// Makes [circleId] the active circle.
  Future<void> switchCircle(String circleId) =>
      db.collection('users').doc(uid).update({'activeCircleId': circleId});

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
