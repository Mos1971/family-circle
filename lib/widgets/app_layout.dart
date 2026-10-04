import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'app_wordmark.dart';
import 'member_avatar.dart';

/// Screens at least this wide get the desktop layout (sidebar navigation,
/// centred content). Narrower screens keep the phone layout.
const double kDesktopBreakpoint = 900;

bool isDesktopWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

/// Wraps every signed-in screen. On a phone it does nothing; on a wide
/// screen it adds the sidebar and keeps content to a readable width.
class AppLayout extends StatelessWidget {
  const AppLayout({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  double get _contentMaxWidth {
    if (location.startsWith('/home')) return 1180;
    if (location.startsWith('/plan')) return 1040;
    return 780;
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWidth(context)) return child;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _Sidebar(location: location),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _contentMaxWidth),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.activeIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _items = [
  _NavItem('/home', 'Home', Icons.home_outlined, Icons.home),
  _NavItem('/feed', 'Feed', Icons.dynamic_feed_outlined, Icons.dynamic_feed),
  _NavItem(
    '/messages',
    'Messages',
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
  ),
  _NavItem('/plan', 'Plan', Icons.event_note_outlined, Icons.event_note),
  _NavItem('/family', 'Family', Icons.groups_outlined, Icons.groups),
  _NavItem('/profile', 'Profile', Icons.person_outline, Icons.person),
];

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location});

  final String location;

  /// Which sidebar entry a (possibly nested) location belongs to.
  String? _activePath() {
    if (location.startsWith('/lists')) return '/plan';
    if (location.startsWith('/members')) return '/family';
    if (location.startsWith('/announcements')) return '/profile';
    for (final i in _items) {
      if (location.startsWith(i.path)) return i.path;
    }
    if (location.startsWith('/admin')) return '/admin';
    if (location.startsWith('/notifications')) return '/notifications';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final unreadMessages = me == null
        ? 0
        : context.watch<MessageProvider>().unreadCountFor(me.id);
    final unreadNotifications = me == null
        ? 0
        : context.watch<NotificationProvider>().unreadCountFor(me.id);
    final active = _activePath();

    Widget tile(_NavItem item, {int badge = 0}) => _SidebarTile(
      item: item,
      selected: active == item.path,
      badge: badge,
      onTap: () => context.go(item.path),
    );

    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppWordmark(fontSize: 30),
                if (context.watch<UserProvider>().circle != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.watch<UserProvider>().circle!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final item in _items)
            tile(item, badge: item.path == '/messages' ? unreadMessages : 0),
          const SizedBox(height: 8),
          const Divider(height: 24),
          tile(
            const _NavItem(
              '/notifications',
              'Notifications',
              Icons.notifications_none,
              Icons.notifications,
            ),
            badge: unreadNotifications,
          ),
          if (me?.isAdmin ?? false)
            tile(
              const _NavItem(
                '/admin',
                'Admin dashboard',
                Icons.shield_outlined,
                Icons.shield,
              ),
            ),
          const Spacer(),
          if (me != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  MemberAvatar(user: me, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.firstName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (me.familyName.isNotEmpty)
                          Text(
                            me.familyName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout, size: 20),
                    color: AppColors.muted,
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.gold.withValues(alpha: 0.07),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected ? AppColors.gold : AppColors.muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.gold : AppColors.text,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onGold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
