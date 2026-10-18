/// An entry on a calendar. A [shared] event is on the family calendar and
/// visible to every approved member; a private event is only visible to its
/// owner (until they choose to share it).
class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.date,
    this.minutesFromMidnight,
    this.endDate,
    this.endMinutes,
    this.notes = '',
    this.shared = false,
    this.copiedFromId,
  });

  final String id;
  final String ownerId;
  String title;
  String notes;

  /// Calendar day (time part ignored).
  DateTime date;

  /// Start time as minutes after midnight; null means all-day.
  int? minutesFromMidnight;

  bool shared;

  /// Set when this private event was copied from a family event, so the UI
  /// can show it is already on the user's calendar.
  final String? copiedFromId;

  /// Last calendar day of a multi-day event; null means a single day.
  DateTime? endDate;

  /// End time as minutes after midnight (on the last day); null if not set.
  int? endMinutes;

  bool get allDay => minutesFromMidnight == null;

  /// The final day the event covers (the start day when there is no end date).
  DateTime get lastDay {
    final e = endDate;
    if (e == null) return date;
    final end = DateTime(e.year, e.month, e.day);
    return end.isBefore(date) ? date : end;
  }

  bool get multiDay => lastDay != date;

  /// Whether the event is happening on [day] (any time of day).
  bool coversDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(date) && !d.isAfter(lastDay);
  }

  static String _fmt(int m) {
    final h = m ~/ 60;
    final mm = (m % 60).toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm ${h < 12 ? 'AM' : 'PM'}';
  }

  String get timeLabel {
    final s = minutesFromMidnight;
    final e = endMinutes;
    if (s == null && e == null) return 'All day';
    if (s == null) return 'Until ${_fmt(e!)}';
    if (e == null) return _fmt(s);
    return '${_fmt(s)} – ${_fmt(e)}';
  }
}
