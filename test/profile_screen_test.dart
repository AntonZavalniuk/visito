import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/data/settings_repository.dart';
import 'package:visito/features/countries/countries_list_screen.dart';
import 'package:visito/features/profile/profile_screen.dart';
import 'package:visito/models/country.dart';
import 'package:visito/models/list_entry.dart';
import 'package:visito/providers/countries_provider.dart';
import 'package:visito/providers/database_provider.dart';

Country _c(String iso, String name, {bool un = true}) => Country(
  isoCode: iso,
  name: name,
  continent: Continent.africa,
  unMember: un,
  disputed: !un,
  polygons: [
    [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
  ],
);

class _Loader extends CountryGeoJsonLoader {
  const _Loader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    _c('SO', 'Somalia'),
    _c('XSL', 'Somaliland', un: false),
  ];
}

void main() {
  georgiaSiblingTests();
  crimeaHiddenTest();
  crimeaTests();
  transcontinentalTests();
  northernCyprusTests();
  test('SettingsRepository stores and replaces values', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = SettingsRepository(db);
    expect(await repo.getValue('k'), isNull);
    await repo.setValue('k', 'a');
    await repo.setValue('k', 'b');
    expect(await repo.getValue('k'), 'b');
    await db.close();
  });

  testWidgets('Profile lets Somaliland be independent or part of Somalia', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _Loader()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Somaliland'), findsOneWidget);
    // The row shows the current choice; options live in a sheet.
    expect(find.byKey(const ValueKey('XNC_header')), findsOneWidget);
    expect(find.text('Independent state'), findsNWidgets(7));
    expect(find.byKey(const ValueKey('XSL_part')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('XSL_header')));
    await tester.pumpAndSettle();
    expect(find.text('Part of Somalia'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    ListEntry somaliland() =>
        container.read(listEntriesProvider).firstWhere((e) => e.code == 'XSL');
    // Default: independent state, painted on its own.
    expect(somaliland().isTerritory, isFalse);
    expect(somaliland().status, EntryStatus.disputed);
    expect(paintedCodesOf(container.read(listEntriesProvider), {'SO'}), {'SO'});

    await tester.tap(find.byKey(const ValueKey('XSL_part')));
    await tester.pumpAndSettle();
    expect(somaliland().parentCode, 'SO');
    expect(paintedCodesOf(container.read(listEntriesProvider), {'SO'}), {
      'SO',
      'XSL',
    });

    expect(find.text('Part of Somalia'), findsOneWidget); // row subtitle
    await tester.tap(find.byKey(const ValueKey('XSL_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('XSL_independent')));
    await tester.pumpAndSettle();
    expect(somaliland().isTerritory, isFalse);

    await db.close();
  });

  testWidgets('switching to Part of Somalia moves the mark to Somalia', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.visitedCountries)
        .insert(VisitedCountriesCompanion.insert(isoCode: 'XSL'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _Loader()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('XSL_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('XSL_part')));
    await tester.pumpAndSettle();
    final rows = await db.select(db.visitedCountries).get();
    expect(rows.map((r) => r.isoCode), ['SO']);

    await db.close();
  });

  group('switching back to Independent restores the previous marks', () {
    final somalilandAt = DateTime(2024, 5, 6, 7, 8, 9);

    Future<AppDatabase> pumpProfile(
      WidgetTester tester, {
      bool somaliland = false,
      bool somalia = false,
    }) async {
      final db = AppDatabase(NativeDatabase.memory());
      Future<void> mark(String code, DateTime at) => db
          .into(db.visitedCountries)
          .insert(
            VisitedCountriesCompanion.insert(
              isoCode: code,
              visitedAt: Value(at),
            ),
          );
      if (somaliland) await mark('XSL', somalilandAt);
      if (somalia) await mark('SO', DateTime(2023, 1, 2, 3, 4, 5));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            countryGeoJsonLoaderProvider.overrideWithValue(const _Loader()),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return db;
    }

    Future<void> pick(WidgetTester tester, String optionKey) async {
      await tester.tap(find.byKey(const ValueKey('XSL_header')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(optionKey)));
      await tester.pumpAndSettle();
    }

    Future<Map<String, DateTime>> marks(AppDatabase db) async => {
      for (final r in await db.select(db.visitedCountries).get())
        r.isoCode: r.visitedAt,
    };

    testWidgets('Somaliland gets its mark and date back, Somalia is unmarked', (
      tester,
    ) async {
      final db = await pumpProfile(tester, somaliland: true);
      await pick(tester, 'XSL_part');
      expect((await marks(db)).keys, ['SO']);

      await pick(tester, 'XSL_independent');
      final after = await marks(db);
      expect(after.keys, ['XSL']);
      expect(after['XSL'], somalilandAt);
      await db.close();
    });

    testWidgets('Somalia stays marked when it was marked before', (
      tester,
    ) async {
      final db = await pumpProfile(tester, somaliland: true, somalia: true);
      await pick(tester, 'XSL_part');
      await pick(tester, 'XSL_independent');
      expect((await marks(db)).keys.toSet(), {'XSL', 'SO'});
      await db.close();
    });

    testWidgets('Somalia stays marked when the user touched it meanwhile', (
      tester,
    ) async {
      final db = await pumpProfile(tester, somaliland: true);
      await pick(tester, 'XSL_part');
      // The user re-marks Somalia later (new timestamp).
      await db
          .into(db.visitedCountries)
          .insert(
            VisitedCountriesCompanion.insert(
              isoCode: 'SO',
              visitedAt: Value(DateTime(2030, 1, 1)),
            ),
            mode: InsertMode.insertOrReplace,
          );
      await pick(tester, 'XSL_independent');
      expect((await marks(db)).keys.toSet(), {'XSL', 'SO'});
      await db.close();
    });

    testWidgets('nothing is marked when nothing was marked before', (
      tester,
    ) async {
      final db = await pumpProfile(tester);
      await pick(tester, 'XSL_part');
      await pick(tester, 'XSL_independent');
      expect(await marks(db), isEmpty);
      await db.close();
    });
  });
}

class _TransLoader extends CountryGeoJsonLoader {
  const _TransLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    Country(
      isoCode: 'TR',
      name: 'Turkey',
      continent: Continent.asia,
      unMember: true,
      polygons: [
        [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
      ],
    ),
  ];
}

void transcontinentalTests() {
  testWidgets('transcontinental choice changes the continents of a country', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _TransLoader()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    Set<Continent> turkey() => container
        .read(worldCountriesProvider)
        .requireValue
        .firstWhere((c) => c.isoCode == 'TR')
        .continents;

    expect(find.text('TRANSCONTINENTAL'), findsOneWidget);
    expect(turkey(), {Continent.asia, Continent.europe});

    await tester.tap(find.byKey(const ValueKey('TR_trans_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('TR_trans_europe')));
    await tester.pumpAndSettle();
    expect(turkey(), {Continent.europe});
    expect(find.text('Europe'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('TR_trans_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('TR_trans_asia')));
    await tester.pumpAndSettle();
    expect(turkey(), {Continent.asia});

    await db.close();
  });
}

class _CyprusLoader extends CountryGeoJsonLoader {
  const _CyprusLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    for (final (iso, name) in [('CY', 'Cyprus'), ('XNC', 'Northern Cyprus')])
      Country(
        isoCode: iso,
        name: name,
        continent: Continent.asia,
        unMember: iso == 'CY',
        disputed: iso == 'XNC',
        polygons: [
          [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
        ],
      ),
  ];
}

void northernCyprusTests() {
  testWidgets('Northern Cyprus follows the continents chosen for Cyprus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _CyprusLoader()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    Set<Continent> continents(String code) => container
        .read(worldCountriesProvider)
        .requireValue
        .firstWhere((c) => c.isoCode == code)
        .continents;

    expect(continents('XNC'), {Continent.asia, Continent.europe});
    await tester.tap(find.byKey(const ValueKey('CY_trans_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('CY_trans_europe')));
    await tester.pumpAndSettle();
    expect(continents('CY'), {Continent.europe});
    expect(continents('XNC'), {Continent.europe});

    await db.close();
  });
}

class _CrimeaLoader extends CountryGeoJsonLoader {
  const _CrimeaLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    for (final (iso, name) in [
      ('UA', 'Ukraine'),
      ('RU', 'Russia'),
      ('XCR', 'Crimea'),
    ])
      Country(
        isoCode: iso,
        name: name,
        continent: Continent.europe,
        unMember: iso != 'XCR',
        disputed: iso == 'XCR',
        polygons: [
          [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
        ],
      ),
  ];
}

void crimeaTests() {
  testWidgets('Crimea is part of Ukraine or Russia, never independent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _CrimeaLoader()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    String? parentOfCrimea() => container
        .read(listEntriesProvider)
        .firstWhere((e) => e.code == 'XCR')
        .parentCode;

    // Default: Ukraine.
    expect(parentOfCrimea(), 'UA');
    expect(find.text('Part of Ukraine'), findsOneWidget);
    expect(paintedCodesOf(container.read(listEntriesProvider), {'UA'}), {
      'UA',
      'XCR',
    });

    await tester.tap(find.byKey(const ValueKey('XCR_header')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('XCR_independent')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('XCR_partAlt')));
    await tester.pumpAndSettle();
    expect(parentOfCrimea(), 'RU');
    expect(find.text('Part of Russia'), findsOneWidget);
    expect(paintedCodesOf(container.read(listEntriesProvider), {'RU'}), {
      'RU',
      'XCR',
    });
    expect(paintedCodesOf(container.read(listEntriesProvider), {'UA'}), {'UA'});

    await db.close();
  });
}

void crimeaHiddenTest() {
  testWidgets('Crimea is not a row of the countries list', (tester) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _CrimeaLoader()),
        ],
        child: const MaterialApp(home: CountriesListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ukraine'), findsOneWidget);
    expect(find.text('Crimea'), findsNothing);
    await db.close();
  });
}

class _GeorgiaLoader extends CountryGeoJsonLoader {
  const _GeorgiaLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    for (final (iso, name) in [
      ('GE', 'Georgia'),
      ('XAB', 'Abkhazia'),
      ('XSO', 'South Ossetia'),
    ])
      Country(
        isoCode: iso,
        name: name,
        continent: Continent.asia,
        unMember: iso == 'GE',
        disputed: iso != 'GE',
        polygons: [
          [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
        ],
      ),
  ];
}

void georgiaSiblingTests() {
  testWidgets('two territories of one parent do not lose each other\'s marks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    for (final code in ['XAB', 'XSO']) {
      await db
          .into(db.visitedCountries)
          .insert(VisitedCountriesCompanion.insert(isoCode: code));
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(
            const _GeorgiaLoader(),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );

    Future<void> pick(String code, String option) async {
      await tester.tap(find.byKey(ValueKey('${code}_header')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('${code}_$option')));
      await tester.pumpAndSettle();
    }

    Future<Set<String>> stored() async => {
      for (final r in await db.select(db.visitedCountries).get()) r.isoCode,
    };
    Future<Set<String>> painted() async =>
        paintedCodesOf(container.read(listEntriesProvider), await stored());

    await pick('XAB', 'part');
    await pick('XSO', 'part');
    expect(await stored(), {'GE'});
    expect(await painted(), {'GE', 'XAB', 'XSO'});

    // Abkhazia goes back: Georgia must stay, South Ossetia still relies on it.
    await pick('XAB', 'independent');
    expect(await stored(), {'GE', 'XAB'});
    expect(await painted(), {'GE', 'XAB', 'XSO'});

    // Last one goes back: Georgia is unmarked again.
    await pick('XSO', 'independent');
    expect(await stored(), {'XAB', 'XSO'});

    await db.close();
  });
}
