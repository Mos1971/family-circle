import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_back_button.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_wordmark.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/auth_frame.dart';

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
  final _codeController = TextEditingController();
  final _circleNameController = TextEditingController();
  bool _creating = false;
  bool _agreedToGuidelines = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _familyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _circleNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _creating
                ? 'Please enter your licence code.'
                : 'Please enter the invite code from your circle admin.',
          ),
        ),
      );
      return;
    }
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
      inviteCode: _creating ? null : _codeController.text.trim(),
      licenseCode: _creating ? _codeController.text.trim() : null,
      circleName: _creating ? _circleNameController.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().error ??
                'Something went wrong, please try again.',
          ),
        ),
      );
    }
    // On success, the router redirect takes the new pending user to /pending.
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              isDesktopWidth(context) ? 40 : 0,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppWordmark(fontSize: 30),
                const SizedBox(height: 6),
                const Text(
                  'Create your account',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 22),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Join a circle')),
                    ButtonSegment(value: true, label: Text('Start a circle')),
                  ],
                  selected: {_creating},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.gold,
                    selectedForegroundColor: AppColors.onGold,
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onSelectionChanged: (v) => setState(() {
                    _creating = v.first;
                    _codeController.clear();
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  _creating
                      ? 'Set up a brand-new private space for your family. You\x27ll be its admin.'
                      : 'Ask your circle admin for the invite code. They\x27ll approve you once you\x27ve signed up.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 22),
                if (_creating) ...[
                  TextField(
                    controller: _circleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Name your circle',
                      hintText: 'e.g. The Okafor Family',
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: _creating ? 'Licence code' : 'Invite code',
                    hintText: _creating
                        ? 'From your purchase'
                        : 'e.g. K7M2QX9A',
                  ),
                ),
                const SizedBox(height: 14),
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
                        : Text(
                            _creating ? 'Create my circle' : 'Request to join',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
