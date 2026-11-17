import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ContactAvatar(name: c.name, radius: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                if (c.phone.isNotEmpty)
                                  _line(Icons.phone_outlined, c.phone),
                                if (c.address.isNotEmpty)
                                  _line(Icons.home_outlined, c.address),
                                if (c.notes.isNotEmpty)
                                  _line(
                                    Icons.notes_outlined,
                                    c.notes,
                                    maxLines: 1,
                                  ),
                                const SizedBox(height: 8),
                                _ShareBadge(
                                  shared: c.shared,
                                  label: mine
                                      ? (c.shared
                                            ? 'Shared with family'
                                            : 'Private')
                                      : 'Shared by '
                                            '${owner?.firstName ?? 'a member'}',
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _line(IconData icon, String text, {int maxLines = 2}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Round avatar showing the contact's first letter.
class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.gold.withValues(alpha: 0.16),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w700,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// Small pill saying who can see a contact.
class _ShareBadge extends StatelessWidget {
  const _ShareBadge({required this.shared, required this.label});

  final bool shared;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: shared ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            shared ? Icons.group_outlined : Icons.lock_outline,
            size: 13,
            color: shared ? AppColors.gold : AppColors.muted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: shared ? AppColors.gold : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the contact card. Contacts that belong to someone else open
/// read-only because only the owner can change them.
Future<void> showContactSheet(BuildContext context, {Contact? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
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
  late bool _editing;
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
    _editing = c == null; // a new contact opens straight into the form
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

  bool get _isOwner {
    final me = context.read<AuthProvider>().currentUser;
    return _isNew || widget.existing!.ownerId == me?.id;
  }

  bool get _canDelete {
    final me = context.read<AuthProvider>().currentUser;
    return !_isNew &&
        (widget.existing!.ownerId == me?.id ||
            (widget.existing!.shared && (me?.isAdmin ?? false)));
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

  /// The share switch on the card saves straight away.
  void _setShared(bool value) {
    final me = context.read<AuthProvider>().currentUser;
    final c = widget.existing;
    if (me == null || c == null) return;
    setState(() => _shared = value);
    context.read<ContactProvider>().update(
      c.id,
      me.id,
      name: c.name,
      phone: c.phone,
      address: c.address,
      notes: c.notes,
      shared: value,
    );
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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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

  Future<void> _open(Uri uri, String failMessage) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) showAppMessage(failMessage);
    } catch (_) {
      showAppMessage(failMessage);
    }
  }

  void _call(String phone) => _open(
    Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+*#]'), '')),
    'Could not open the phone app',
  );

  void _directions(String address) => _open(
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.replaceAll('\n', ', '),
    }),
    'Could not open maps',
  );

  // ---- building blocks ----------------------------------------------------

  Widget _topButton({
    required Widget child,
    required VoidCallback? onPressed,
    bool filled = false,
  }) => Material(
    color: filled ? AppColors.gold : AppColors.surfaceHigh,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: filled ? AppColors.onGold : AppColors.gold,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              size: 20,
              color: filled ? AppColors.onGold : AppColors.gold,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );

  /// Rounded group of rows, like the grouped lists on a phone's contact card.
  Widget _group(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.border,
          ),
        );
      }
      children.add(rows[i]);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    IconData? trailingIcon,
    VoidCallback? onTrailing,
    String? trailingTooltip,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              SelectableText(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        if (trailingIcon != null)
          IconButton(
            tooltip: trailingTooltip,
            icon: Icon(trailingIcon),
            onPressed: onTrailing,
          ),
      ],
    ),
  );

  Widget _roundAction(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Expanded(
      child: Column(
        children: [
          Material(
            color: enabled
                ? AppColors.gold.withValues(alpha: 0.16)
                : AppColors.surfaceHigh,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  icon,
                  color: enabled ? AppColors.gold : AppColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: enabled ? AppColors.text : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(String phone, String address) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        _roundAction(
          Icons.phone,
          'Call',
          phone.isEmpty ? null : () => _call(phone),
        ),
        _roundAction(
          Icons.copy,
          'Copy phone',
          phone.isEmpty ? null : () => _copy('Number', phone),
        ),
        _roundAction(
          Icons.directions,
          'Directions',
          address.isEmpty ? null : () => _directions(address),
        ),
        _roundAction(
          Icons.location_on_outlined,
          'Copy address',
          address.isEmpty ? null : () => _copy('Address', address),
        ),
      ],
    ),
  );

  Widget _heading(String name, Widget below) => Column(
    children: [
      _ContactAvatar(name: name, radius: 44),
      const SizedBox(height: 12),
      Text(
        name.trim().isEmpty ? 'New contact' : name.trim(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      below,
      const SizedBox(height: 18),
    ],
  );

  Widget _viewBody() {
    final c = widget.existing!;
    final owner = context.read<UserProvider>().getById(c.ownerId);
    final owned = _isOwner;
    final hasDetails =
        c.phone.isNotEmpty || c.address.isNotEmpty || c.notes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          c.name,
          _ShareBadge(
            shared: _shared,
            label: owned
                ? (_shared ? 'Shared with family' : 'Private')
                : 'Shared by ${owner?.firstName ?? 'a member'}',
          ),
        ),
        _actionRow(c.phone, c.address),
        _group([
          if (c.phone.isNotEmpty)
            _detailRow(
              label: 'Phone',
              value: c.phone,
              trailingIcon: Icons.phone_outlined,
              trailingTooltip: 'Call',
              onTrailing: () => _call(c.phone),
            ),
          if (c.address.isNotEmpty)
            _detailRow(
              label: 'Address',
              value: c.address,
              trailingIcon: Icons.directions_outlined,
              trailingTooltip: 'Directions',
              onTrailing: () => _directions(c.address),
            ),
          if (c.notes.isNotEmpty) _detailRow(label: 'Notes', value: c.notes),
          if (!hasDetails)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No details added yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
        ]),
        if (owned)
          _group([
            SwitchListTile(
              title: const Text('Share with family'),
              subtitle: Text(
                _shared
                    ? 'Everyone in your circle can see this contact'
                    : 'Only you can see this contact',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              value: _shared,
              onChanged: _setShared,
            ),
          ]),
        if (_canDelete)
          _group([
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(
                'Delete contact',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: _delete,
            ),
          ]),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.muted),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      );

  Widget _editBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          _name.text,
          Text(
            _isNew ? 'Add the details below' : 'Editing contact',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        _group([
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _error = null),
            decoration: _fieldDecoration('Name', Icons.person_outline),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration('Phone number', Icons.phone_outlined),
          ),
          TextField(
            controller: _address,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
            minLines: 2,
            maxLines: 4,
            decoration: _fieldDecoration('Address', Icons.home_outlined),
          ),
          TextField(
            controller: _notes,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 6,
            decoration: _fieldDecoration('Notes', Icons.notes_outlined),
          ),
        ]),
        _group([
          SwitchListTile(
            title: const Text('Share with family'),
            subtitle: Text(
              _shared
                  ? 'Everyone in your circle can see this contact'
                  : 'Only you can see this contact',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            value: _shared,
            onChanged: (v) => setState(() => _shared = v),
          ),
        ]),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: AppColors.danger)),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            child: Text(_isNew ? 'Save contact' : 'Save changes'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing && _isOwner;

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            // Opaque tint (not see-through) so the page never shows through.
            colors: [
              Color.alphaBlend(
                AppColors.gold.withValues(alpha: 0.14),
                AppColors.bg,
              ),
              AppColors.bg,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  _topButton(
                    onPressed: () {
                      if (editing && !_isNew) {
                        // Back to the card without saving.
                        final c = widget.existing!;
                        setState(() {
                          _name.text = c.name;
                          _phone.text = c.phone;
                          _address.text = c.address;
                          _notes.text = c.notes;
                          _shared = c.shared;
                          _error = null;
                          _editing = false;
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(editing ? 'Cancel' : 'Close'),
                  ),
                  const Spacer(),
                  if (!editing && _isOwner)
                    _topButton(
                      onPressed: () => setState(() => _editing = true),
                      child: const Text('Edit'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: editing ? _editBody() : _viewBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
