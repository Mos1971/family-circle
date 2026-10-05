import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_back_button.dart';

import '../../providers/auth_provider.dart';
import '../../providers/plan_providers.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/member_avatar.dart';

class TodoDetailScreen extends StatefulWidget {
  const TodoDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<TodoProvider>().addItem(widget.listId, text);
    _controller.clear();
  }

  Future<void> _share() async {
    final me = context.read<AuthProvider>().currentUser!;
    final todos = context.read<TodoProvider>();
    final list = todos.getById(widget.listId);
    if (list == null) return;
    final others = context
        .read<UserProvider>()
        .getAll()
        .where((u) => u.isApproved && u.id != me.id)
        .toList();
    final selected = {...list.sharedWith};

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Share this list'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'People you pick can see the list, tick things off and '
                    'add items. Everyone else can\'t see it.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
                for (final u in others)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(u.id),
                    onChanged: (v) => setDialog(
                      () => v == true
                          ? selected.add(u.id)
                          : selected.remove(u.id),
                    ),
                    secondary: MemberAvatar(user: u, radius: 16),
                    title: Text(u.firstName),
                    subtitle: u.familyName.isEmpty ? null : Text(u.familyName),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null) todos.setSharedWith(widget.listId, me.id, result);
  }

  Future<void> _delete() async {
    final me = context.read<AuthProvider>().currentUser!;
    final todos = context.read<TodoProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this list?'),
        content: const Text(
          'It will be removed for you and anyone it\'s shared with.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      todos.delete(widget.listId, me.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final list = context.watch<TodoProvider>().getById(widget.listId);
    final users = context.watch<UserProvider>();

    if (me == null || list == null || !list.canView(me.id)) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: const EmptyState(emoji: '✅', title: 'List not available'),
      );
    }
    final isOwner = list.ownerId == me.id;
    final owner = users.getById(list.ownerId);
    final todos = context.read<TodoProvider>();

    final sharedNames = list.sharedWith
        .map((id) => users.getById(id)?.firstName)
        .whereType<String>()
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(list.title),
        actions: [
          if (isOwner) ...[
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: _share,
            ),
            IconButton(
              tooltip: 'Delete list',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceHigh,
            child: Row(
              children: [
                Icon(
                  isOwner && list.sharedWith.isEmpty
                      ? Icons.lock_outline
                      : Icons.group_outlined,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isOwner
                        ? (list.sharedWith.isEmpty
                              ? 'Private — only you can see this list.'
                              : 'Shared with $sharedNames.')
                        : 'Shared by ${owner?.firstName ?? 'a member'}. '
                              'You can tick items and add new ones.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.items.isEmpty
                ? const EmptyState(
                    emoji: '📝',
                    title: 'Nothing here yet',
                    subtitle: 'Add your first item below.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      for (final item in list.items)
                        Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: AppColors.danger,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) =>
                              todos.removeItem(list.id, item.id),
                          child: CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: item.done,
                            onChanged: (_) =>
                                todos.toggleItem(list.id, item.id),
                            title: Text(
                              item.text,
                              style: TextStyle(
                                decoration: item.done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.done
                                    ? AppColors.muted
                                    : AppColors.text,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Add an item…',
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.onGold,
                    ),
                    onPressed: _add,
                    icon: const Icon(Icons.add),
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
