import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/member_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = context.watch<UserProvider>();
    final feed = context.watch<FeedProvider>();
    final me = auth.currentUser == null
        ? null
        : users.getById(auth.currentUser!.id);

    if (me == null) return const SizedBox.shrink();

    final myPostCount = feed
        .getPosts()
        .where((p) => p.authorId == me.id)
        .length;
    final familyCount = me.familyName.isEmpty
        ? 1
        : users
              .getAll()
              .where((u) => u.isApproved && u.familyName == me.familyName)
              .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                MemberAvatar(user: me, radius: 44),
                const SizedBox(height: 12),
                Text(
                  me.firstName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (me.familyName.isNotEmpty)
                  Text(
                    me.familyName,
                    style: const TextStyle(color: AppColors.gold),
                  ),
                if (me.isAdmin) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'CIRCLE ADMIN',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (me.bio.isNotEmpty)
                  Text(
                    me.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Member since ${DateFormat.yMMMM().format(me.joinDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(label: 'Posts', value: '$myPostCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(label: 'In my family', value: '$familyCount'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profile'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Notification settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('Announcements'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/announcements'),
                ),
                if (me.isAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Admin dashboard'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin'),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text(
                    'Log out',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
