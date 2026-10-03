import '../models/comment.dart';
import '../models/post.dart';
import '../models/reaction.dart';
import '../models/report.dart';

abstract class FeedRepository {
  List<Post> getPosts();
  Post? getPost(String id);
  Post createPost({
    required String authorId,
    required String text,
    PostType type = PostType.normal,
  });
  void deletePost(String postId, String requestingUserId);
  void toggleReaction(String postId, String userId, ReactionType type);

  List<Comment> getComments(String postId);
  Comment addComment({
    required String postId,
    required String authorId,
    required String text,
    String? parentCommentId,
  });

  void reportPost(String postId, String reporterId);
  void reportComment(String commentId, String reporterId);
  List<ContentReport> getOpenReports();
  void resolveReport(String reportId, {required bool removeContent});

  Stream<void> get changes;
}
