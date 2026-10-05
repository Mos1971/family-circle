import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/direct_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/conversation_avatar.dart';
import '../../widgets/empty_state.dart';

/// Inbox: private chats and group chats in one list, newest first.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  void _newChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('New message'),
                subtitle: const Text('A private chat with one person'),
                onTap: () {
                  Navigator.of(sheet).pop();
                  context.push('/messages/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: const Text('New group'),
                subtitle: const Text('Chat with several people at once'),
                onTap: () {
                  Navigator.of(sheet).pop();
                  context.push('/messages/group/new');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        onPressed: () => _newChat(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New chat'),
      ),
      body: conversations.isEmpty
          ? const EmptyState(
              emoji: '✉️',
              title: 'No messages yet',
              subtitle:
                  'Start a private chat with someone, or make a group for '
                  'the whole family.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = conversations[i];
                final other = c.otherUserId == null
                    ? null
                    : users.getById(c.otherUserId!);
                final unread = c.unreadCount > 0;
                final last = c.lastMessage;

                final title = c.isGroup
                    ? c.groupName
                    : (other == null
                          ? 'Member'
                          : other.familyName.isEmpty
                          ? other.firstName
                          : '${other.firstName} · ${other.familyName}');

                String preview;
                if (last == null) {
                  preview = 'No messages yet';
                } else {
                  final mine = last.senderId == me.id;
                  final who = mine
                      ? 'You: '
                      : (c.isGroup
                            ? '${users.getById(last.senderId)?.firstName ?? 'Someone'}: '
                            : '');
                  preview = '$who${last.text}';
                }

                return ListTile(
                  leading: ConversationAvatar(isGroup: c.isGroup, user: other),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    preview,
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
                      if (c.lastActivity != null)
                        Text(
                          timeAgo(c.lastActivity!),
                          style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onGold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => context.push(_routeFor(c)),
                );
              },
            ),
    );
  }

  String _routeFor(ConversationSummary c) => c.isGroup
      ? '/messages/group/${c.chatId}'
      : '/messages/dm/${c.otherUserId}';
}
