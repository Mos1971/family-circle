import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_back_button.dart';

import '../../models/notification_prefs.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_prefs_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prefsProvider = context.watch<NotificationPrefsProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return const SizedBox.shrink();
    final prefs = prefsProvider.getFor(userId);

    void mutate(void Function(NotificationPrefs) fn) {
      context.read<NotificationPrefsProvider>().update(userId, fn);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Text('✉️', style: TextStyle(fontSize: 20)),
            title: const Text('Private messages'),
            value: prefs.messagesOn,
            onChanged: (v) => mutate((p) => p.messagesOn = v),
          ),
          SwitchListTile(
            secondary: const Text('📅', style: TextStyle(fontSize: 20)),
            title: const Text('New family events'),
            value: prefs.calendarOn,
            onChanged: (v) => mutate((p) => p.calendarOn = v),
          ),
          SwitchListTile(
            secondary: const Text('✅', style: TextStyle(fontSize: 20)),
            title: const Text('Lists shared with me'),
            value: prefs.listsOn,
            onChanged: (v) => mutate((p) => p.listsOn = v),
          ),
          SwitchListTile(
            secondary: const Text('📢', style: TextStyle(fontSize: 20)),
            title: const Text('Admin announcements'),
            value: prefs.announcementsOn,
            onChanged: (v) => mutate((p) => p.announcementsOn = v),
          ),
          SwitchListTile(
            secondary: const Text('💬', style: TextStyle(fontSize: 20)),
            title: const Text('Comments on my posts'),
            value: prefs.commentsOn,
            onChanged: (v) => mutate((p) => p.commentsOn = v),
          ),
          SwitchListTile(
            secondary: const Text('❤️', style: TextStyle(fontSize: 20)),
            title: const Text('Reactions to my posts'),
            value: prefs.reactionsOn,
            onChanged: (v) => mutate((p) => p.reactionsOn = v),
          ),
          SwitchListTile(
            secondary: const Text('👋', style: TextStyle(fontSize: 20)),
            title: const Text('Family activity'),
            subtitle: const Text('New members joining the circle'),
            value: prefs.communityOn,
            onChanged: (v) => mutate((p) => p.communityOn = v),
          ),
        ],
      ),
    );
  }
}
