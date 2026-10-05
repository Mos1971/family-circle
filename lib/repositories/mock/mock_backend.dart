import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../models/announcement.dart';
import '../../models/app_notification.dart';
import '../../models/calendar_event.dart';
import '../../models/comment.dart';
import '../../models/direct_message.dart';
import '../../models/notification_prefs.dart';
import '../../models/post.dart';
import '../../models/reaction.dart';
import '../../models/report.dart';
import '../../models/todo.dart';
import '../../models/user.dart';

/// Single in-memory store shared by every Mock*Repository so cross-domain
/// side effects (e.g. approving a member posts a welcome message) stay in one
/// place instead of repositories reaching into each other.
///
/// A future FirebaseBackend equivalent would replace this with real
/// Firestore/Auth/FCM calls behind the same repository interfaces.
class MockBackend {
  MockBackend() {
    _seed();
  }

  static const _uuid = Uuid();

  final List<AppUser> users = [];
  final List<Post> posts = [];
  final List<Comment> comments = [];
  final List<Announcement> announcements = [];
  final List<AppNotification> notifications = [];
  final List<ContentReport> reports = [];
  final List<ChatMessage> messages = [];
  final List<Chat> chats = [];
  final List<CalendarEvent> events = [];
  final List<TodoList> todoLists = [];
  final Map<String, NotificationPrefs> prefsByUserId = {};

  String? currentUserId;

  final userChanges = StreamController<void>.broadcast();
  final feedChanges = StreamController<void>.broadcast();
  final announcementChanges = StreamController<void>.broadcast();
  final notificationChanges = StreamController<void>.broadcast();
  final messageChanges = StreamController<void>.broadcast();
  final calendarChanges = StreamController<void>.broadcast();
  final todoChanges = StreamController<void>.broadcast();
  final authChanges = StreamController<AppUser?>.broadcast();

  AppUser? get currentUser =>
      currentUserId == null ? null : userById(currentUserId!);

  AppUser? userById(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  NotificationPrefs prefsFor(String userId) =>
      prefsByUserId.putIfAbsent(userId, NotificationPrefs.new);

  Iterable<AppUser> get approvedMembers =>
      users.where((u) => u.status == MemberStatus.approved);

  String newId() => _uuid.v4();

  // ---------------------------------------------------------------------
  // Cross-domain side effects
  // ---------------------------------------------------------------------

  void welcomeNewMember(AppUser user) {
    final family = user.familyName.isEmpty ? '' : ' (${user.familyName})';
    final post = Post(
      id: newId(),
      authorId: user.id,
      text: '👋 Welcome to Family Circle, ${user.firstName}$family!',
      createdAt: DateTime.now(),
      type: PostType.welcome,
    );
    posts.insert(0, post);
    feedChanges.add(null);

    for (final member in approvedMembers) {
      if (member.id == user.id) continue;
      if (!prefsFor(member.id).communityOn) continue;
      notifications.insert(
        0,
        AppNotification(
          id: newId(),
          userId: member.id,
          type: AppNotificationType.community,
          title: 'New member 👋',
          body: '${user.firstName} just joined Family Circle.',
          createdAt: DateTime.now(),
        ),
      );
    }
    notificationChanges.add(null);
  }

  void notifyAdmins({
    required AppNotificationType type,
    required String title,
    required String body,
  }) {
    for (final admin in users.where((u) => u.isAdmin)) {
      notifications.insert(
        0,
        AppNotification(
          id: newId(),
          userId: admin.id,
          type: type,
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
      );
    }
    notificationChanges.add(null);
  }

  // ---------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------

  void _seed() {
    final now = DateTime.now();

    final admin = AppUser(
      id: 'u_admin',
      firstName: 'Jordan',
      familyName: 'The Brooks',
      email: 'jordan@example.com',
      bio: 'Circle admin — shout if you need anything 👑',
      role: MemberRole.admin,
      status: MemberStatus.approved,
      joinDate: now.subtract(const Duration(days: 400)),
      profileEmoji: '👑',
    );

    final sarah = AppUser(
      id: 'u_sarah',
      firstName: 'Sarah',
      familyName: 'The Okafors',
      email: 'sarah@example.com',
      bio: 'Mum of three. Always baking something 🍪',
      status: MemberStatus.approved,
      joinDate: now.subtract(const Duration(days: 180)),
      profileEmoji: '🌻',
    );

    final david = AppUser(
      id: 'u_david',
      firstName: 'David',
      familyName: 'The Okafors',
      email: 'david@example.com',
      bio: 'Weekend footballer and BBQ enthusiast ⚽',
      status: MemberStatus.approved,
      joinDate: now.subtract(const Duration(days: 175)),
      profileEmoji: '⚽',
    );

    final maya = AppUser(
      id: 'u_maya',
      firstName: 'Maya',
      familyName: 'The Patels',
      email: 'maya@example.com',
      bio: 'New here — hello everyone!',
      status: MemberStatus.approved,
      joinDate: now.subtract(const Duration(days: 40)),
      profileEmoji: '🌟',
    );

    final craig = AppUser(
      id: 'u_craig',
      firstName: 'Craig',
      familyName: 'The Hendersons',
      email: 'craig@example.com',
      bio: 'Grandad, gardener, terrible joke teller 🌱',
      status: MemberStatus.approved,
      joinDate: now.subtract(const Duration(days: 260)),
      profileEmoji: '🌱',
    );

    final pending = AppUser(
      id: 'u_pending_amanda',
      firstName: 'Amanda',
      familyName: 'The Clarkes',
      email: 'amanda@example.com',
      status: MemberStatus.pending,
      joinDate: now,
    );

    users.addAll([admin, sarah, david, maya, craig, pending]);

    announcements.addAll([
      Announcement(
        id: newId(),
        title: 'Family day out — save the date',
        body:
            'We\'re planning a Circle picnic at the park on the first '
            'Saturday of next month. Bring a blanket, a dish to share and '
            'the kids. More details to follow right here.',
        authorId: admin.id,
        createdAt: now.subtract(const Duration(days: 2)),
        pinned: true,
      ),
      Announcement(
        id: newId(),
        title: 'Be kind, be family',
        body:
            'A reminder that Family Circle is a safe, friendly space. If '
            'something in the feed doesn\'t feel right, use the report '
            'button and an admin will take a look.',
        authorId: admin.id,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
    ]);

    posts.addAll([
      Post(
        id: newId(),
        authorId: sarah.id,
        text:
            'Made far too many cupcakes for the school fair. Anyone '
            'want some? 🧁',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Post(
        id: newId(),
        authorId: maya.id,
        text:
            'Hello Circle! We\'re the Patels — so glad to be part of '
            'this. Any tips for good family days out nearby?',
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      Post(
        id: newId(),
        authorId: craig.id,
        text:
            'Our tomatoes finally came in 🍅 Pop round if you want a '
            'bag — plenty to go around.',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
    ]);
    posts[0].reactions[ReactionType.like]!.addAll([craig.id, maya.id]);
    posts[0].reactions[ReactionType.celebrate]!.add(admin.id);
    posts[1].reactions[ReactionType.like]!.addAll([sarah.id, craig.id]);
    posts[2].reactions[ReactionType.love]!.addAll([sarah.id, david.id]);

    comments.add(
      Comment(
        id: newId(),
        postId: posts[1].id,
        authorId: sarah.id,
        text: 'Welcome Maya! The riverside park is lovely on weekends 🧡',
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
    );

    ChatMessage dm(
      String from,
      String to,
      String text,
      Duration ago, {
      bool read = false,
    }) => ChatMessage(
      id: newId(),
      chatId: dmChatId(from, to),
      senderId: from,
      text: text,
      createdAt: now.subtract(ago),
      participants: [from, to],
      readBy: {from, if (read) to},
    );

    messages.addAll([
      dm(
        sarah.id,
        david.id,
        'Can you grab milk on the way home?',
        const Duration(hours: 5),
        read: true,
      ),
      dm(
        david.id,
        sarah.id,
        'On it 👍',
        const Duration(hours: 4, minutes: 50),
        read: true,
      ),
      dm(
        maya.id,
        sarah.id,
        'Hi Sarah! I saw your cupcake post — are the school fair details '
        'anywhere?',
        const Duration(minutes: 35),
      ),
      dm(
        admin.id,
        sarah.id,
        'Thanks for helping organise the picnic! Let me know if you need '
        'anything from me.',
        const Duration(days: 1),
      ),
    ]);

    final picnic = Chat(
      id: newId(),
      name: 'Picnic planning 🧺',
      participants: [admin.id, sarah.id, david.id, maya.id],
      createdBy: admin.id,
      createdAt: now.subtract(const Duration(days: 2)),
    );
    chats.add(picnic);
    messages.addAll([
      ChatMessage(
        id: newId(),
        chatId: picnic.id,
        senderId: admin.id,
        text: 'Who is bringing what to the picnic?',
        createdAt: now.subtract(const Duration(hours: 9)),
        participants: picnic.participants,
        readBy: {admin.id, sarah.id, david.id, maya.id},
      ),
      ChatMessage(
        id: newId(),
        chatId: picnic.id,
        senderId: david.id,
        text: 'I can do the drinks and a football ⚽',
        createdAt: now.subtract(const Duration(hours: 2)),
        participants: picnic.participants,
        readBy: {david.id},
      ),
    ]);

    final today = DateTime(now.year, now.month, now.day);
    events.addAll([
      CalendarEvent(
        id: newId(),
        ownerId: admin.id,
        title: 'Family picnic at the park',
        notes: 'Bring a blanket and a dish to share.',
        date: today.add(const Duration(days: 4)),
        minutesFromMidnight: 12 * 60,
        shared: true,
      ),
      CalendarEvent(
        id: newId(),
        ownerId: sarah.id,
        title: 'School fair',
        date: today.add(const Duration(days: 2)),
        minutesFromMidnight: 10 * 60,
        shared: true,
      ),
      CalendarEvent(
        id: newId(),
        ownerId: craig.id,
        title: 'Tomato swap',
        date: today.add(const Duration(days: 9)),
        shared: true,
      ),
      CalendarEvent(
        id: newId(),
        ownerId: sarah.id,
        title: 'Dentist — Olivia',
        date: today.add(const Duration(days: 1)),
        minutesFromMidnight: 15 * 60 + 30,
      ),
    ]);

    todoLists.addAll([
      TodoList(
        id: newId(),
        ownerId: sarah.id,
        title: 'Weekly shop 🛒',
        sharedWith: {david.id},
        items: [
          TodoItem(id: newId(), text: 'Milk', done: true),
          TodoItem(id: newId(), text: 'Bread'),
          TodoItem(id: newId(), text: 'Cupcake sprinkles'),
        ],
      ),
      TodoList(
        id: newId(),
        ownerId: sarah.id,
        title: 'School fair prep',
        items: [
          TodoItem(id: newId(), text: 'Bake 24 cupcakes', done: true),
          TodoItem(id: newId(), text: 'Print price labels'),
        ],
      ),
    ]);
  }
}
