import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget: wires the mock backend + repositories into providers, then
/// hands the app off to go_router. Swapping in a real Firebase backend later
/// means replacing this provider list with Firebase*Repository
/// implementations of the same abstract repository interfaces — screens
/// don't change.
class FamilyCircleApp extends StatelessWidget {
  const FamilyCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => MockBackend()),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(MockAuthRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => UserProvider(MockUserRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FeedProvider(MockFeedRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              AnnouncementProvider(MockAnnouncementRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              NotificationProvider(MockNotificationRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => NotificationPrefsProvider(
            MockNotificationPrefsRepository(ctx.read()),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AdminProvider(MockAdminRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MessageProvider(MockMessageRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CalendarProvider(MockCalendarRepository(ctx.read())),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TodoProvider(MockTodoRepository(ctx.read())),
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
