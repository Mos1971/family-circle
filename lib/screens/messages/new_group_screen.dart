import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/member_avatar.dart';

/// Pick a name and some people to start a group chat.
class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _name = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _create() {
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    if (_name.text.trim().isEmpty) return _toast('Give the group a name.');
    if (_selected.isEmpty) return _toast('Pick at least one person.');
    final chat = context.read<MessageProvider>().createGroup(
      creatorId: me.id,
      name: _name.text.trim(),
      memberIds: _selected,
    );
    context.pushReplacement('/messages/group/${chat.id}');
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final people = context
        .watch<UserProvider>()
        .getAll()
        .where((u) => u.isApproved && u.id != me?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('New group'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Group name, e.g. Weekend plans',
                prefixIcon: Icon(Icons.groups_outlined, color: AppColors.gold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selected.isEmpty
                    ? 'ADD PEOPLE'
                    : 'ADD PEOPLE · ${_selected.length} SELECTED',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final u in people)
                  CheckboxListTile(
                    value: _selected.contains(u.id),
                    onChanged: (v) => setState(
                      () => v == true
                          ? _selected.add(u.id)
                          : _selected.remove(u.id),
                    ),
                    secondary: MemberAvatar(user: u, radius: 20),
                    title: Text(u.firstName),
                    subtitle: u.familyName.isEmpty ? null : Text(u.familyName),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _create,
                  child: const Text('Create group'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
