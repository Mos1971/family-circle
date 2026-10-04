import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/announcements/announcement_detail_screen.dart';
import '../screens/announcements/announcements_list_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/community/feed_screen.dart';
import '../screens/community/post_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/members/member_profile_screen.dart';
import '../screens/members/members_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../screens/plan/plan_screen.dart';
import '../screens/plan/todo_detail_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/app_layout.dart';
import '../widgets/main_shell.dart';

class AppRouter {
  AppRouter(this._auth) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _auth,
      redirect: _redirect,
      routes: [
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
        GoRoute(
          path: '/pending',
          builder: (c, s) => const PendingApprovalScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AppLayout(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/feed/post/:postId',
              builder: (c, s) =>
                  PostDetailScreen(postId: s.pathParameters['postId']!),
            ),
            // '/messages/new' must be declared before '/messages/:userId'.
            GoRoute(
              path: '/messages/new',
              builder: (c, s) => const MembersScreen(pickToMessage: true),
            ),
            GoRoute(
              path: '/messages/:userId',
              builder: (c, s) =>
                  ChatScreen(otherUserId: s.pathParameters['userId']!),
            ),
            GoRoute(
              path: '/members/:userId',
              builder: (c, s) =>
                  MemberProfileScreen(memberId: s.pathParameters['userId']!),
            ),
            GoRoute(
              path: '/profile/edit',
              builder: (c, s) => const EditProfileScreen(),
            ),
            GoRoute(
              path: '/profile/notifications',
              builder: (c, s) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: '/announcements',
              builder: (c, s) => const AnnouncementsListScreen(),
            ),
            GoRoute(
              path: '/announcements/:id',
              builder: (c, s) => AnnouncementDetailScreen(
                announcementId: s.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/notifications',
              builder: (c, s) => const NotificationCenterScreen(),
            ),
            GoRoute(path: '/family', builder: (c, s) => const MembersScreen()),
            GoRoute(
              path: '/lists/:listId',
              builder: (c, s) =>
                  TodoDetailScreen(listId: s.pathParameters['listId']!),
            ),
            GoRoute(
              path: '/admin',
              builder: (c, s) => const AdminDashboardScreen(),
            ),
            StatefulShellRoute.indexedStack(
              builder: (context, state, shell) => MainShell(shell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/home',
                      builder: (c, s) => const HomeScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/feed',
                      builder: (c, s) => const FeedScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/messages',
                      builder: (c, s) => const MessagesScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/plan',
                      builder: (c, s) => const PlanScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/profile',
                      builder: (c, s) => const ProfileScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  final AuthProvider _auth;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final loggedIn = _auth.isLoggedIn;
    final authScreens = {'/login', '/register'};

    if (!loggedIn) {
      return authScreens.contains(loc) ? null : '/login';
    }

    // Pending and removed/rejected members are held on the waiting screen.
    if (!_auth.isApproved) {
      return loc == '/pending' ? null : '/pending';
    }

    if (authScreens.contains(loc) || loc == '/pending') {
      return '/home';
    }

    if (loc.startsWith('/admin') && !_auth.isAdmin) {
      return '/home';
    }

    return null;
  }
}
