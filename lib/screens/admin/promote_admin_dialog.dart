import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/member_avatar.dart';

Future<void> showPromoteAdminDialog(BuildContext context) {
  final users = context.read<UserProvider>();
  final eligible = users
      .getAll()
      .where((u) => u.isApproved && !u.isAdmin)
      .toList();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Add admin'),
        content: SizedBox(
          width: double.maxFinite,
          child: eligible.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No other approved members to promote.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: eligible.map((u) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: MemberAvatar(user: u, radius: 18),
                      title: Text(u.firstName),
                      subtitle: Text(
                        u.email,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        final ok = context.read<UserProvider>().promoteToAdmin(
                          u.id,
                        );
                        Navigator.of(dialogContext).pop();
                        _showResult(context, ok, u);
                      },
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

void _showResult(BuildContext context, bool ok, AppUser user) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? '${user.firstName} is now a Family Circle admin.'
            : 'Could not promote ${user.firstName} — maximum of $kMaxAdmins admins reached.',
      ),
    ),
  );
}
