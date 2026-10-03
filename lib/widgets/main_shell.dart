import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final unreadMessages = userId == null
        ? 0
        : context.watch<MessageProvider>().unreadCountFor(userId);

    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed_outlined),
            activeIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: _MessagesIcon(unread: unreadMessages, filled: false),
            activeIcon: _MessagesIcon(unread: unreadMessages, filled: true),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Plan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _MessagesIcon extends StatelessWidget {
  const _MessagesIcon({required this.unread, required this.filled});

  final int unread;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.chat_bubble : Icons.chat_bubble_outline,
    );
    if (unread == 0) return icon;
    return Badge(
      backgroundColor: AppColors.gold,
      textColor: AppColors.onGold,
      label: Text('$unread'),
      child: icon,
    );
  }
}
