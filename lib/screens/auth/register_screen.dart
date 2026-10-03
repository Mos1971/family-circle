import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_wordmark.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _familyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationController = TextEditingController();
  bool _agreedToGuidelines = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _familyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    if (!_agreedToGuidelines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm you agree to the house rules.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await context.read<AuthProvider>().register(
      firstName: _nameController.text.trim(),
      familyName: _familyController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      verificationNote: _verificationController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong, please try again.')),
      );
    }
    // On success, the router redirect takes the new pending user to /pending.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppWordmark(fontSize: 30),
              const SizedBox(height: 6),
              const Text(
                'Request to join your family circle',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _familyController,
                decoration: const InputDecoration(
                  labelText: 'Family name',
                  hintText: 'e.g. The Okafors',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _verificationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Who invited you? (optional)',
                  hintText: 'e.g. the family member who told you about Family Circle',
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'House rules',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Family Circle is a private space for families. Be kind, '
                      'keep it friendly and family-safe, and respect other '
                      'people\'s privacy — what\'s shared here stays here.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _agreedToGuidelines,
                      onChanged: (v) =>
                          setState(() => _agreedToGuidelines = v ?? false),
                      title: const Text(
                        'I agree to the house rules',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
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
                      : const Text('Request to join'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
