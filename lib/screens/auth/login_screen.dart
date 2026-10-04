import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../app_mode.dart';
import '../../repositories/mock/mock_backend.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_wordmark.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/auth_frame.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await context.read<AuthProvider>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      final error = context.read<AuthProvider>().error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error ?? 'Could not log in.')));
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final auth = context.read<AuthProvider>();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset your password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email and we\x27ll send you a link to choose a new password.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty || !mounted) return;
    String message =
        'If that email has an account, a reset link is on its way. '
        'Check your spam folder too.';
    try {
      await auth.sendPasswordReset(email.trim());
    } catch (e) {
      message = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              isDesktopWidth(context) ? 96 : 40,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppWordmark(fontSize: 44),
                const SizedBox(height: 6),
                const Text(
                  'Your family. Your circle.',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onGold,
                            ),
                          )
                        : const Text('Log in'),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('New here? Join or start a circle'),
                  ),
                ),
                const SizedBox(height: 32),
                if (context.read<AppMode>().isMock) const _DemoAccounts(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();

  @override
  Widget build(BuildContext context) {
    final backend = context.read<MockBackend>();
    final demoUsers = backend.users
        .where((u) => u.status.name == 'approved')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick demo login',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Skip credentials and explore instantly as a seeded member.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: demoUsers.map((u) {
              return ActionChip(
                avatar: Text(u.profileEmoji),
                label: Text(u.isAdmin ? '${u.firstName} (Admin)' : u.firstName),
                onPressed: () => context.read<AuthProvider>().loginAsDemo(u.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
