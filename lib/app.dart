import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_mode.dart';
import 'firebase/firebase_backend.dart';
import 'firebase/firebase_repositories.dart';
import 'providers/admin_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/message_provider.dart';
import 'providers/notification_prefs_provider.dart';
import 'providers/plan_providers.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'repositories/mock/mock_admin_repository.dart';
import 'repositories/mock/mock_announcement_repository.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/mock/mock_backend.dart';
import 'repositories/mock/mock_feed_repository.dart';
import 'repositories/mock/mock_message_repository.dart';
import 'repositories/mock/mock_notification_prefs_repository.dart';
import 'repositories/mock/mock_plan_repositories.dart';
import 'repositories/mock/mock_notification_repository.dart';
import 'repositories/mock/mock_user_repository.dart';
import 'repositories/admin_repository.dart';
import 'repositories/announcement_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/feed_repository.dart';
import 'repositories/message_repository.dart';
import 'repositories/notification_prefs_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/plan_repository.dart';
import 'repositories/user_repository.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// The set of repositories the app runs on. Swapping backends only means
/// building a different bundle — screens never know the difference.
class _Repos {
  _Repos({
    required this.auth,
    required this.users,
    required this.feed,
    required this.announcements,
    required this.notifications,
    required this.prefs,
    required this.admin,
    required this.messages,
    required this.calendar,
    required this.todos,
  });

  final AuthRepository auth;
  final UserRepository users;
  final FeedRepository feed;
  final AnnouncementRepository announcements;
  final NotificationRepository notifications;
  final NotificationPrefsRepository prefs;
  final AdminRepository admin;
  final MessageRepository messages;
  final CalendarRepository calendar;
  final TodoRepository todos;
}

/// Root widget. Use [FamilyCircleApp.firebase] for the real app and
/// [FamilyCircleApp.mock] for tests / offline demos with sample data.
class FamilyCircleApp extends StatelessWidget {
  const FamilyCircleApp.mock({super.key}) : _firebase = null;
  const FamilyCircleApp.firebase(FirebaseBackend backend, {super.key})
    : _firebase = backend;

  final FirebaseBackend? _firebase;

  _Repos _buildRepos(BuildContext context) {
    final fb = _firebase;
    if (fb != null) {
      return _Repos(
        auth: FirebaseAuthRepository(fb),
        users: FirebaseUserRepository(fb),
        feed: FirebaseFeedRepository(fb),
        announcements: FirebaseAnnouncementRepository(fb),
        notifications: FirebaseNotificationRepository(fb),
        prefs: FirebaseNotificationPrefsRepository(fb),
        admin: FirebaseAdminRepository(fb),
        messages: FirebaseMessageRepository(fb),
        calendar: FirebaseCalendarRepository(fb),
        todos: FirebaseTodoRepository(fb),
      );
    }
    final mock = context.read<MockBackend>();
    return _Repos(
      auth: MockAuthRepository(mock),
      users: MockUserRepository(mock),
      feed: MockFeedRepository(mock),
      announcements: MockAnnouncementRepository(mock),
      notifications: MockNotificationRepository(mock),
      prefs: MockNotificationPrefsRepository(mock),
      admin: MockAdminRepository(mock),
      messages: MockMessageRepository(mock),
      calendar: MockCalendarRepository(mock),
      todos: MockTodoRepository(mock),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: AppMode(isMock: _firebase == null)),
        if (_firebase == null) Provider(create: (_) => MockBackend()),
        Provider(create: _buildRepos),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(ctx.read<_Repos>().auth),
        ),
        ChangeNotifierProvider(
          create: (ctx) => UserProvider(ctx.read<_Repos>().users),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FeedProvider(ctx.read<_Repos>().feed),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              AnnouncementProvider(ctx.read<_Repos>().announcements),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              NotificationProvider(ctx.read<_Repos>().notifications),
        ),
        ChangeNotifierProvider(
          create: (ctx) => NotificationPrefsProvider(ctx.read<_Repos>().prefs),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AdminProvider(ctx.read<_Repos>().admin),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MessageProvider(ctx.read<_Repos>().messages),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CalendarProvider(ctx.read<_Repos>().calendar),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TodoProvider(ctx.read<_Repos>().todos),
        ),
        // Built once, after AuthProvider exists above it; GoRouter's own
        // refreshListenable (not a widget rebuild) reacts to auth changes.
        Provider<GoRouter>(
          create: (ctx) => AppRouter(ctx.read<AuthProvider>()).router,
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Family Circle',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            routerConfig: context.read<GoRouter>(),
          );
        },
      ),
    );
  }
}
