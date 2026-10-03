import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';

/// Inbox: one row per person you've exchanged private messages with.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    if (me == null) return const SizedBox.shrink();
    final conversations = context.watch<MessageProvider>().getConversations(
      me.id,
    );
    final users = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/messages/new'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New message'),
      ),
      body: conversations.isEmpty
          ? const EmptyState(
              emoji: '✉️',
              title: 'No messages yet',
              subtitle:
                  'Start a private conversation with anyone in your Family '
                  'Circle.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = conversations[i];
                final other = users.getById(c.otherUserId);
                final unread = c.unreadCount > 0;
                final prefix = c.lastMessage.senderId == me.id ? 'You: ' : '';
                return ListTile(
                  leading: MemberAvatar(user: other, radius: 22),
                  title: Text(
                    other == null
                        ? 'Member'
                        : other.familyName.isEmpty
                        ? other.firstName
                        : '${other.firstName} · ${other.familyName}',
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '$prefix${c.lastMessage.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread ? AppColors.text : AppColors.muted,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeAgo(c.lastMessage.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(height: 6),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.gold,
                          child: Text(
                            '${c.unreadCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onGold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => context.push('/messages/${c.otherUserId}'),
                );
              },
            ),
    );
  }
}
