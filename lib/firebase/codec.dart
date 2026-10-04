import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';
import '../models/app_notification.dart';
import '../models/calendar_event.dart';
import '../models/circle.dart';
import '../models/comment.dart';
import '../models/direct_message.dart';
import '../models/notification_prefs.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/report.dart';
import '../models/todo.dart';
import '../models/user.dart';

/// Converts between the app's models and Firestore documents.
DateTime _date(dynamic v) =>
    v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

T _enum<T extends Enum>(List<T> values, dynamic name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

// ---- Users ----------------------------------------------------------------

Map<String, dynamic> userToMap(AppUser u) => {
  'firstName': u.firstName,
  'familyName': u.familyName,
  'circleId': u.circleId,
  'email': u.email,
  'bio': u.bio,
  'role': u.role.name,
  'status': u.status.name,
  'joinDate': Timestamp.fromDate(u.joinDate),
  'postCount': u.postCount,
  'profileEmoji': u.profileEmoji,
  'prefs': prefsToMap(NotificationPrefs()),
};

AppUser userFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return AppUser(
    id: d.id,
    firstName: m['firstName'] ?? '',
    familyName: m['familyName'] ?? '',
    circleId: m['circleId'] ?? '',
    email: m['email'] ?? '',
    bio: m['bio'] ?? '',
    role: _enum(MemberRole.values, m['role'], MemberRole.member),
    status: _enum(MemberStatus.values, m['status'], MemberStatus.pending),
    joinDate: _date(m['joinDate']),
    postCount: (m['postCount'] ?? 0) as int,
    profileEmoji: m['profileEmoji'] ?? '🏡',
  );
}

Map<String, dynamic> prefsToMap(NotificationPrefs p) => {
  'announcementsOn': p.announcementsOn,
  'messagesOn': p.messagesOn,
  'calendarOn': p.calendarOn,
  'listsOn': p.listsOn,
  'commentsOn': p.commentsOn,
  'reactionsOn': p.reactionsOn,
  'communityOn': p.communityOn,
};

NotificationPrefs prefsFromMap(dynamic raw) {
  final m = (raw is Map) ? raw : const {};
  bool b(String k) => m[k] is bool ? m[k] as bool : true;
  return NotificationPrefs(
    announcementsOn: b('announcementsOn'),
    messagesOn: b('messagesOn'),
    calendarOn: b('calendarOn'),
    listsOn: b('listsOn'),
    commentsOn: b('commentsOn'),
    reactionsOn: b('reactionsOn'),
    communityOn: b('communityOn'),
  );
}

// ---- Posts / comments / reports ------------------------------------------

Map<String, dynamic> postToMap(Post p) => {
  'authorId': p.authorId,
  'text': p.text,
  'createdAt': Timestamp.fromDate(p.createdAt),
  'type': p.type.name,
  'reactions': {
    for (final t in ReactionType.values) t.name: p.reactions[t]!.toList(),
  },
  'reportedCount': p.reportedCount,
  'hidden': p.hidden,
};

Post postFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  final raw = (m['reactions'] is Map) ? m['reactions'] as Map : const {};
  return Post(
    id: d.id,
    authorId: m['authorId'] ?? '',
    text: m['text'] ?? '',
    createdAt: _date(m['createdAt']),
    type: _enum(PostType.values, m['type'], PostType.normal),
    reactions: {
      for (final t in ReactionType.values)
        t: Set<String>.from((raw[t.name] as List?) ?? const []),
    },
    reportedCount: (m['reportedCount'] ?? 0) as int,
    hidden: m['hidden'] ?? false,
  );
}

Map<String, dynamic> commentToMap(Comment c) => {
  'postId': c.postId,
  'authorId': c.authorId,
  'text': c.text,
  'createdAt': Timestamp.fromDate(c.createdAt),
  'parentCommentId': c.parentCommentId,
};

Comment commentFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return Comment(
    id: d.id,
    postId: m['postId'] ?? '',
    authorId: m['authorId'] ?? '',
    text: m['text'] ?? '',
    createdAt: _date(m['createdAt']),
    parentCommentId: m['parentCommentId'],
  );
}

Map<String, dynamic> reportToMap(ContentReport r) => {
  'contentType': r.contentType.name,
  'contentId': r.contentId,
  'reporterId': r.reporterId,
  'createdAt': Timestamp.fromDate(r.createdAt),
  'resolved': r.resolved,
};

ContentReport reportFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return ContentReport(
    id: d.id,
    contentType: _enum(
      ReportedContentType.values,
      m['contentType'],
      ReportedContentType.post,
    ),
    contentId: m['contentId'] ?? '',
    reporterId: m['reporterId'] ?? '',
    createdAt: _date(m['createdAt']),
    resolved: m['resolved'] ?? false,
  );
}

// ---- Announcements / notifications ---------------------------------------

Map<String, dynamic> announcementToMap(Announcement a) => {
  'title': a.title,
  'body': a.body,
  'authorId': a.authorId,
  'createdAt': Timestamp.fromDate(a.createdAt),
  'pinned': a.pinned,
};

Announcement announcementFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return Announcement(
    id: d.id,
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    authorId: m['authorId'] ?? '',
    createdAt: _date(m['createdAt']),
    pinned: m['pinned'] ?? false,
  );
}

Map<String, dynamic> notificationToMap(AppNotification n) => {
  'userId': n.userId,
  'type': n.type.name,
  'title': n.title,
  'body': n.body,
  'createdAt': Timestamp.fromDate(n.createdAt),
  'read': n.read,
};

AppNotification notificationFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return AppNotification(
    id: d.id,
    userId: m['userId'] ?? '',
    type: _enum(
      AppNotificationType.values,
      m['type'],
      AppNotificationType.community,
    ),
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    createdAt: _date(m['createdAt']),
    read: m['read'] ?? false,
  );
}

// ---- Messages -------------------------------------------------------------

Map<String, dynamic> messageToMap(DirectMessage m) => {
  'senderId': m.senderId,
  'recipientId': m.recipientId,
  'participants': [m.senderId, m.recipientId],
  'text': m.text,
  'createdAt': Timestamp.fromDate(m.createdAt),
  'read': m.read,
};

DirectMessage messageFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return DirectMessage(
    id: d.id,
    senderId: m['senderId'] ?? '',
    recipientId: m['recipientId'] ?? '',
    text: m['text'] ?? '',
    createdAt: _date(m['createdAt']),
    read: m['read'] ?? false,
  );
}

// ---- Calendar -------------------------------------------------------------

Map<String, dynamic> eventToMap(CalendarEvent e) => {
  'ownerId': e.ownerId,
  'title': e.title,
  'notes': e.notes,
  'date': Timestamp.fromDate(e.date),
  'minutesFromMidnight': e.minutesFromMidnight,
  'shared': e.shared,
  'copiedFromId': e.copiedFromId,
};

CalendarEvent eventFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  final date = _date(m['date']);
  return CalendarEvent(
    id: d.id,
    ownerId: m['ownerId'] ?? '',
    title: m['title'] ?? '',
    notes: m['notes'] ?? '',
    date: DateTime(date.year, date.month, date.day),
    minutesFromMidnight: m['minutesFromMidnight'] as int?,
    shared: m['shared'] ?? false,
    copiedFromId: m['copiedFromId'],
  );
}

// ---- To-do lists ----------------------------------------------------------

Map<String, dynamic> todoToMap(TodoList l) => {
  'ownerId': l.ownerId,
  'title': l.title,
  'createdAt': Timestamp.now(),
  'items': [
    for (final i in l.items) {'id': i.id, 'text': i.text, 'done': i.done},
  ],
  'sharedWith': l.sharedWith.toList(),
  'members': [l.ownerId, ...l.sharedWith],
};

TodoList todoFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return TodoList(
    id: d.id,
    ownerId: m['ownerId'] ?? '',
    title: m['title'] ?? '',
    items: [
      for (final i in (m['items'] as List? ?? const []))
        TodoItem(
          id: i['id'] ?? '',
          text: i['text'] ?? '',
          done: i['done'] ?? false,
        ),
    ],
    sharedWith: Set<String>.from(m['sharedWith'] as List? ?? const []),
  );
}

Circle circleFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  return Circle(
    id: d.id,
    name: m['name'] ?? 'Family Circle',
    code: m['code'] ?? '',
    ownerId: m['ownerId'] ?? '',
  );
}
