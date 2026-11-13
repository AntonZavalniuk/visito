import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/country_repository.dart';
import 'package:visito/data/database.dart';
import 'package:visito/features/stats/stats_screen.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/database_provider.dart';

class _FakeLoader extends CountryGeoJsonLoader {
  const _FakeLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async {
    return [
      Country(
        isoCode: 'CA',
        name: 'Canada',
        continent: Continent.northAmerica,
        unMember: true,
        polygons: [
          [
            const LatLng(50, -100),
            const LatLng(60, -100),
            const LatLng(50, -90),
          ],
        ],
      ),
      Country(
        isoCode: 'JP',
        name: 'Japan',
        continent: Continent.asia,
        unMember: true,
        polygons: [
          [const LatLng(35, 139), const LatLng(36, 139), const LatLng(35, 140)],
        ],
      ),
    ];
  }
}

void main() {
  testWidgets(
    'StatsScreen renders progress, rank, metrics, and reacts to visited updates',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
          ],
          child: const MaterialApp(home: StatsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial elements
      expect(find.text('Travel Stats'), findsOneWidget);
      expect(find.text('World Explored'), findsOneWidget);
      expect(find.text('0 of 2 countries visited'), findsOneWidget);
      expect(find.text('Aspiring Explorer 🌱'), findsOneWidget);
      // The hero counter says what it counts.
      expect(find.byKey(const ValueKey('hero_scope_hint')), findsOneWidget);
      expect(find.text('UN member states only'), findsOneWidget);
      expect(find.text('Ready to explore?'), findsOneWidget);
      // Rank progress: 0 of 1 needed for Curious Wanderer.
      expect(
        find.text('1 more UN country to Curious Wanderer 🎒'),
        findsOneWidget,
      );

      // Mark 1 country as visited
      final repo = CountryRepository(db);
      await repo.toggleVisited('CA');

      // Settle UI animations
      await tester.pumpAndSettle();

      // Verify reactive update
      expect(find.text('1 of 2 countries visited'), findsOneWidget);
      expect(find.text('Curious Wanderer 🎒'), findsOneWidget);
      expect(
        find.text('5 more UN countries to Globetrotter ✈️'),
        findsOneWidget,
      );
      expect(find.text('Explored Lands'), findsOneWidget);
      // The metric cards (Visited / Remaining / Total) are gone.
      expect(find.text('Remaining'), findsNothing);
      expect(find.text('In database'), findsNothing);

      // The statistic cards form a swipeable stack; the section sits below
      // the fold in the test viewport.
      final deck = find.byKey(const ValueKey('deck_gesture'));
      expect(deck, findsOneWidget);
      await tester.ensureVisible(deck);
      await tester.pumpAndSettle();

      Future<void> swipeAway() async {
        await tester.drag(deck, const Offset(-500, 0));
        await tester.pumpAndSettle();
      }

      // Top card: In Total.
      expect(find.byKey(const ValueKey('deck_total')), findsOneWidget);
      expect(find.text('In Total'), findsOneWidget);
      expect(find.text('Out of 2 UN Countries'), findsOneWidget);
      // 1 of 2 = 50 % (rich text: number + '%' suffix).
      expect(find.text('50%', findRichText: true), findsWidgets);

      // Swipe: Continents (only North America has a visited country).
      await swipeAway();
      expect(find.text('Continents'), findsOneWidget);
      expect(find.text('Including Antarctica'), findsOneWidget);

      // Asia (0 / 1), then North America (1 / 1).
      await swipeAway();
      expect(find.byKey(const ValueKey('continent_asia')), findsOneWidget);
      expect(find.text('Countries recognized by the UN'), findsWidgets);

      await swipeAway();
      expect(
        find.byKey(const ValueKey('continent_northAmerica')),
        findsOneWidget,
      );
      expect(find.text('North America'), findsOneWidget);

      // A dismissed card goes to the back: the deck cycles to In Total.
      await swipeAway();
      expect(find.text('In Total'), findsOneWidget);

      // Recent activity: the country just marked shows up as "Today".
      final recent = find.byKey(const ValueKey('timeline_CA'));
      await tester.ensureVisible(recent);
      await tester.pumpAndSettle();
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(
        find.descendant(of: recent, matching: find.text('Canada')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: recent, matching: find.text('Today')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('timeline_visited')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('timeline_visited')),
          matching: find.text('Visited Countries'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('timeline_streak')),
          matching: find.text('Month streak'),
        ),
        findsOneWidget,
      );

      // Achievements: First Stamp is unlocked after marking one country.
      final firstStamp = find.byKey(const ValueKey('achievement_first_stamp'));
      await tester.ensureVisible(firstStamp);
      await tester.pumpAndSettle();
      expect(find.text('Achievements'), findsOneWidget);
      expect(
        find.descendant(of: firstStamp, matching: find.text('Unlocked')),
        findsOneWidget,
      );
      // Every badge explains how to earn it.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('achievement_double_digits')),
          matching: find.text('Visit 10 UN countries'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('achievement_both_hemispheres')),
        findsOneWidget,
      );
      final gettingStarted = find.byKey(
        const ValueKey('achievement_getting_started'),
      );
      expect(
        find.descendant(of: gettingStarted, matching: find.text('1 / 5')),
        findsOneWidget,
      );

      // Scroll back to the deck before interacting with it again.
      await tester.ensureVisible(deck);
      await tester.pumpAndSettle();

      // A short drag springs back instead of dismissing the card.
      await tester.drag(deck, const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(find.text('In Total'), findsOneWidget);

      await db.close();
    },
  );
}
