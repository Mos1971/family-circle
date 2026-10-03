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

  bool get allDay => minutesFromMidnight == null;

  String get timeLabel {
    final m = minutesFromMidnight;
    if (m == null) return 'All day';
    final h = m ~/ 60;
    final mm = (m % 60).toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm ${h < 12 ? 'AM' : 'PM'}';
  }
}
