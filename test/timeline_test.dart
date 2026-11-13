import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/models/country.dart';
import 'package:visito/models/timeline.dart';

Country _c(String iso, String name, {bool un = true, bool disputed = false}) =>
    Country(
      isoCode: iso,
      name: name,
      unMember: un,
      disputed: disputed,
      polygons: [
        [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
      ],
    );

void main() {
  final countries = [
    _c('FR', 'France'),
    _c('DE', 'Germany'),
    _c('JP', 'Japan'),
    _c('CA', 'Canada'),
    _c('AU', 'Australia'),
    _c('BR', 'Brazil'),
    _c('IT', 'Italy'),
    _c('EH', 'Western Sahara', un: false, disputed: true),
  ];
  final now = DateTime(2026, 11, 13, 12);

  group('computeTimeline', () {
    test('empty entries produce an empty timeline', () {
      final t = computeTimeline({}, countries, now);
      expect(t.visitedCount, 0);
      expect(t.monthStreak, 0);
      expect(t.recent, isEmpty);
    });

    test('recent is newest first, limited and ignores unknown codes', () {
      final entries = {
        'FR': DateTime(2026, 1, 5),
        'DE': DateTime(2026, 2, 5),
        'JP': DateTime(2026, 3, 5),
        'CA': DateTime(2026, 4, 5),
        'AU': DateTime(2026, 5, 5),
        'BR': DateTime(2026, 6, 5),
        'XX': DateTime(2026, 7, 5), // not in the country list
      };
      final t = computeTimeline(entries, countries, now);
      expect(t.recent.map((e) => e.country.isoCode), [
        'BR',
        'AU',
        'CA',
        'JP',
        'DE',
      ]);
    });

    test('visited count includes every marked entry, official or not', () {
      final entries = {
        'FR': DateTime(2025, 12, 31),
        'JP': DateTime(2026, 11, 2),
        'EH': DateTime(2026, 11, 3), // disputed: still counted
      };
      final t = computeTimeline(entries, countries, now);
      expect(t.visitedCount, 3);
      expect(t.recent.map((e) => e.country.isoCode), ['EH', 'JP', 'FR']);
    });

    test('unknown ISO codes are not counted', () {
      final entries = {
        'FR': DateTime(2026, 11, 1),
        'XX': DateTime(2026, 11, 2),
      };
      expect(computeTimeline(entries, countries, now).visitedCount, 1);
    });

    test('non-official entries still extend the streak', () {
      final entries = {'EH': DateTime(2026, 11, 3)};
      final t = computeTimeline(entries, countries, now);
      expect(t.visitedCount, 1);
      expect(t.monthStreak, 1);
    });

    test('streak counts consecutive months ending this month', () {
      final entries = {
        'FR': DateTime(2026, 9, 10),
        'DE': DateTime(2026, 10, 10),
        'JP': DateTime(2026, 11, 1),
        'CA': DateTime(2026, 7, 1), // gap in August -> not part of the streak
      };
      expect(computeTimeline(entries, countries, now).monthStreak, 3);
    });

    test('streak stays alive in the month after the last activity', () {
      final entries = {
        'FR': DateTime(2026, 9, 10),
        'DE': DateTime(2026, 10, 10),
      };
      // "now" is November: last activity was October -> streak still 2.
      expect(computeTimeline(entries, countries, now).monthStreak, 2);
    });

    test('streak resets after a whole month without activity', () {
      final entries = {
        'FR': DateTime(2026, 8, 10),
        'DE': DateTime(2026, 9, 10),
      };
      expect(computeTimeline(entries, countries, now).monthStreak, 0);
    });

    test('streak crosses the year boundary', () {
      final january = DateTime(2026, 1, 20);
      final entries = {
        'FR': DateTime(2025, 11, 5),
        'DE': DateTime(2025, 12, 5),
        'JP': DateTime(2026, 1, 5),
      };
      expect(computeTimeline(entries, countries, january).monthStreak, 3);
    });
  });

  group('relativeDate', () {
    test('uses friendly labels for recent dates', () {
      expect(relativeDate(DateTime(2026, 11, 13, 1), now), 'Today');
      expect(relativeDate(DateTime(2026, 11, 12, 23), now), 'Yesterday');
      expect(relativeDate(DateTime(2026, 11, 10), now), '3 days ago');
      expect(relativeDate(DateTime(2026, 11, 5), now), '1 week ago');
      expect(relativeDate(DateTime(2026, 10, 20), now), '3 weeks ago');
    });

    test('falls back to month and year for older dates', () {
      expect(relativeDate(DateTime(2026, 3, 8), now), 'Mar 2026');
      expect(relativeDate(DateTime(2025, 12, 1), now), 'Dec 2025');
    });

    test('future dates are shown as Today', () {
      expect(relativeDate(DateTime(2026, 11, 20), now), 'Today');
    });
  });
}
