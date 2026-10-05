import '../models/direct_message.dart';

abstract class MessageRepository {
  /// Inbox rows for [userId] (private chats and groups), newest first.
  List<ConversationSummary> getConversations(String userId);

  /// The group record for [chatId], or null for a private chat.
  Chat? getChat(String chatId);

  /// Every message [userId] can see in [chatId], oldest first.
  List<ChatMessage> getMessages(String chatId, String userId);

  /// Sends a message. For a private chat the recipient comes from the id; for
  /// a group it is everyone currently in the group.
  ChatMessage send({
    required String chatId,
    required String senderId,
    required String text,
  });

  /// Marks everything in [chatId] as read by [userId].
  void markRead(String chatId, String userId);

  int unreadCountFor(String userId);

  Chat createGroup({
    required String creatorId,
    required String name,
    required Set<String> memberIds,
  });

  void renameGroup(String chatId, String name);
  void addMembers(String chatId, Set<String> userIds);
  void leaveGroup(String chatId, String userId);

  Stream<void> get changes;
}
