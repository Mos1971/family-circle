import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_wordmark.dart';
import '../../widgets/auth_frame.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.firstName ?? 'there';

    return AuthFrame(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppWordmark(fontSize: 32),
                const SizedBox(height: 40),
                const Text('⏳', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 20),
                Text(
                  'Thanks, $name!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your request to join Family Circle is being '
                  'reviewed by the admins. This usually only takes a short '
                  'while — we\'ll let you in as soon as it\'s approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
