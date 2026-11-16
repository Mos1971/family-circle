import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_messenger.dart';
import '../../models/contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

/// "Contacts" tab: names, phone numbers, addresses and notes. Contacts are
/// private to their owner unless the owner shares them with the family.
class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    if (me == null) return const SizedBox.shrink();
    final contacts = context.watch<ContactProvider>().getFor(me.id);
    final users = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showContactSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New contact'),
      ),
      body: contacts.isEmpty
          ? const EmptyState(
              emoji: '📇',
              title: 'No contacts yet',
              subtitle:
                  'Keep names, phone numbers, addresses and notes here. '
                  'Contacts are private to you unless you share them with '
                  'the family.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: contacts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = contacts[i];
                final mine = c.ownerId == me.id;
                final owner = users.getById(c.ownerId);
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => showContactSheet(context, existing: c),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Icon(
                                c.shared
                                    ? Icons.group_outlined
                                    : Icons.lock_outline,
                                size: 18,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                          if (c.phone.isNotEmpty)
                            _line(Icons.phone_outlined, c.phone),
                          if (c.address.isNotEmpty)
                            _line(Icons.home_outlined, c.address),
                          if (c.notes.isNotEmpty)
                            _line(Icons.notes_outlined, c.notes, maxLines: 2),
                          const SizedBox(height: 8),
                          Text(
                            mine
                                ? (c.shared ? 'Shared with family' : 'Private')
                                : 'Shared by ${owner?.firstName ?? 'a member'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _line(IconData icon, String text, {int maxLines = 3}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

/// Opens the add / edit form. Contacts that belong to someone else open
/// read-only (with copy buttons) because only the owner can change them.
Future<void> showContactSheet(BuildContext context, {Contact? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ContactSheet(existing: existing),
  );
}

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({this.existing});

  final Contact? existing;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late bool _shared;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _shared = c?.shared ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isNew => widget.existing == null;

  bool get _canEdit {
    final me = context.read<AuthProvider>().currentUser;
    return _isNew || widget.existing!.ownerId == me?.id;
  }

  void _save() {
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    final contacts = context.read<ContactProvider>();
    if (_isNew) {
      contacts.add(
        ownerId: me.id,
        name: name,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        shared: _shared,
      );
    } else {
      contacts.update(
        widget.existing!.id,
        me.id,
        name: name,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        shared: _shared,
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final me = context.read<AuthProvider>().currentUser;
    if (me == null || widget.existing == null) return;
    final contacts = context.read<ContactProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove ${widget.existing!.name} from your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    contacts.delete(widget.existing!.id, me.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showAppMessage('$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final editable = _canEdit;
    final me = context.read<AuthProvider>().currentUser;
    final canDelete =
        !_isNew &&
        (widget.existing!.ownerId == me?.id ||
            (widget.existing!.shared && (me?.isAdmin ?? false)));

    Widget field(
      TextEditingController c,
      String label, {
      TextInputType? type,
      int lines = 1,
      TextCapitalization caps = TextCapitalization.none,
      String? copyLabel,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        readOnly: !editable,
        keyboardType: type,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 3,
        textCapitalization: caps,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: !editable && c.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copy(copyLabel ?? label, c.text),
                )
              : null,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isNew
                  ? 'New contact'
                  : (editable ? 'Edit contact' : 'Contact'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            field(_name, 'Name', caps: TextCapitalization.words),
            field(_phone, 'Phone number', type: TextInputType.phone),
            field(
              _address,
              'Address',
              type: TextInputType.streetAddress,
              lines: 2,
              caps: TextCapitalization.words,
            ),
            field(
              _notes,
              'Notes',
              type: TextInputType.multiline,
              lines: 3,
              caps: TextCapitalization.sentences,
            ),
            if (editable)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share with family'),
                subtitle: Text(
                  _shared
                      ? 'Everyone in your circle can see this contact'
                      : 'Only you can see this contact',
                ),
                value: _shared,
                onChanged: (v) => setState(() => _shared = v),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (canDelete)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(editable ? 'Cancel' : 'Close'),
                ),
                if (editable) ...[
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
