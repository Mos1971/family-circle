import '../../models/app_notification.dart';
import '../../models/direct_message.dart';
import '../../models/user.dart';
import '../message_repository.dart';
import 'mock_backend.dart';

class MockMessageRepository implements MessageRepository {
  MockMessageRepository(this._backend);

  final MockBackend _backend;

  @override
  List<ConversationSummary> getConversations(String userId) {
    final byOther = <String, List<DirectMessage>>{};
    for (final m in _backend.directMessages) {
      if (!m.involves(userId)) continue;
      byOther.putIfAbsent(m.otherParty(userId), () => []).add(m);
    }
    final rows = byOther.entries.map((e) {
      final msgs = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return ConversationSummary(
        otherUserId: e.key,
        lastMessage: msgs.last,
        unreadCount: msgs
            .where((m) => m.recipientId == userId && !m.read)
            .length,
      );
    }).toList();
    rows.sort(
      (a, b) => b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt),
    );
    return rows;
  }

  @override
  List<DirectMessage> getThread(String userId, String otherUserId) =>
      _backend.directMessages
          .where((m) => m.between(userId, otherUserId))
          .toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  DirectMessage send({
    required String senderId,
    required String recipientId,
    required String text,
  }) {
    final recipient = _backend.userById(recipientId);
    if (recipient == null || recipient.status != MemberStatus.approved) {
      throw StateError('That member is not available to message.');
    }
    final message = DirectMessage(
      id: _backend.newId(),
      senderId: senderId,
      recipientId: recipientId,
      text: text,
      createdAt: DateTime.now(),
    );
    _backend.directMessages.add(message);
    _backend.messageChanges.add(null);

    if (_backend.prefsFor(recipientId).messagesOn) {
      final sender = _backend.userById(senderId);
      _backend.notifications.insert(
        0,
        AppNotification(
          id: _backend.newId(),
          userId: recipientId,
          type: AppNotificationType.message,
          title: '✉️ ${sender?.firstName ?? 'Someone'} sent you a message',
          body: text,
          createdAt: DateTime.now(),
        ),
      );
      _backend.notificationChanges.add(null);
    }
    return message;
  }

  @override
  void markThreadRead(String userId, String otherUserId) {
    var changed = false;
    for (final m in _backend.directMessages) {
      if (m.recipientId == userId && m.senderId == otherUserId && !m.read) {
        m.read = true;
        changed = true;
      }
    }
    if (changed) _backend.messageChanges.add(null);
  }

  @override
  int unreadCountFor(String userId) => _backend.directMessages
      .where((m) => m.recipientId == userId && !m.read)
      .length;

  @override
  Stream<void> get changes => _backend.messageChanges.stream;
}
