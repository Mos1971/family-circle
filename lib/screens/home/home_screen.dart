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

    return Scaffold(
      appBar: AppBar(
        title: const AppWordmark(fontSize: 22),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              '${_greeting()}, ${me?.firstName ?? 'friend'} 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Row(
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
                    onTap: () => context.push('/family'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (unreadConversations.isNotEmpty) ...[
              InkWell(
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
                        user: users.getById(
                          unreadConversations.first.otherUserId,
                        ),
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
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.onGold,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (latestAnnouncement != null) ...[
              const SectionHeader(title: '📢 From the admins'),
              AnnouncementCard(
                announcement: latestAnnouncement,
                compact: true,
                onTap: () =>
                    context.push('/announcements/${latestAnnouncement.id}'),
              ),
              const SizedBox(height: 24),
            ],
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
                  .take(2)
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(post: p),
                    ),
                  ),
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
