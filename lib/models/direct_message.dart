/// Chat id for a private one-to-one conversation: the same two people always
/// get the same id, whichever of them starts it.
String dmChatId(String a, String b) {
  final ids = [a, b]..sort();
  return 'dm|${ids[0]}|${ids[1]}';
}

bool isDmChatId(String chatId) => chatId.startsWith('dm|');

/// The two people in a private conversation, from its id.
List<String> dmParticipants(String chatId) =>
    chatId.split('|').skip(1).toList();

/// A group conversation (three or more people, named). One-to-one chats have
/// no [Chat] record — their id alone says who is in them.
class Chat {
  Chat({
    required this.id,
    required this.name,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  String name;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;

  bool get isGroup => true;
}

/// One message in a conversation. [participants] is who could see the
/// conversation at the time it was sent, so people added to a group later do
/// not see earlier messages.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.participants,
    Set<String>? readBy,
  }) : readBy = readBy ?? {senderId};

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final List<String> participants;

  /// People who have opened it (the sender counts as having read it).
  final Set<String> readBy;

  bool isUnreadFor(String userId) =>
      senderId != userId &&
      participants.contains(userId) &&
      !readBy.contains(userId);
}

/// A row in the inbox: a private chat or a group, its latest message and how
/// many messages in it are still unread for the viewer.
class ConversationSummary {
  const ConversationSummary({
    required this.chatId,
    required this.isGroup,
    required this.participants,
    required this.unreadCount,
    this.groupName = '',
    this.lastMessage,
    this.otherUserId,
  });

  final String chatId;
  final bool isGroup;
  final String groupName;
  final List<String> participants;

  /// Null for a group that has no messages yet.
  final ChatMessage? lastMessage;

  /// The other person, for private chats.
  final String? otherUserId;
  final int unreadCount;

  DateTime? get lastActivity => lastMessage?.createdAt;
}
