import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/data/territories.dart';
import 'package:visito/features/countries/countries_list_screen.dart';
import 'package:visito/models/country.dart';
import 'package:visito/models/list_entry.dart';
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

/// List-only top-level entries: the extra countries plus the alignable
/// disputed territories (e.g. Somaliland), independent by default.
final int _extraCount =
    extraCountrySpecs.length +
    territorySpecs
        .where(
          (t) =>
              t.alignable &&
              t.defaultAlignment == DisputedAlignment.independent,
        )
        .length;

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  _somaliaTests();
  testWidgets(
    'CountriesListScreen displays list, searches, and toggles visited',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      _tallView(tester);
      _tallView(tester);

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

      // Verify Brazil shows a check mark
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Summary counts countries (not territories), not UN-only.
      expect(find.text('Visited: 1 of ${3 + _extraCount}'), findsOneWidget);

      await db.close();
    },
  );

  testWidgets('continent groups can be collapsed and expanded', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    _tallView(tester);

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

  testWidgets('group header shows visited / continent total', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    _tallView(tester);
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
    expect(find.text('Visited: 1 of ${3 + _extraCount}'), findsOneWidget);

    await db.close();
  });

  testWidgets('territories are nested and marked separately', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    _tallView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(
            const _TerritoryLoader(),
          ),
        ],
        child: const MaterialApp(home: CountriesListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gibraltar'), findsOneWidget);
    expect(find.text('Kosovo'), findsOneWidget);
    expect(find.text('Visited: 0 of ${1 + _extraCount}'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('territory_GI')));
    await tester.pumpAndSettle();
    expect(await db.select(db.visitedCountries).get(), hasLength(1));
    // Territory visits do not count towards the country summary.
    expect(find.text('Visited: 0 of ${1 + _extraCount}'), findsOneWidget);

    // Searching a territory keeps its parent country visible.
    await tester.enterText(find.byType(TextField), 'gibr');
    await tester.pumpAndSettle();
    expect(find.text('United Kingdom'), findsOneWidget);
    expect(find.text('Gibraltar'), findsOneWidget);
    expect(find.text('Anguilla'), findsNothing);

    await db.close();
  });
}

class _TerritoryLoader extends CountryGeoJsonLoader {
  const _TerritoryLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    Country(
      isoCode: 'GB',
      name: 'United Kingdom',
      continent: Continent.europe,
      unMember: true,
      polygons: [
        [const LatLng(50, 0), const LatLng(51, 0), const LatLng(50, 1)],
      ],
    ),
  ];
}

class _SomaliaLoader extends CountryGeoJsonLoader {
  const _SomaliaLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    Country(
      isoCode: 'SO',
      name: 'Somalia',
      continent: Continent.africa,
      unMember: true,
      polygons: [
        [const LatLng(2, 45), const LatLng(3, 45), const LatLng(2, 46)],
      ],
    ),
    Country(
      isoCode: 'XSL',
      name: 'Somaliland',
      continent: Continent.africa,
      disputed: true,
      polygons: [
        [const LatLng(9, 44), const LatLng(10, 44), const LatLng(9, 45)],
      ],
    ),
  ];
}

void _somaliaTests() {
  testWidgets('Somaliland as part of Somalia is disabled and follows it', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    _tallView(tester);
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: 'disputed.XSL',
            value: 'partOfParent',
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(
            const _SomaliaLoader(),
          ),
        ],
        child: const MaterialApp(home: CountriesListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Disabled: tapping the nested row writes nothing.
    await tester.tap(find.byKey(const ValueKey('territory_XSL')));
    await tester.pumpAndSettle();
    expect(await db.select(db.visitedCountries).get(), isEmpty);
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    // Marking Somalia marks both rows (derived check on Somaliland).
    await tester.tap(find.byKey(const ValueKey('SO')));
    await tester.pumpAndSettle();
    expect(await db.select(db.visitedCountries).get(), hasLength(1));
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));

    await db.close();
  });
}
