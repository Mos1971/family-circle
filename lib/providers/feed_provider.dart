import 'package:flutter/foundation.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/report.dart';
import '../repositories/feed_repository.dart';

class FeedProvider extends ChangeNotifier {
  FeedProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final FeedRepository _repo;

  List<Post> getPosts() => _repo.getPosts();
  Post? getPost(String id) => _repo.getPost(id);

  Post createPost({
    required String authorId,
    required String text,
    PostType type = PostType.normal,
  }) => _repo.createPost(authorId: authorId, text: text, type: type);

  void deletePost(String postId, String requestingUserId) =>
      _repo.deletePost(postId, requestingUserId);

  void toggleReaction(String postId, String userId, ReactionType type) =>
      _repo.toggleReaction(postId, userId, type);

  List<Comment> getComments(String postId) => _repo.getComments(postId);

  Comment addComment({
    required String postId,
    required String authorId,
    required String text,
    String? parentCommentId,
  }) => _repo.addComment(
    postId: postId,
    authorId: authorId,
    text: text,
    parentCommentId: parentCommentId,
  );

  void reportPost(String postId, String reporterId) =>
      _repo.reportPost(postId, reporterId);

  void reportComment(String commentId, String reporterId) =>
      _repo.reportComment(commentId, reporterId);

  List<ContentReport> getOpenReports() => _repo.getOpenReports();

  void resolveReport(String reportId, {required bool removeContent}) =>
      _repo.resolveReport(reportId, removeContent: removeContent);
}
