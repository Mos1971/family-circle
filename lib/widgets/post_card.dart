import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'member_avatar.dart';
import 'reaction_bar.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.showCommentLink = true});

  final Post post;
  final bool showCommentLink;

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final feed = context.read<FeedProvider>();
    final author = users.getById(post.authorId);
    final me = auth.currentUser;
    final isWelcome = post.type != PostType.normal;
    final commentCount = feed.getComments(post.id).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MemberAvatar(user: author, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.firstName ?? 'A member',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (me != null && (post.authorId == me.id || me.isAdmin))
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: AppColors.muted),
                    onSelected: (v) {
                      if (v == 'delete') {
                        feed.deletePost(post.id, me.id);
                      } else if (v == 'report') {
                        feed.reportPost(post.id, me.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post reported to the admins.'),
                          ),
                        );
                      }
                    },
                    itemBuilder: (c) => [
                      if (post.authorId == me.id || me.isAdmin)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete post'),
                        ),
                      if (post.authorId != me.id)
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Report post'),
                        ),
                    ],
                  )
                else if (me != null && post.authorId != me.id)
                  IconButton(
                    icon: Icon(
                      Icons.flag_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () {
                      feed.reportPost(post.id, me.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post reported to the admins.'),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (isWelcome)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.text,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  post.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ReactionBar(
                    reactions: post.reactions,
                    myReaction: me == null ? null : post.userReaction(me.id),
                    onTap: (type) {
                      if (me == null) return;
                      feed.toggleReaction(post.id, me.id, type);
                    },
                  ),
                ),
                if (showCommentLink)
                  TextButton.icon(
                    onPressed: () => context.push('/feed/post/${post.id}'),
                    icon: const Icon(Icons.mode_comment_outlined, size: 18),
                    label: Text(
                      commentCount == 0 ? 'Comment' : '$commentCount',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
