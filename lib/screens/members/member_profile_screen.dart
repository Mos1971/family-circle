import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_back_button.dart';

import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/post_card.dart';

/// Another member's profile with a prominent "Message" button.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final member = context.watch<UserProvider>().getById(memberId);
    final posts = context
        .watch<FeedProvider>()
        .getPosts()
        .where((p) => p.authorId == memberId)
        .toList();

    if (member == null || !member.isApproved) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: const EmptyState(emoji: '👤', title: 'Member not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                MemberAvatar(user: member, radius: 44),
                const SizedBox(height: 12),
                Text(
                  member.firstName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (member.familyName.isNotEmpty)
                  Text(
                    member.familyName,
                    style: TextStyle(color: AppColors.gold),
                  ),
                if (member.isAdmin) ...[
                  const SizedBox(height: 4),
                  Text(
                    'CIRCLE ADMIN',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
                if (member.bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    member.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Member since ${DateFormat.yMMMM().format(member.joinDate)}',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (me != null && me.id != member.id)
            ElevatedButton.icon(
              onPressed: () => context.push('/messages/dm/${member.id}'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text('Message ${member.firstName}'),
            ),
          const SizedBox(height: 24),
          Text('Posts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (posts.isEmpty)
            Text('No posts yet.', style: TextStyle(color: AppColors.muted))
          else
            ...posts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(post: p),
              ),
            ),
        ],
      ),
    );
  }
}
