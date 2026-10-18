import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/reaction.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

/// "Anna, Tom and 2 others reacted" line under a post. Tapping it lists
/// everyone with the reaction they chose.
class ReactionSummary extends StatelessWidget {
  const ReactionSummary({super.key, required this.post});

  final Post post;

  List<({String userId, ReactionType type})> _all() => [
    for (final entry in post.reactions.entries)
      for (final id in entry.value) (userId: id, type: entry.key),
  ];

  @override
  Widget build(BuildContext context) {
    final all = _all();
    if (all.isEmpty) return const SizedBox.shrink();

    final users = context.watch<UserProvider>();
    final myId = context.watch<AuthProvider>().currentUser?.id;

    String nameOf(String id) =>
        id == myId ? 'You' : (users.getById(id)?.firstName ?? 'A member');

    // You first, then the others in the order they reacted.
    all.sort((a, b) => (a.userId == myId ? 0 : 1) - (b.userId == myId ? 0 : 1));
    final shown = all.take(2).toList();
    final more = all.length - shown.length;
    final names = shown.map((r) => nameOf(r.userId)).toList();
    final label = more > 0
        ? '${names.join(', ')} and $more other${more == 1 ? '' : 's'}'
        : names.length == 2
        ? '${names[0]} and ${names[1]}'
        : names.first;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showReactionList(context, post),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Overlapping avatars of the first few people.
              SizedBox(
                height: 24,
                width: 24.0 + (all.take(3).length - 1) * 15,
                child: Stack(
                  children: [
                    for (var i = 0; i < all.take(3).length; i++)
                      Positioned(
                        left: i * 15.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: MemberAvatar(
                            user: users.getById(all[i].userId),
                            radius: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with everyone who reacted and what they chose.
Future<void> showReactionList(BuildContext context, Post post) {
  final users = context.read<UserProvider>();
  final myId = context.read<AuthProvider>().currentUser?.id;
  final rows = [
    for (final entry in post.reactions.entries)
      for (final id in entry.value) (userId: id, type: entry.key),
  ];

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reactions', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final r in rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: MemberAvatar(user: users.getById(r.userId)),
                    title: Text(
                      r.userId == myId
                          ? 'You'
                          : (users.getById(r.userId)?.firstName ?? 'A member'),
                    ),
                    trailing: Text(
                      r.type.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
