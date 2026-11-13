import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/core/widgets/achievement_toast_host.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/country_repository.dart';
import 'package:visito/data/database.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/database_provider.dart';

class _Loader extends CountryGeoJsonLoader {
  const _Loader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    for (final (iso, name) in [
      ('CA', 'Canada'),
      ('JP', 'Japan'),
      ('FR', 'France'),
    ])
      Country(
        isoCode: iso,
        name: name,
        continent: Continent.europe,
        unMember: true,
        polygons: [
          [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
        ],
      ),
  ];
}

Future<void> _pumpHost(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        countryGeoJsonLoaderProvider.overrideWithValue(const _Loader()),
      ],
      child: const MaterialApp(
        home: AchievementToastHost(child: Scaffold(body: SizedBox.expand())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no toast for state that already existed at load', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    // Visited before the app starts (real async: the DB needs real timers).
    await tester.runAsync(() => CountryRepository(db).toggleVisited('CA'));

    await _pumpHost(tester, db);

    expect(find.text('Achievement unlocked'), findsNothing);
    expect(find.text('New rank'), findsNothing);

    await db.close();
  });

  testWidgets('marking the first country unlocks a badge and a rank-up', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _pumpHost(tester, db);

    await CountryRepository(db).toggleVisited('CA');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // First queued toast: an achievement (First Stamp / Half the World...).
    expect(find.text('Achievement unlocked'), findsOneWidget);

    // Drain the queue: every toast stays 3 s; eventually the rank-up shows.
    var sawRankUp = false;
    for (var i = 0; i < 6 && !sawRankUp; i++) {
      sawRankUp = find.text('New rank').evaluate().isNotEmpty;
      if (!sawRankUp) await tester.pump(const Duration(seconds: 3));
    }
    expect(sawRankUp, isTrue);
    expect(find.text('Curious Wanderer 🎒'), findsOneWidget);

    // Let everything finish so no timers are left pending.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    await db.close();
  });

  testWidgets('a badge is announced only once per session', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await _pumpHost(tester, db);
    final repo = CountryRepository(db);

    await repo.toggleVisited('CA');
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));

    await repo.toggleVisited('CA'); // un-mark: badges re-lock silently
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await repo.toggleVisited('CA'); // mark again: same badge, no repeat toast
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Achievement unlocked'), findsNothing);

    await tester.pump(const Duration(seconds: 10));
    await db.close();
  });
}
