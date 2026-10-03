import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/member_avatar.dart';

/// Directory of approved members, grouped by family. Used both as the
/// "Family" tab (tap = view profile) and as the recipient picker for a new
/// private message ([pickToMessage] = true, tap = open chat).
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, this.pickToMessage = false});

  final bool pickToMessage;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final all = context
        .watch<UserProvider>()
        .getAll()
        .where((u) => u.isApproved && u.id != me?.id)
        .where((u) {
          final q = _query.toLowerCase();
          return q.isEmpty ||
              u.firstName.toLowerCase().contains(q) ||
              u.familyName.toLowerCase().contains(q);
        })
        .toList();

    final families = <String, List<AppUser>>{};
    for (final u in all) {
      families
          .putIfAbsent(u.familyName.isEmpty ? 'Other' : u.familyName, () => [])
          .add(u);
    }
    final names = families.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        leading: (widget.pickToMessage || context.canPop())
            ? BackButton(onPressed: () => context.pop())
            : null,
        title: Text(widget.pickToMessage ? 'New message' : 'Family'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.muted),
                hintText: 'Search people or families',
              ),
            ),
          ),
          Expanded(
            child: names.isEmpty
                ? const Center(
                    child: Text(
                      'No one found.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final family in names) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                          child: Text(
                            family.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        for (final u in families[family]!)
                          ListTile(
                            leading: MemberAvatar(user: u, radius: 22),
                            title: Text(u.firstName),
                            subtitle: u.isAdmin
                                ? const Text(
                                    'Circle admin',
                                    style: TextStyle(color: AppColors.gold),
                                  )
                                : (u.bio.isEmpty
                                      ? null
                                      : Text(
                                          u.bio,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                            trailing: widget.pickToMessage
                                ? const Icon(Icons.chevron_right)
                                : IconButton(
                                    tooltip: 'Message ${u.firstName}',
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    onPressed: () =>
                                        context.push('/messages/${u.id}'),
                                  ),
                            onTap: () => widget.pickToMessage
                                ? context.pushReplacement('/messages/${u.id}')
                                : context.push('/members/${u.id}'),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
