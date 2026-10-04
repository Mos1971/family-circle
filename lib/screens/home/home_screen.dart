import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/app_wordmark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopWidth(context);
    final me = context.watch<AuthProvider>().currentUser;
    final feed = context.watch<FeedProvider>().getPosts();
    final announcements = context.watch<AnnouncementProvider>().getAll();
    final users = context.watch<UserProvider>();
    final conversations = me == null
        ? const []
        : context.watch<MessageProvider>().getConversations(me.id);
    final unreadConversations = conversations
        .where((c) => c.unreadCount > 0)
        .toList();
    final latestAnnouncement = announcements.isEmpty
        ? null
        : announcements.first;

    final greeting = Text(
      '${_greeting()}, ${me?.firstName ?? 'friend'} 👋',
      style: desktop
          ? Theme.of(context).textTheme.headlineLarge
          : Theme.of(context).textTheme.headlineMedium,
    );

    final quickLinks = Row(
      children: [
        Expanded(
          child: _QuickLink(
            icon: Icons.event_note_outlined,
            label: 'Calendar',
            onTap: () => context.go('/plan'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickLink(
            icon: Icons.checklist_outlined,
            label: 'Lists',
            onTap: () => context.go('/plan'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickLink(
            icon: Icons.groups_outlined,
            label: 'Family',
            onTap: () =>
                desktop ? context.go('/family') : context.push('/family'),
          ),
        ),
      ],
    );

    final unreadBanner = unreadConversations.isEmpty
        ? null
        : InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.go('/messages'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  MemberAvatar(
                    user: users.getById(unreadConversations.first.otherUserId),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unreadConversations.length == 1
                              ? '${users.getById(unreadConversations.first.otherUserId)?.firstName ?? 'Someone'} sent you a message'
                              : 'You have ${unreadConversations.length} unread conversations',
                          style: const TextStyle(
                            color: AppColors.onGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo(
                            unreadConversations.first.lastMessage.createdAt,
                          ),
                          style: TextStyle(
                            color: AppColors.onGold.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.onGold),
                ],
              ),
            ),
          );

    final announcementSection = latestAnnouncement == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '📢 From the admins'),
              AnnouncementCard(
                announcement: latestAnnouncement,
                compact: true,
                onTap: () =>
                    context.push('/announcements/${latestAnnouncement.id}'),
              ),
            ],
          );

    final feedSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '🏡 Family feed',
          actionLabel: 'See all',
          onAction: () => context.go('/feed'),
        ),
        if (feed.isEmpty)
          const EmptyState(
            emoji: '💬',
            title: 'No posts yet',
            subtitle: 'Be the first to share something with the family.',
          )
        else
          ...feed
              .take(desktop ? 5 : 2)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostCard(post: p),
                ),
              ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: desktop ? const Text('Home') : const AppWordmark(fontSize: 22),
        toolbarHeight: 64,
        actions: [
          if (!desktop)
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push('/notifications'),
            ),
        ],
      ),
      body: desktop
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  greeting,
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: feedSection),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            quickLinks,
                            if (unreadBanner != null) ...[
                              const SizedBox(height: 20),
                              unreadBanner,
                            ],
                            if (announcementSection != null) ...[
                              const SizedBox(height: 28),
                              announcementSection,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  greeting,
                  const SizedBox(height: 20),
                  quickLinks,
                  const SizedBox(height: 20),
                  if (unreadBanner != null) ...[
                    unreadBanner,
                    const SizedBox(height: 24),
                  ],
                  if (announcementSection != null) ...[
                    announcementSection,
                    const SizedBox(height: 24),
                  ],
                  feedSection,
                ],
              ),
            ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        hoverColor: AppColors.gold.withValues(alpha: 0.07),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
