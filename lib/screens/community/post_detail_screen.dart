import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startReply(Comment c, String? name) {
    setState(() {
      _replyingToCommentId = c.id;
      _replyingToName = name;
    });
  }

  void _submitComment() {
    final auth = context.read<AuthProvider>();
    final text = _commentController.text.trim();
    if (text.isEmpty || auth.currentUser == null) return;
    context.read<FeedProvider>().addComment(
      postId: widget.postId,
      authorId: auth.currentUser!.id,
      text: text,
      parentCommentId: _replyingToCommentId,
    );
    _commentController.clear();
    setState(() {
      _replyingToCommentId = null;
      _replyingToName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    final post = feed.getPost(widget.postId);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const EmptyState(emoji: '🙈', title: 'This post is no longer available'),
      );
    }

    final allComments = feed.getComments(widget.postId);
    final topLevel = allComments.where((c) => !c.isReply).toList();
    Map<String, List<Comment>> repliesByParent = {};
    for (final c in allComments.where((c) => c.isReply)) {
      repliesByParent.putIfAbsent(c.parentCommentId!, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                PostCard(post: post, showCommentLink: false),
                const SizedBox(height: 8),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (topLevel.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No comments yet — be the first to say something.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                for (final c in topLevel) ...[
                  _CommentTile(
                    comment: c,
                    onReply: (name) => _startReply(c, name),
                  ),
                  for (final r in repliesByParent[c.id] ?? [])
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: _CommentTile(
                        comment: r,
                        onReply: (name) => _startReply(c, name),
                      ),
                    ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingToCommentId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Row(
                        children: [
                          Text(
                            'Replying to ${_replyingToName ?? 'comment'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _replyingToCommentId = null;
                              _replyingToName = null;
                            }),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment…',
                          ),
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onReply});

  final Comment comment;
  final ValueChanged<String?> onReply;

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final author = users.getById(comment.authorId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(user: author, radius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.firstName ?? 'A member',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(comment.text),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Row(
                    children: [
                      Text(
                        timeAgo(comment.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => onReply(author?.firstName),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      if (auth.currentUser?.id != comment.authorId) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            context.read<FeedProvider>().reportComment(
                              comment.id,
                              auth.currentUser!.id,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comment reported to the admins.'),
                              ),
                            );
                          },
                          child: const Text(
                            'Report',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
