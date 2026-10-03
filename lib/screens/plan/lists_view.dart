import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/plan_providers.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class ListsView extends StatelessWidget {
  const ListsView({super.key});

  Future<void> _newList(BuildContext context) async {
    final me = context.read<AuthProvider>().currentUser;
    final todos = context.read<TodoProvider>();
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New list'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Weekly shop'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty || me == null) return;
    final list = todos.create(ownerId: me.id, title: title.trim());
    if (context.mounted) context.push('/lists/${list.id}');
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    if (me == null) return const SizedBox.shrink();
    final lists = context.watch<TodoProvider>().getFor(me.id);
    final users = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newList(context),
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
      body: lists.isEmpty
          ? const EmptyState(
              emoji: '✅',
              title: 'No lists yet',
              subtitle:
                  'Lists are private to you. Share one with a family member '
                  'when you want to tackle it together.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: lists.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final l = lists[i];
                final owner = users.getById(l.ownerId);
                final mineList = l.ownerId == me.id;
                final progress = l.items.isEmpty
                    ? 0.0
                    : l.doneCount / l.items.length;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => context.push('/lists/${l.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Icon(
                                mineList && l.sharedWith.isEmpty
                                    ? Icons.lock_outline
                                    : Icons.group_outlined,
                                size: 18,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mineList
                                ? (l.sharedWith.isEmpty
                                      ? 'Private'
                                      : 'Shared with ${l.sharedWith.length}')
                                : 'Shared by ${owner?.firstName ?? 'a member'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${l.doneCount} of ${l.items.length} done',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
