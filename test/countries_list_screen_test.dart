import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/features/countries/countries_list_screen.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/database_provider.dart';

class _FakeLoader extends CountryGeoJsonLoader {
  const _FakeLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async {
    return [
      Country(
        isoCode: 'BR',
        name: 'Brazil',
        polygons: [
          [
            const LatLng(-10, -50),
            const LatLng(-10, -40),
            const LatLng(-20, -40),
          ],
        ],
      ),
      Country(
        isoCode: 'CA',
        name: 'Canada',
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
        polygons: [
          [const LatLng(35, 139), const LatLng(36, 139), const LatLng(35, 140)],
        ],
      ),
    ];
  }
}

void main() {
  testWidgets(
    'CountriesListScreen displays list, searches, and toggles visited',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
          ],
          child: const MaterialApp(home: CountriesListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 3 countries are shown initially
      expect(find.text('Brazil'), findsOneWidget);
      expect(find.text('Canada'), findsOneWidget);
      expect(find.text('Japan'), findsOneWidget);

      // Test search filtering by country name
      await tester.enterText(find.byType(TextField), 'Jap');
      await tester.pumpAndSettle();

      // 'Jap' will be in the TextField, 'Japan' will be in the list
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('Brazil'), findsNothing);
      expect(find.text('Canada'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Brazil'), findsOneWidget);

      // Toggle visited on Brazil by tapping the country tile text
      await tester.tap(find.text('Brazil'));
      await tester.pumpAndSettle();

      // Verify Brazil shows visited subtitle
      expect(find.text('Visited'), findsWidgets);

      // Filter by Visited chip using explicit key
      await tester.tap(find.byKey(const ValueKey('filter_visited')));
      await tester.pumpAndSettle();

      expect(find.text('Brazil'), findsOneWidget);
      expect(find.text('Canada'), findsNothing);
      expect(find.text('Japan'), findsNothing);

      // Filter by Unvisited chip
      await tester.tap(find.byKey(const ValueKey('filter_unvisited')));
      await tester.pumpAndSettle();

      expect(find.text('Brazil'), findsNothing);
      expect(find.text('Canada'), findsOneWidget);
      expect(find.text('Japan'), findsOneWidget);

      await db.close();
    },
  );

  testWidgets('continent groups can be collapsed and expanded', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
        ],
        child: const MaterialApp(home: CountriesListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Fake countries have no continent, so they land in the "Other" group.
    expect(find.text('Brazil'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group_Other')));
    await tester.pumpAndSettle();
    expect(find.text('Brazil'), findsNothing);
    expect(find.text('OTHER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group_Other')));
    await tester.pumpAndSettle();
    expect(find.text('Brazil'), findsOneWidget);

    await db.close();
  });

  testWidgets('group header shows visited / continent total under filters', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.visitedCountries)
        .insert(VisitedCountriesCompanion.insert(isoCode: 'JP'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
        ],
        child: const MaterialApp(home: CountriesListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('filter_visited')));
    await tester.pumpAndSettle();
    expect(find.text('Brazil'), findsNothing);
    // Header still reads 1 / 3, not 1 / 1.
    expect(find.text('1 / 3'), findsWidgets);
    expect(find.text('1 / 1'), findsNothing);

    // Unvisited filter counts unvisited countries: 2 of 3.
    await tester.tap(find.byKey(const ValueKey('filter_unvisited')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsWidgets);

    await db.close();
  });
}
