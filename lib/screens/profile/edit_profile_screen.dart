import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

/// Pictures a member can pick for their profile.
const kAvatarChoices = [
  '🏡', '👑', '🌻', '🌟', '🌱', '⚽', '🎸', '🎨',
  '🐶', '🐱', '🦊', '🐼', '🦁', '🐯', '🐸', '🦉',
  '🦋', '🐢', '🐬', '🦄', '🐝', '🐧', '🐰', '🐨',
  '🍕', '🍰', '☕', '🍎', '🌈', '🔥', '🌙', '☀️',
  '🚀', '🎮', '📚', '🎧', '⚓', '🌴', '🏔️', '💎',
];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _bioController;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().currentUser;
    _bioController = TextEditingController(text: me?.bio ?? '');
    _emoji = me?.profileEmoji ?? kAvatarChoices.first;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Edit profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                child: Text(_emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose your picture',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kAvatarChoices)
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e == _emoji
                            ? AppColors.gold.withValues(alpha: 0.18)
                            : AppColors.surfaceHigh,
                        border: Border.all(
                          color: e == _emoji ? AppColors.gold : AppColors.border,
                          width: e == _emoji ? 2 : 1,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('First name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(me?.firstName ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text('Short bio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 120,
              decoration: const InputDecoration(
                hintText: 'Tell the community a little about yourself',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: me == null
                    ? null
                    : () {
                        context.read<UserProvider>().updateProfile(
                          me.id,
                          bio: _bioController.text.trim(),
                          profileEmoji: _emoji,
                        );
                        context.pop();
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
