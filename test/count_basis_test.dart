import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/features/profile/profile_screen.dart';
import 'package:visito/models/count_basis.dart';
import 'package:visito/models/country.dart';
import 'package:visito/models/list_entry.dart';
import 'package:visito/providers/countries_provider.dart';
import 'package:visito/providers/database_provider.dart';

ListEntry _e(
  String code,
  EntryStatus status, {
  Continent continent = Continent.europe,
  String? parent,
  bool hidden = false,
}) => ListEntry(
  code: code,
  name: code,
  status: status,
  continent: continent,
  parentCode: parent,
  hidden: hidden,
);

Country _c(
  String iso, {
  bool un = false,
  bool obs = false,
  bool disp = false,
}) => Country(
  isoCode: iso,
  name: iso,
  continent: Continent.europe,
  unMember: un,
  unObserver: obs,
  disputed: disp,
  polygons: [
    [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
  ],
);

class _Loader extends CountryGeoJsonLoader {
  const _Loader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    _c('FR', un: true),
    _c('VA', obs: true),
    _c('TW'),
    _c('XK', disp: true),
  ];
}

void main() {
  final fr = _e('FR', EntryStatus.un);
  final va = _e('VA', EntryStatus.observer);
  final tw = _e('TW', EntryStatus.none);
  final xk = _e('XK', EntryStatus.disputed);
  final gi = _e('GI', EntryStatus.none, parent: 'GB');
  final somaliland = _e('XSL', EntryStatus.disputed, parent: 'SO');
  final crimea = _e('XCR', EntryStatus.disputed, parent: 'UA', hidden: true);

  test('UN basis counts members and observers only', () {
    final counted = [
      fr,
      va,
      tw,
      xk,
      gi,
      somaliland,
      crimea,
    ].where(CountBasis.un.counts).map((e) => e.code);
    expect(counted, ['FR', 'VA']);
  });

  test('UN + DISP adds disputed states and Taiwan', () {
    final counted = [
      fr,
      va,
      tw,
      xk,
      gi,
      somaliland,
      crimea,
    ].where(CountBasis.unDisputed.counts).map((e) => e.code);
    expect(counted, ['FR', 'VA', 'TW', 'XK']);
  });

  test('a disputed state that is part of its parent is not counted', () {
    final nested = _e('XK', EntryStatus.disputed, parent: 'RS');
    expect(CountBasis.unDisputed.counts(nested), isFalse);
  });

  test('All territories counts everything except parts and hidden', () {
    final counted = [
      fr,
      va,
      tw,
      xk,
      gi,
      somaliland,
      crimea,
    ].where(CountBasis.all.counts).map((e) => e.code);
    expect(counted, ['FR', 'VA', 'TW', 'XK', 'GI']);
  });

  test('continent stats follow the counted entries', () {
    final stats = computeCountedContinentStats(
      [fr, _e('JP', EntryStatus.un, continent: Continent.asia)],
      {'JP'},
    );
    expect(stats.map((s) => (s.continent, s.visited, s.total)), [
      (Continent.asia, 1, 1),
      (Continent.europe, 0, 1),
    ]);
  });

  testWidgets('Profile switches the count basis and the totals follow', (
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
          countryGeoJsonLoaderProvider.overrideWithValue(const _Loader()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    int total() => container.read(countedEntriesProvider).length;

    expect(find.text('COUNTRY COUNT'), findsOneWidget);
    expect(find.text('UN (2)'), findsOneWidget);
    expect(total(), 2);

    await tester.tap(find.byKey(const ValueKey('count_header')));
    await tester.pumpAndSettle();
    expect(find.text('UN + DISP (10)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('count_unDisputed')));
    await tester.pumpAndSettle();
    expect(container.read(countBasisProvider), CountBasis.unDisputed);
    expect(find.text('UN + DISP (10)'), findsOneWidget);
    // FR, VA, TW, XK plus the six list-only disputed states, independent by
    // default (Somaliland, N. Cyprus, Transnistria, W. Sahara, Abkhazia,
    // S. Ossetia); hidden Crimea is not counted.
    expect(total(), 10);

    await db.close();
  });

  test(
    'ranks count visited UN countries and observers whatever the basis',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _Loader()),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await container.read(worldCountriesProvider.future);
      final repo = container.read(countryRepositoryProvider);
      for (final code in ['FR', 'VA', 'TW', 'XK']) {
        await repo.toggleVisited(code);
      }
      container.listen(
        rankVisitedCountProvider,
        (_, _) {},
        fireImmediately: true,
      );
      container.listen(worldStatsProvider, (_, _) {}, fireImmediately: true);
      for (var i = 0; i < 20; i++) {
        await pumpEventQueue();
      }
      expect(container.read(rankVisitedCountProvider), 2);

      await container
          .read(settingsRepositoryProvider)
          .setValue('countBasis', 'all');
      for (var i = 0; i < 20; i++) {
        await pumpEventQueue();
      }
      expect(container.read(worldStatsProvider).requireValue.visitedCount, 4);
      expect(container.read(rankVisitedCountProvider), 2);
    },
  );
}
