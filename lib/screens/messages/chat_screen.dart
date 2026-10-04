import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_back_button.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';

/// Private one-to-one chat. Only the two participants can see it.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUserId});

  final String otherUserId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final MessageProvider _messages;

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

  // Keeps the thread read while it's open, including messages that arrive
  // while the user is looking at it.
  void _markRead() {
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    _messages.markThreadRead(me.id, widget.otherUserId);
  }

  void _send() {
    final me = context.read<AuthProvider>().currentUser;
    final text = _controller.text.trim();
    if (me == null || text.isEmpty) return;
    try {
      _messages.send(
        senderId: me.id,
        recipientId: widget.otherUserId,
        text: text,
      );
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
        const SnackBar(content: Text('That member can\'t be messaged.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final other = context.watch<UserProvider>().getById(widget.otherUserId);
    if (me == null) return const SizedBox.shrink();

    if (other == null || !other.isApproved) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: const EmptyState(emoji: '✉️', title: 'Member not available'),
      );
    }

    final thread = context.watch<MessageProvider>().getThread(me.id, other.id);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: InkWell(
          onTap: () => context.push('/members/${other.id}'),
          child: Row(
            children: [
              MemberAvatar(user: other, radius: 16),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other.firstName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (other.familyName.isNotEmpty)
                      Text(
                        other.familyName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceHigh,
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.gold),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Private — only you and this member can see this chat.',
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
                        'Say hello to ${other.firstName} 👋',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: thread.length,
                    itemBuilder: (context, i) {
                      final m = thread[i];
                      return _Bubble(
                        text: m.text,
                        time: timeAgo(m.createdAt),
                        mine: m.senderId == me.id,
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
                        hintText: 'Message ${other.firstName}…',
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
  const _Bubble({required this.text, required this.time, required this.mine});

  final String text;
  final String time;
  final bool mine;

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
