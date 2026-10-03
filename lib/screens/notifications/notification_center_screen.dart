import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/empty_state.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final userId = auth.currentUser?.id;
    final items = userId == null ? <AppNotification>[] : notifications.getFor(userId);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Notifications'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => notifications.markAllRead(userId!),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              emoji: '🔔',
              title: 'You\'re all caught up',
              subtitle: 'Community activity will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                return ListTile(
                  onTap: () => notifications.markRead(n.id),
                  leading: CircleAvatar(
                    backgroundColor: n.read
                        ? AppColors.border
                        : AppColors.gold.withValues(alpha: 0.15),
                    child: Text(n.emoji),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(n.body),
                  trailing: Text(
                    timeAgo(n.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  isThreeLine: n.body.length > 40,
                );
              },
            ),
    );
  }
}
