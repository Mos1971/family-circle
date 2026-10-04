import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/empty_state.dart';
import 'announcement_editor.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  final String announcementId;

  @override
  Widget build(BuildContext context) {
    final announcements = context.watch<AnnouncementProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final matches = announcements.getAll().where((a) => a.id == announcementId);
    final announcement = matches.isEmpty ? null : matches.first;

    if (announcement == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const EmptyState(
          emoji: '📢',
          title: 'This announcement was removed',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        actions: isAdmin
            ? [
                IconButton(
                  icon: Icon(
                    announcement.pinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                  ),
                  tooltip: announcement.pinned ? 'Unpin' : 'Pin',
                  onPressed: () => announcements.setPinned(
                    announcement.id,
                    !announcement.pinned,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      showAnnouncementEditor(context, existing: announcement),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    announcements.delete(announcement.id);
                    context.pop();
                  },
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Text('📢', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'FROM THE ADMINS',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            announcement.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            timeAgo(announcement.createdAt),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Text(
            announcement.body,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
