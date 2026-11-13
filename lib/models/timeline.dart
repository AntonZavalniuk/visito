import 'country.dart';

/// A country together with when it was marked as visited.
class TimelineEntry {
  const TimelineEntry({required this.country, required this.date});

  final Country country;
  final DateTime date;
}

/// Summary of recent activity derived from visit timestamps.
class Timeline {
  const Timeline({
    required this.visitedCount,
    required this.monthStreak,
    required this.recent,
  });

  /// All marked entries: UN members plus disputed territories, observers and
  /// anything else the user marked (so it can exceed the official counter).
  final int visitedCount;

  /// Consecutive calendar months, ending this month or last month, in which
  /// at least one country was marked.
  final int monthStreak;

  /// Most recently marked countries, newest first.
  final List<TimelineEntry> recent;
}

int _monthIndex(DateTime d) => d.year * 12 + (d.month - 1);

/// Computes the [Timeline] from [entries] (ISO code -> when it was marked).
/// Entries whose ISO code is not in [countries] are ignored.
///
/// Everything here counts every marked entry (UN members, disputed
/// territories, observers, Antarctica); the official-only counter lives in
/// `worldStatsProvider`.
///
/// The streak is still alive during the month after the last activity, so it
/// only resets once a whole calendar month has passed without a new country.
Timeline computeTimeline(
  Map<String, DateTime> entries,
  List<Country> countries,
  DateTime now, {
  int recentLimit = 5,
}) {
  final byIso = {for (final c in countries) c.isoCode: c};
  final items = <TimelineEntry>[
    for (final e in entries.entries)
      if (byIso[e.key] != null)
        TimelineEntry(country: byIso[e.key]!, date: e.value.toLocal()),
  ]..sort((a, b) => b.date.compareTo(a.date));

  final months = {for (final i in items) _monthIndex(i.date)};
  final current = _monthIndex(now);
  var cursor = months.contains(current) ? current : current - 1;
  var streak = 0;
  while (months.contains(cursor)) {
    streak++;
    cursor--;
  }

  return Timeline(
    visitedCount: items.length,
    monthStreak: streak,
    recent: items.take(recentLimit).toList(),
  );
}

const _monthNames = [
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

/// Short human-friendly date: Today, Yesterday, "3 days ago", "2 weeks ago"
/// and "Mar 2026" for anything older than about two months.
String relativeDate(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;

  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  if (days < 14) return '1 week ago';
  if (days < 60) return '${days ~/ 7} weeks ago';
  return '${_monthNames[date.month - 1]} ${date.year}';
}
