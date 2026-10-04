import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_back_button.dart';

import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/empty_state.dart';
import 'announcement_editor.dart';

class AnnouncementsListScreen extends StatelessWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = context.watch<AnnouncementProvider>().getAll();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Announcements'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => showAnnouncementEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
      body: announcements.isEmpty
          ? const EmptyState(emoji: '📢', title: 'No announcements yet')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: announcements.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = announcements[i];
                return AnnouncementCard(
                  announcement: a,
                  onTap: () => context.push('/announcements/${a.id}'),
                );
              },
            ),
    );
  }
}
