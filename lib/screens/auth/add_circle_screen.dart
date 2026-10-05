import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/auth_frame.dart';

/// For someone who is already signed in: join another circle with an invite
/// code, or start a new one with a licence code. The same account can belong
/// to as many circles as you like.
class AddCircleScreen extends StatefulWidget {
  const AddCircleScreen({super.key});

  @override
  State<AddCircleScreen> createState() => _AddCircleScreenState();
}

class _AddCircleScreenState extends State<AddCircleScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _familyController;
  final _codeController = TextEditingController();
  final _circleNameController = TextEditingController();
  bool _creating = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: me?.firstName ?? '');
    _familyController = TextEditingController(text: me?.familyName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyController.dispose();
    _codeController.dispose();
    _circleNameController.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _submit() async {
    if (_codeController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      _toast(
        _creating
            ? 'Please enter your name and licence code.'
            : 'Please enter your name and the invite code.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<UserProvider>().addCircle(
        firstName: _nameController.text.trim(),
        familyName: _familyController.text.trim(),
        inviteCode: _creating ? null : _codeController.text.trim(),
        licenseCode: _creating ? _codeController.text.trim() : null,
        circleName: _creating ? _circleNameController.text.trim() : null,
      );
      if (!mounted) return;
      _toast(
        _creating
            ? 'Your new circle is ready.'
            : 'Request sent. The circle admin will approve you.',
      );
      // The app switches to the new circle by itself; head back home.
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Add a circle'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              isDesktopWidth(context) ? 24 : 8,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use the same account for more than one family or group. '
                  'You can switch between circles any time.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 20),
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
                    side: BorderSide(color: AppColors.border),
                  ),
                  onSelectionChanged: (v) => setState(() {
                    _creating = v.first;
                    _codeController.clear();
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your first name in this circle',
                  ),
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
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? SizedBox(
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
