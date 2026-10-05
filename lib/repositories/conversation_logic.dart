import '../models/direct_message.dart';

/// Shared rules for turning raw messages + group records into inbox rows and
/// per-chat message lists. Used by both the mock and Firebase repositories so
/// they can never disagree.

List<ConversationSummary> buildConversations(
  String me,
  List<ChatMessage> messages,
  List<Chat> chats,
) {
  final byChat = <String, List<ChatMessage>>{};
  for (final m in messages) {
    if (m.participants.contains(me)) {
      byChat.putIfAbsent(m.chatId, () => []).add(m);
    }
  }
  final chatById = {for (final c in chats) c.id: c};
  final rows = <({DateTime when, ConversationSummary summary})>[];

  for (final entry in byChat.entries) {
    final msgs = entry.value
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final unread = msgs.where((m) => m.isUnreadFor(me)).length;
    final chatId = entry.key;
    if (isDmChatId(chatId)) {
      final people = dmParticipants(chatId);
      final other = people.firstWhere((p) => p != me, orElse: () => me);
      rows.add((
        when: msgs.last.createdAt,
        summary: ConversationSummary(
          chatId: chatId,
          isGroup: false,
          participants: people,
          lastMessage: msgs.last,
          unreadCount: unread,
          otherUserId: other,
        ),
      ));
    } else {
      final chat = chatById[chatId];
      // Hide groups the person has left (their old messages stay theirs, but
      // the group no longer appears in their inbox).
      if (chat == null || !chat.participants.contains(me)) continue;
      rows.add((
        when: msgs.last.createdAt,
        summary: ConversationSummary(
          chatId: chatId,
          isGroup: true,
          groupName: chat.name,
          participants: chat.participants,
          lastMessage: msgs.last,
          unreadCount: unread,
        ),
      ));
    }
  }

  // Groups nobody has written in yet still belong in the inbox.
  for (final chat in chats) {
    if (!chat.participants.contains(me) || byChat.containsKey(chat.id)) {
      continue;
    }
    rows.add((
      when: chat.createdAt,
      summary: ConversationSummary(
        chatId: chat.id,
        isGroup: true,
        groupName: chat.name,
        participants: chat.participants,
        unreadCount: 0,
      ),
    ));
  }

  rows.sort((a, b) => b.when.compareTo(a.when));
  return [for (final r in rows) r.summary];
}

List<ChatMessage> messagesFor(
  String chatId,
  String me,
  List<ChatMessage> messages,
) =>
    messages
        .where((m) => m.chatId == chatId && m.participants.contains(me))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

int unreadCount(String me, List<ChatMessage> messages) =>
    messages.where((m) => m.isUnreadFor(me)).length;
