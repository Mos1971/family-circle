import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/calendar_event.dart';
import '../../models/external_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/external_calendar_provider.dart';
import '../../providers/plan_providers.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/app_layout.dart';
import 'external_sync_widgets.dart';

enum _Mode { family, mine }

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  _Mode _mode = _Mode.family;
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    if (me == null) return const SizedBox.shrink();
    final cal = context.watch<CalendarProvider>();

    final shared = cal.getShared();
    final mine = cal.getPrivate(me.id);
    // "My calendar" shows private events and, optionally, the family's too.
    final visible = _mode == _Mode.family
        ? shared
        : [...mine, if (cal.overlayFamily) ...shared];
    final dayEvents = cal.onDay(visible, _selected);

    // Events synced from the person's own Google / Outlook calendars. They
    // only ever appear on "My calendar" and are read-only.
    final ext = context.watch<ExternalCalendarProvider>();
    final externalAll = _mode == _Mode.mine ? ext.all : const <ExternalEvent>[];
    final externalDay = _mode == _Mode.mine
        ? ext.onDay(_selected)
        : const <ExternalEvent>[];

    final controls = <Widget>[
      SegmentedButton<_Mode>(
        segments: const [
          ButtonSegment(
            value: _Mode.family,
            label: Text('Family calendar'),
            icon: Icon(Icons.groups_outlined),
          ),
          ButtonSegment(
            value: _Mode.mine,
            label: Text('My calendar'),
            icon: Icon(Icons.lock_outline),
          ),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.gold,
          selectedForegroundColor: AppColors.onGold,
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
        ),
        onSelectionChanged: (s) => setState(() => _mode = s.first),
      ),
      if (_mode == _Mode.mine) ...[
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Show family events here'),
          subtitle: const Text(
            'Only you can see your calendar. Family events are shown '
            'in gold.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          value: cal.overlayFamily,
          onChanged: cal.setOverlayFamily,
        ),
        if (ext.anyEnabled) ...[const SizedBox(height: 8), const SyncPanel()],
      ],
      const SizedBox(height: 8),
    ];

    final calendar = <Widget>[
      _MonthHeader(
        month: _month,
        onPrev: () => _shiftMonth(-1),
        onNext: () => _shiftMonth(1),
        onToday: () {
          final now = DateTime.now();
          setState(() {
            _month = DateTime(now.year, now.month);
            _selected = DateTime(now.year, now.month, now.day);
          });
        },
      ),
      _MonthGrid(
        month: _month,
        selected: _selected,
        sharedEvents: _mode == _Mode.family
            ? shared
            : (cal.overlayFamily ? shared : const []),
        privateEvents: _mode == _Mode.mine ? mine : const [],
        externalEvents: externalAll,
        onSelect: (d) => setState(() => _selected = d),
      ),
    ];

    // Own events and synced ones in one list, ordered by time of day.
    final agendaItems = <({int minutes, Widget tile})>[
      for (final e in dayEvents)
        (minutes: e.minutesFromMidnight ?? -1, tile: _EventTile(event: e)),
      for (final e in externalDay)
        (
          minutes: e.minutesFromMidnight ?? -1,
          tile: ExternalEventTile(event: e),
        ),
    ]..sort((a, b) => a.minutes.compareTo(b.minutes));

    final agenda = <Widget>[
      Text(
        DateFormat('EEEE d MMMM').format(_selected),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      if (agendaItems.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Nothing planned.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else
        ...agendaItems.map((i) => i.tile),
    ];

    final wide = isDesktopWidth(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEventEditor(
          context,
          date: _selected,
          shared: _mode == _Mode.family,
        ),
        icon: const Icon(Icons.add),
        label: Text(_mode == _Mode.family ? 'Add to family' : 'Add to mine'),
      ),
      body: wide
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...controls,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: Column(children: calendar)),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const SizedBox(height: 12), ...agenda],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                ...controls,
                ...calendar,
                const SizedBox(height: 18),
                ...agenda,
              ],
            ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: GestureDetector(
            onTap: onToday,
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.sharedEvents,
    required this.privateEvents,
    required this.externalEvents,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final List<CalendarEvent> sharedEvents;
  final List<CalendarEvent> privateEvents;
  final List<ExternalEvent> externalEvents;
  final ValueChanged<DateTime> onSelect;

  bool _has(List<CalendarEvent> list, DateTime d) => list.any(
    (e) =>
        e.date.year == d.year && e.date.month == d.month && e.date.day == d.day,
  );

  bool _hasExternal(DateTime d) => externalEvents.any(
    (e) =>
        e.date.year == d.year && e.date.month == d.month && e.date.day == d.day,
  );

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    // Monday-first grid.
    final lead = (first.weekday + 6) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: _cell(r * 7 + c - lead + 1, daysInMonth, today),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(int day, int daysInMonth, DateTime today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 46);
    final date = DateTime(month.year, month.month, day);
    final isSel = isSameDay(date, selected);
    final isToday = isSameDay(date, today);
    final hasShared = _has(sharedEvents, date);
    final hasPrivate = _has(privateEvents, date);
    final hasExternal = _hasExternal(date);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelect(date),
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSel ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSel ? Border.all(color: AppColors.gold) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSel ? AppColors.onGold : AppColors.text,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasShared) _dot(isSel ? AppColors.onGold : AppColors.gold),
                if (hasShared && hasPrivate) const SizedBox(width: 3),
                if (hasPrivate) _dot(isSel ? AppColors.onGold : AppColors.text),
                if ((hasShared || hasPrivate) && hasExternal)
                  const SizedBox(width: 3),
                if (hasExternal)
                  _dot(isSel ? AppColors.onGold : kExternalColor),
                if (!hasShared && !hasPrivate && !hasExternal)
                  const SizedBox(height: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<UserProvider>().getById(event.ownerId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showEventDetails(context, event.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.shared ? AppColors.gold : AppColors.text,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.timeLabel} · ${event.shared ? 'Family' : 'Private'}'
                        '${event.shared && owner != null ? ' · ${owner.firstName}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for adding an event. [shared] picks the starting audience.
Future<void> showEventEditor(
  BuildContext context, {
  required DateTime date,
  required bool shared,
}) {
  final me = context.read<AuthProvider>().currentUser;
  if (me == null) return Future.value();
  final cal = context.read<CalendarProvider>();
  final title = TextEditingController();
  final notes = TextEditingController();
  var pickedDate = date;
  TimeOfDay? pickedTime;
  var isShared = shared;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New event', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What\'s happening?',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(DateFormat('EEE d MMM').format(pickedDate)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: pickedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setSheet(() => pickedDate = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          pickedTime == null
                              ? 'All day'
                              : pickedTime!.format(ctx),
                        ),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime:
                                pickedTime ??
                                const TimeOfDay(hour: 12, minute: 0),
                          );
                          if (t != null) setSheet(() => pickedTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                if (pickedTime != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setSheet(() => pickedTime = null),
                      child: const Text('Make all day'),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on the family calendar'),
                  subtitle: Text(
                    isShared
                        ? 'Everyone in Family Circle can see this.'
                        : 'Only you can see this.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  value: isShared,
                  onChanged: (v) => setSheet(() => isShared = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final t = title.text.trim();
                      if (t.isEmpty) return;
                      cal.add(
                        ownerId: me.id,
                        title: t,
                        notes: notes.text.trim(),
                        date: pickedDate,
                        minutesFromMidnight: pickedTime == null
                            ? null
                            : pickedTime!.hour * 60 + pickedTime!.minute,
                        shared: isShared,
                      );
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Save event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Event details with the sync actions between the two calendars.
Future<void> showEventDetails(BuildContext context, String eventId) {
  final me = context.read<AuthProvider>().currentUser;
  if (me == null) return Future.value();

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Consumer<CalendarProvider>(
      builder: (ctx, cal, _) {
        final e = cal.getById(eventId);
        if (e == null) {
          return const SizedBox(height: 120);
        }
        final mineOwned = e.ownerId == me.id;
        final alreadyCopied = cal.isCopiedToPrivate(e.id, me.id);
        final owner = ctx.read<UserProvider>().getById(e.ownerId);

        void close() => Navigator.of(sheetContext).pop();
        void toast(String msg) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '${DateFormat('EEEE d MMMM').format(e.date)} · ${e.timeLabel}',
                style: const TextStyle(color: AppColors.gold),
              ),
              const SizedBox(height: 4),
              Text(
                e.shared
                    ? 'Family calendar · added by ${owner?.firstName ?? 'a member'}'
                    : 'Private — only you can see this',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (e.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(e.notes),
              ],
              const SizedBox(height: 18),
              if (e.shared && !mineOwned)
                OutlinedButton.icon(
                  icon: Icon(
                    alreadyCopied ? Icons.check : Icons.event_available,
                  ),
                  label: Text(
                    alreadyCopied ? 'On my calendar' : 'Add to my calendar',
                  ),
                  onPressed: alreadyCopied
                      ? null
                      : () {
                          cal.copyToPrivate(e.id, me.id);
                          close();
                          toast('Added to your private calendar.');
                        },
                ),
              if (!e.shared && mineOwned)
                OutlinedButton.icon(
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Share to family calendar'),
                  onPressed: () {
                    cal.shareToFamily(e.id, me.id);
                    close();
                    toast('Shared with the family.');
                  },
                ),
              if (e.shared && mineOwned)
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Make private'),
                  onPressed: () {
                    cal.makePrivate(e.id, me.id);
                    close();
                    toast('Moved to your private calendar.');
                  },
                ),
              if (mineOwned || (e.shared && me.isAdmin))
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete event'),
                  onPressed: () {
                    cal.delete(e.id, me.id);
                    close();
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}
