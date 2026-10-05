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

  Chat? getChat(String chatId) => _repo.getChat(chatId);

  List<ChatMessage> getMessages(String chatId, String userId) =>
      _repo.getMessages(chatId, userId);

  ChatMessage send({
    required String chatId,
    required String senderId,
    required String text,
  }) => _repo.send(chatId: chatId, senderId: senderId, text: text);

  void markRead(String chatId, String userId) => _repo.markRead(chatId, userId);

  int unreadCountFor(String userId) => _repo.unreadCountFor(userId);

  Chat createGroup({
    required String creatorId,
    required String name,
    required Set<String> memberIds,
  }) =>
      _repo.createGroup(creatorId: creatorId, name: name, memberIds: memberIds);

  void renameGroup(String chatId, String name) =>
      _repo.renameGroup(chatId, name);
  void addMembers(String chatId, Set<String> userIds) =>
      _repo.addMembers(chatId, userIds);
  void leaveGroup(String chatId, String userId) =>
      _repo.leaveGroup(chatId, userId);
}
