/// One message in a private one-to-one conversation between two members.
/// A conversation is just the messages between a given pair of people and is
/// only ever visible to those two.
class DirectMessage {
  DirectMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime createdAt;
  bool read;

  bool between(String a, String b) =>
      (senderId == a && recipientId == b) ||
      (senderId == b && recipientId == a);

  bool involves(String userId) => senderId == userId || recipientId == userId;

  String otherParty(String userId) =>
      senderId == userId ? recipientId : senderId;
}

/// A row in the inbox: the other person, the latest message, and how many of
/// their messages are still unread.
class ConversationSummary {
  const ConversationSummary({
    required this.otherUserId,
    required this.lastMessage,
    required this.unreadCount,
  });

  final String otherUserId;
  final DirectMessage lastMessage;
  final int unreadCount;
}
