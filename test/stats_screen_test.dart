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
        polygons: [
          [const LatLng(50, -100), const LatLng(60, -100), const LatLng(50, -90)]
        ],
      ),
      Country(
        isoCode: 'JP',
        name: 'Japan',
        polygons: [
          [const LatLng(35, 139), const LatLng(36, 139), const LatLng(35, 140)]
        ],
      ),
    ];
  }
}

void main() {
  testWidgets('StatsScreen renders progress, rank, metrics, and reacts to visited updates',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
        ],
        child: const MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial elements
    expect(find.text('Travel Stats'), findsOneWidget);
    expect(find.text('World Explored'), findsOneWidget);
    expect(find.text('0 of 2 countries visited'), findsOneWidget);
    expect(find.text('Aspiring Explorer 🌱'), findsOneWidget);
    expect(find.text('Ready to explore?'), findsOneWidget);

    // Mark 1 country as visited
    final repo = CountryRepository(db);
    await repo.toggleVisited('CA');

    // Settle UI animations
    await tester.pumpAndSettle();

    // Verify reactive update
    expect(find.text('1 of 2 countries visited'), findsOneWidget);
    expect(find.text('Curious Wanderer 🎒'), findsOneWidget);
    expect(find.text('Explored Lands'), findsOneWidget);
    expect(find.text('Canada'), findsOneWidget);

    await db.close();
  });
}
