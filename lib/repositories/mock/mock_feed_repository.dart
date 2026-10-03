import '../../models/app_notification.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/reaction.dart';
import '../../models/report.dart';
import '../feed_repository.dart';
import 'mock_backend.dart';

class MockFeedRepository implements FeedRepository {
  MockFeedRepository(this._backend);

  final MockBackend _backend;

  @override
  List<Post> getPosts() => _backend.posts
      .where((p) => !p.hidden)
      .toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Post? getPost(String id) {
    for (final p in _backend.posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Post createPost({
    required String authorId,
    required String text,
    PostType type = PostType.normal,
  }) {
    final post = Post(
      id: _backend.newId(),
      authorId: authorId,
      text: text,
      createdAt: DateTime.now(),
      type: type,
    );
    _backend.posts.insert(0, post);
    final author = _backend.userById(authorId);
    if (author != null) author.postCount += 1;
    _backend.feedChanges.add(null);
    return post;
  }

  @override
  void deletePost(String postId, String requestingUserId) {
    final post = getPost(postId);
    if (post == null) return;
    if (post.authorId != requestingUserId) return;
    _backend.posts.removeWhere((p) => p.id == postId);
    _backend.comments.removeWhere((c) => c.postId == postId);
    _backend.feedChanges.add(null);
  }

  @override
  void toggleReaction(String postId, String userId, ReactionType type) {
    final post = getPost(postId);
    if (post == null) return;
    final alreadyReacted = post.reactions[type]!.contains(userId);
    // A member can only have one active reaction per post.
    for (final set in post.reactions.values) {
      set.remove(userId);
    }
    if (!alreadyReacted) {
      post.reactions[type]!.add(userId);
      if (post.authorId != userId) {
        final author = _backend.userById(post.authorId);
        if (author != null && _backend.prefsFor(author.id).reactionsOn) {
          _backend.notifications.insert(
            0,
            AppNotification(
              id: _backend.newId(),
              userId: author.id,
              type: AppNotificationType.reaction,
              title: '${type.emoji} New reaction',
              body: 'Someone reacted "${type.label}" to your post.',
              createdAt: DateTime.now(),
            ),
          );
          _backend.notificationChanges.add(null);
        }
      }
    }
    _backend.feedChanges.add(null);
  }

  @override
  List<Comment> getComments(String postId) => _backend.comments
      .where((c) => c.postId == postId)
      .toList(growable: false)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Comment addComment({
    required String postId,
    required String authorId,
    required String text,
    String? parentCommentId,
  }) {
    final comment = Comment(
      id: _backend.newId(),
      postId: postId,
      authorId: authorId,
      text: text,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );
    _backend.comments.add(comment);

    final post = getPost(postId);
    if (post != null && post.authorId != authorId) {
      final author = _backend.userById(post.authorId);
      if (author != null && _backend.prefsFor(author.id).commentsOn) {
        _backend.notifications.insert(
          0,
          AppNotification(
            id: _backend.newId(),
            userId: author.id,
            type: AppNotificationType.comment,
            title: '💬 New comment',
            body: 'Someone commented on your post.',
            createdAt: DateTime.now(),
          ),
        );
        _backend.notificationChanges.add(null);
      }
    }
    _backend.feedChanges.add(null);
    return comment;
  }

  @override
  void reportPost(String postId, String reporterId) {
    final post = getPost(postId);
    if (post == null) return;
    post.reportedCount += 1;
    _backend.reports.add(
      ContentReport(
        id: _backend.newId(),
        contentType: ReportedContentType.post,
        contentId: postId,
        reporterId: reporterId,
        createdAt: DateTime.now(),
      ),
    );
    _backend.notifyAdmins(
      type: AppNotificationType.community,
      title: 'Post reported',
      body: 'A member has reported a post for review.',
    );
    _backend.feedChanges.add(null);
  }

  @override
  void reportComment(String commentId, String reporterId) {
    _backend.reports.add(
      ContentReport(
        id: _backend.newId(),
        contentType: ReportedContentType.comment,
        contentId: commentId,
        reporterId: reporterId,
        createdAt: DateTime.now(),
      ),
    );
    _backend.notifyAdmins(
      type: AppNotificationType.community,
      title: 'Comment reported',
      body: 'A member has reported a comment for review.',
    );
    _backend.feedChanges.add(null);
  }

  @override
  List<ContentReport> getOpenReports() => _backend.reports
      .where((r) => !r.resolved)
      .toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  void resolveReport(String reportId, {required bool removeContent}) {
    ContentReport? report;
    for (final r in _backend.reports) {
      if (r.id == reportId) {
        report = r;
        break;
      }
    }
    if (report == null) return;
    report.resolved = true;

    if (removeContent) {
      if (report.contentType == ReportedContentType.post) {
        _backend.posts.removeWhere((p) => p.id == report!.contentId);
        _backend.comments.removeWhere((c) => c.postId == report!.contentId);
      } else {
        _backend.comments.removeWhere((c) => c.id == report!.contentId);
      }
    }
    _backend.feedChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.feedChanges.stream;
}
