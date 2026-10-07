import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';

/// The five main sections, in bottom-bar order.
const kTabPaths = ['/home', '/feed', '/messages', '/plan', '/profile'];

/// The phone's bottom menu bar. Used by the main tabs and also by screens
/// that open on top of them (admin dashboard, a list...) so there is always a
/// way back to the rest of the app.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final unread = userId == null
        ? 0
        : context.watch<MessageProvider>().unreadCountFor(userId);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
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
          icon: _MessagesIcon(unread: unread, filled: false),
          activeIcon: _MessagesIcon(unread: unread, filled: true),
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
    );
  }
}

class _MessagesIcon extends StatelessWidget {
  const _MessagesIcon({required this.unread, required this.filled});

  final int unread;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(filled ? Icons.chat_bubble : Icons.chat_bubble_outline);
    if (unread == 0) return icon;
    return Badge(
      backgroundColor: AppColors.gold,
      textColor: AppColors.onGold,
      label: Text('$unread'),
      child: icon,
    );
  }
}
