import 'package:flutter/foundation.dart';

import '../models/direct_message.dart';
import '../repositories/message_repository.dart';

class MessageProvider extends ChangeNotifier {
  MessageProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final MessageRepository _repo;

  List<ConversationSummary> getConversations(String userId) =>
      _repo.getConversations(userId);

  List<DirectMessage> getThread(String userId, String otherUserId) =>
      _repo.getThread(userId, otherUserId);

  DirectMessage send({
    required String senderId,
    required String recipientId,
    required String text,
  }) => _repo.send(senderId: senderId, recipientId: recipientId, text: text);

  void markThreadRead(String userId, String otherUserId) =>
      _repo.markThreadRead(userId, otherUserId);

  int unreadCountFor(String userId) => _repo.unreadCountFor(userId);
}
