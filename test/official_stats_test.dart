import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/countries_provider.dart';
import 'package:visito/providers/database_provider.dart';

class _Loader extends CountryGeoJsonLoader {
  const _Loader();

  static List<List<LatLng>> _ring() => [
    [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
  ];

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async => [
    Country(isoCode: 'FR', name: 'France', unMember: true, polygons: _ring()),
    Country(isoCode: 'JP', name: 'Japan', unMember: true, polygons: _ring()),
    Country(
      isoCode: 'PS',
      name: 'Palestine',
      unObserver: true,
      polygons: _ring(),
    ),
    Country(
      isoCode: 'EH',
      name: 'Western Sahara',
      disputed: true,
      polygons: _ring(),
    ),
  ];
}

void main() {
  test('stats count only UN member states', () async {
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
    await repo.toggleVisited('FR');
    await repo.toggleVisited('PS'); // observer: must not be counted
    await repo.toggleVisited('EH'); // disputed: must not be counted

    container.listen(worldStatsProvider, (_, _) {}, fireImmediately: true);
    for (var i = 0; i < 20; i++) {
      await pumpEventQueue();
    }

    final stats = container.read(worldStatsProvider).requireValue;
    expect(stats.totalCount, 2);
    expect(stats.visitedCount, 1);
  });
}
