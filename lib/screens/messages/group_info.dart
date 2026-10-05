import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/member_avatar.dart';

/// Bottom sheet showing who is in a group, with add / rename / leave.
Future<void> showGroupInfo(BuildContext context, String chatId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => _GroupInfo(chatId: chatId, sheetContext: sheet),
  );
}

class _GroupInfo extends StatelessWidget {
  const _GroupInfo({required this.chatId, required this.sheetContext});

  final String chatId;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final messages = context.watch<MessageProvider>();
    final users = context.watch<UserProvider>();
    final chat = messages.getChat(chatId);
    if (me == null || chat == null) return const SizedBox(height: 120);
    final isCreator = chat.createdBy == me.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chat.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isCreator)
                  IconButton(
                    tooltip: 'Rename',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _rename(context, chat.name),
                  ),
              ],
            ),
            Text(
              '${chat.participants.length} people · only they can see this chat',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            for (final id in chat.participants)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MemberAvatar(user: users.getById(id), radius: 18),
                title: Text(
                  id == me.id
                      ? 'You'
                      : (users.getById(id)?.firstName ?? 'Member'),
                ),
                subtitle: id == chat.createdBy
                    ? Text(
                        'Started this group',
                        style: TextStyle(color: AppColors.gold, fontSize: 12),
                      )
                    : null,
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add people'),
              onPressed: () => _addPeople(context, chat.participants),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.logout),
              label: const Text('Leave group'),
              onPressed: () => _leave(context, me.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, String current) async {
    final provider = context.read<MessageProvider>();
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename group'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      provider.renameGroup(chatId, name.trim());
    }
  }

  Future<void> _addPeople(BuildContext context, List<String> current) async {
    final provider = context.read<MessageProvider>();
    final candidates = context
        .read<UserProvider>()
        .getAll()
        .where((u) => u.isApproved && !current.contains(u.id))
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Everyone is already in this group.')),
      );
      return;
    }
    final picked = <String>{};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Add people'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'New people only see messages sent after they join.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
                for (final u in candidates)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: picked.contains(u.id),
                    onChanged: (v) => setDialog(
                      () => v == true ? picked.add(u.id) : picked.remove(u.id),
                    ),
                    secondary: MemberAvatar(user: u, radius: 16),
                    title: Text(u.firstName),
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
              onPressed: () => Navigator.of(ctx).pop(picked),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      provider.addMembers(chatId, result);
    }
  }

  Future<void> _leave(BuildContext context, String myId) async {
    final provider = context.read<MessageProvider>();
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this group?'),
        content: const Text(
          'You won\'t get new messages from it. Someone can add you back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok == true) {
      provider.leaveGroup(chatId, myId);
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      router.go('/messages');
    }
  }
}
