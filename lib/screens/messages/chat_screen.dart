import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/direct_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/conversation_avatar.dart';
import '../../widgets/empty_state.dart';
import 'group_info.dart';

/// A chat: either private (give [dmUserId]) or a group (give [groupId]).
/// Only the people in the conversation can see it.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.dmUserId, this.groupId})
    : assert(dmUserId != null || groupId != null);

  final String? dmUserId;
  final String? groupId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final MessageProvider _messages;

  bool get _isGroup => widget.groupId != null;

  String _chatId(String myId) =>
      _isGroup ? widget.groupId! : dmChatId(myId, widget.dmUserId!);

  @override
  void initState() {
    super.initState();
    _messages = context.read<MessageProvider>();
    _messages.addListener(_markRead);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _messages.removeListener(_markRead);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Keeps the chat read while it's open, including messages that arrive while
  // the person is looking at it.
  void _markRead() {
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    _messages.markRead(_chatId(me.id), me.id);
  }

  void _send() {
    final me = context.read<AuthProvider>().currentUser;
    final text = _controller.text.trim();
    if (me == null || text.isEmpty) return;
    try {
      _messages.send(chatId: _chatId(me.id), senderId: me.id, text: text);
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isGroup
                ? 'You can\'t message this group.'
                : 'That member can\'t be messaged.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final users = context.watch<UserProvider>();
    final provider = context.watch<MessageProvider>();
    if (me == null) return const SizedBox.shrink();

    final chatId = _chatId(me.id);
    final other = _isGroup ? null : users.getById(widget.dmUserId!);
    final chat = _isGroup ? provider.getChat(widget.groupId!) : null;

    final unavailable = _isGroup
        ? (chat == null || !chat.participants.contains(me.id))
        : (other == null || !other.isApproved);
    if (unavailable) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: EmptyState(
          emoji: '✉️',
          title: _isGroup ? 'Group not available' : 'Member not available',
        ),
      );
    }

    final thread = provider.getMessages(chatId, me.id);
    final title = _isGroup ? chat!.name : other!.firstName;
    final subtitle = _isGroup
        ? '${chat!.participants.length} people'
        : other!.familyName;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: InkWell(
          onTap: () => _isGroup
              ? showGroupInfo(context, widget.groupId!)
              : context.push('/members/${other!.id}'),
          child: Row(
            children: [
              ConversationAvatar(isGroup: _isGroup, user: other, radius: 16),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_isGroup)
            IconButton(
              tooltip: 'Group info',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showGroupInfo(context, widget.groupId!),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceHigh,
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isGroup
                        ? 'Private — only the ${chat!.participants.length} '
                              'people in this group can see this chat.'
                        : 'Private — only you and this member can see this chat.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: thread.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _isGroup
                            ? 'Say hello to the group 👋'
                            : 'Say hello to ${other!.firstName} 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: thread.length,
                    itemBuilder: (context, i) {
                      final m = thread[i];
                      final mine = m.senderId == me.id;
                      return _Bubble(
                        text: m.text,
                        time: timeAgo(m.createdAt),
                        mine: mine,
                        // In a group, say who wrote each message.
                        sender: _isGroup && !mine
                            ? (users.getById(m.senderId)?.firstName ??
                                  'Someone')
                            : null,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _isGroup
                            ? 'Message the group…'
                            : 'Message ${other!.firstName}…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.onGold,
                    ),
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.time,
    required this.mine,
    this.sender,
  });

  final String text;
  final String time;
  final bool mine;
  final String? sender;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sender != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  sender!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(color: mine ? AppColors.onGold : AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? AppColors.onGold.withValues(alpha: 0.65)
                    : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
