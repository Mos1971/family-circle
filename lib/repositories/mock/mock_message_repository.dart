import '../../models/app_notification.dart';
import '../../models/direct_message.dart';
import '../../models/user.dart';
import '../conversation_logic.dart';
import '../message_repository.dart';
import 'mock_backend.dart';

class MockMessageRepository implements MessageRepository {
  MockMessageRepository(this._backend);

  final MockBackend _backend;

  @override
  List<ConversationSummary> getConversations(String userId) =>
      buildConversations(userId, _backend.messages, _backend.chats);

  @override
  Chat? getChat(String chatId) {
    for (final c in _backend.chats) {
      if (c.id == chatId) return c;
    }
    return null;
  }

  @override
  List<ChatMessage> getMessages(String chatId, String userId) =>
      messagesFor(chatId, userId, _backend.messages);

  @override
  ChatMessage send({
    required String chatId,
    required String senderId,
    required String text,
  }) {
    final List<String> people;
    if (isDmChatId(chatId)) {
      people = dmParticipants(chatId);
      final other = people.firstWhere((p) => p != senderId);
      final recipient = _backend.userById(other);
      if (recipient == null || recipient.status != MemberStatus.approved) {
        throw StateError('That member is not available to message.');
      }
    } else {
      final chat = getChat(chatId);
      if (chat == null || !chat.participants.contains(senderId)) {
        throw StateError('You are not in this group.');
      }
      people = chat.participants;
    }

    final message = ChatMessage(
      id: _backend.newId(),
      chatId: chatId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      participants: List.of(people),
    );
    _backend.messages.add(message);
    _backend.messageChanges.add(null);

    final sender = _backend.userById(senderId);
    final groupName = getChat(chatId)?.name;
    for (final id in people.where((p) => p != senderId)) {
      if (!_backend.prefsFor(id).messagesOn) continue;
      _backend.notifications.insert(
        0,
        AppNotification(
          id: _backend.newId(),
          userId: id,
          type: AppNotificationType.message,
          title: groupName == null
              ? '✉️ ${sender?.firstName ?? 'Someone'} sent you a message'
              : '💬 ${sender?.firstName ?? 'Someone'} in $groupName',
          body: text,
          createdAt: DateTime.now(),
        ),
      );
    }
    _backend.notificationChanges.add(null);
    return message;
  }

  @override
  void markRead(String chatId, String userId) {
    var changed = false;
    for (final m in _backend.messages) {
      if (m.chatId == chatId && m.isUnreadFor(userId)) {
        m.readBy.add(userId);
        changed = true;
      }
    }
    if (changed) _backend.messageChanges.add(null);
  }

  @override
  int unreadCountFor(String userId) => unreadCount(userId, _backend.messages);

  @override
  Chat createGroup({
    required String creatorId,
    required String name,
    required Set<String> memberIds,
  }) {
    final chat = Chat(
      id: _backend.newId(),
      name: name,
      participants: {creatorId, ...memberIds}.toList(),
      createdBy: creatorId,
      createdAt: DateTime.now(),
    );
    _backend.chats.add(chat);
    _backend.messageChanges.add(null);
    return chat;
  }

  @override
  void renameGroup(String chatId, String name) {
    getChat(chatId)?.name = name;
    _backend.messageChanges.add(null);
  }

  @override
  void addMembers(String chatId, Set<String> userIds) {
    final chat = getChat(chatId);
    if (chat == null) return;
    for (final id in userIds) {
      if (!chat.participants.contains(id)) chat.participants.add(id);
    }
    _backend.messageChanges.add(null);
  }

  @override
  void leaveGroup(String chatId, String userId) {
    getChat(chatId)?.participants.remove(userId);
    _backend.messageChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.messageChanges.stream;
}
