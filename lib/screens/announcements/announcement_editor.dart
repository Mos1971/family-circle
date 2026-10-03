import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/announcement.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';

Future<void> showAnnouncementEditor(
  BuildContext context, {
  Announcement? existing,
}) {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final bodyController = TextEditingController(text: existing?.body ?? '');
  final announcements = context.read<AnnouncementProvider>();
  final auth = context.read<AuthProvider>();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(existing == null ? 'New announcement' : 'Edit announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) return;
              if (existing == null) {
                announcements.create(
                  title: title,
                  body: body,
                  authorId: auth.currentUser!.id,
                );
              } else {
                announcements.update(existing.id, title: title, body: body);
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
