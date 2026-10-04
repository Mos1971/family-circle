enum ExternalSource { google, microsoft }

extension ExternalSourceX on ExternalSource {
  String get label =>
      this == ExternalSource.google ? 'Google Calendar' : 'Outlook';
  String get shortLabel => this == ExternalSource.google ? 'Google' : 'Outlook';
}

/// A read-only event pulled from the person's own Google or Outlook
/// calendar. Never stored on our servers.
class ExternalEvent {
  const ExternalEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.source,
    this.minutesFromMidnight,
    this.location = '',
  });

  final String id;
  final String title;

  /// Calendar day the event starts on (local time).
  final DateTime date;

  /// Start time as minutes after midnight; null means all-day.
  final int? minutesFromMidnight;
  final ExternalSource source;
  final String location;

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
