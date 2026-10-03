import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().currentUser;
    _bioController = TextEditingController(text: me?.bio ?? '');
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
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Edit profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
