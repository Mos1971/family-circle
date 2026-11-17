import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/circle.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

Future<void> _confirmLeave(BuildContext context, CircleRef circle) async {
  final users = context.read<UserProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Leave "${circle.name}"?'),
      content: const Text(
        'You will be removed from this circle and everything you created in '
        'it (posts, comments, messages, calendar entries, contacts and '
        'lists) will be deleted. Your other circles are not affected. This '
        'cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Leave circle'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final error = await users.leaveCircle(circle.id);
  messenger.showSnackBar(
    SnackBar(content: Text(error ?? 'You left "${circle.name}".')),
  );
}

/// "Your circles" card: shows every circle the person belongs to, lets them
/// switch the active one, and join/start another.
class CircleSwitcher extends StatelessWidget {
  const CircleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final active = users.circle?.id;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'YOUR CIRCLES',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          for (final c in users.myCircles)
            ListTile(
              leading: Icon(
                c.id == active
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: c.id == active ? AppColors.gold : AppColors.muted,
              ),
              title: Text(c.name),
              subtitle: c.id == active
                  ? Text(
                      'Active',
                      style: TextStyle(color: AppColors.gold, fontSize: 12),
                    )
                  : null,
              trailing: PopupMenuButton<String>(
                tooltip: 'Circle options',
                icon: Icon(Icons.more_vert, color: AppColors.muted),
                onSelected: (_) => _confirmLeave(context, c),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'leave',
                    child: Text(
                      'Leave this circle',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
              onTap: c.id == active ? null : () => users.switchCircle(c.id),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Join or start another circle'),
            onTap: () => context.push('/circles/add'),
          ),
        ],
      ),
    );
  }
}
