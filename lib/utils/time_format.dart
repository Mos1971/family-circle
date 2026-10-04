String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Today" / "Tomorrow" / "5 Sep" — the day a session falls on, distinct
/// from [timeAgo] which describes when the alert was reported.
String sessionDateLabel(DateTime date) {
  final now = DateTime.now();
  if (isSameDay(date, now)) return 'Today';
  if (isSameDay(date, now.add(const Duration(days: 1)))) return 'Tomorrow';
  return '${date.day} ${_kMonths[date.month - 1]}';
}
