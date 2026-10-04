import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_wordmark.dart';
import '../../widgets/circle_switcher.dart';
import '../../widgets/auth_frame.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.firstName ?? 'there';
    final removed = auth.currentUser?.status == MemberStatus.rejected;
    final circleName = context.watch<UserProvider>().circle?.name;

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
                  removed ? 'Hi $name' : 'Thanks, $name!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  removed
                      ? 'Your access to ${circleName ?? 'this circle'} has '
                            'ended. Please contact the circle admin if you '
                            'think this is a mistake.'
                      : 'Your request to join ${circleName ?? 'the circle'} '
                            'is waiting for the admin to approve it. We\'ll '
                            'let you in as soon as they do.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: CircleSwitcher(),
                ),
                const SizedBox(height: 20),
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
