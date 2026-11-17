import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appearance_card.dart';
import '../../widgets/circle_switcher.dart';
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
                  Text(me.familyName, style: TextStyle(color: AppColors.gold)),
                if (me.isAdmin) ...[
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
                const SizedBox(height: 8),
                if (me.bio.isNotEmpty)
                  Text(
                    me.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Member since ${DateFormat.yMMMM().format(me.joinDate)}',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
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
          const CircleSwitcher(),
          const SizedBox(height: 16),
          const AppearanceCard(),
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
                  leading: Icon(Icons.logout, color: AppColors.danger),
                  title: Text(
                    'Log out',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => context.read<AuthProvider>().logout(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    'Delete my account',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for the password, then permanently deletes the account.
Future<void> showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.deleteAccount(_password.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and everything you '
              'created in every circle you belong to: your posts, comments, '
              'messages, calendar entries, contacts and lists. This cannot '
              'be undone.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Your password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onSubmitted: (_) => _delete(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete forever'),
        ),
      ],
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
