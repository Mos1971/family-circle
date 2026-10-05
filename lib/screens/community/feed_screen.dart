import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  void _openComposer(BuildContext context) {
    final controller = TextEditingController();
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with the family',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "What's happening in your family today?",
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty || auth.currentUser == null) return;
                      context.read<FeedProvider>().createPost(
                        authorId: auth.currentUser!.id,
                        text: text,
                      );
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<FeedProvider>().getPosts();

    return Scaffold(
      appBar: AppBar(title: const Text('Family Feed')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openComposer(context),
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: posts.isEmpty
          ? const EmptyState(
              emoji: '💬',
              title: 'No posts yet',
              subtitle: 'Be the first to share something with the family.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => PostCard(post: posts[i]),
            ),
    );
  }
}
