import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

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
          const Padding(
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
                  ? const Text(
                      'Active',
                      style: TextStyle(color: AppColors.gold, fontSize: 12),
                    )
                  : null,
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
