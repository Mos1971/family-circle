import '../models/direct_message.dart';

abstract class MessageRepository {
  /// Inbox rows for [userId], newest conversation first.
  List<ConversationSummary> getConversations(String userId);

  /// Every message between [userId] and [otherUserId], oldest first.
  List<DirectMessage> getThread(String userId, String otherUserId);

  DirectMessage send({
    required String senderId,
    required String recipientId,
    required String text,
  });

  /// Marks everything [otherUserId] sent to [userId] as read.
  void markThreadRead(String userId, String otherUserId);

  int unreadCountFor(String userId);

  Stream<void> get changes;
}
