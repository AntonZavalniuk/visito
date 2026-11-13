import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/countries_provider.dart';
import 'package:visito/providers/database_provider.dart';

class _FakeLoader extends CountryGeoJsonLoader {
  const _FakeLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async {
    return [
      Country(
        isoCode: 'CA',
        name: 'Canada',
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
        unMember: true,
        polygons: [
          [const LatLng(35, 139), const LatLng(36, 139), const LatLng(35, 140)],
        ],
      ),
      Country(
        isoCode: 'IT',
        name: 'Italy',
        unMember: true,
        polygons: [
          [const LatLng(41, 12), const LatLng(42, 12), const LatLng(41, 13)],
        ],
      ),
      Country(
        isoCode: 'BR',
        name: 'Brazil',
        unMember: true,
        polygons: [
          [
            const LatLng(-15, -47),
            const LatLng(-14, -47),
            const LatLng(-15, -46),
          ],
        ],
      ),
    ];
  }
}

void main() {
  group('WorldStats model', () {
    test('computes percentage and progress correctly', () {
      const stats = WorldStats(visitedCount: 1, totalCount: 4);
      expect(stats.percentage, 25.0);
      expect(stats.progress, 0.25);
    });

    test('handles zero totalCount gracefully', () {
      const stats = WorldStats(visitedCount: 0, totalCount: 0);
      expect(stats.percentage, 0.0);
      expect(stats.progress, 0.0);
    });
  });

  group('Riverpod Providers', () {
    late AppDatabase memoryDb;
    late ProviderContainer container;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(memoryDb),
          countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await memoryDb.close();
    });

    test('worldCountriesProvider loads list of countries', () async {
      final countries = await container.read(worldCountriesProvider.future);
      expect(countries.length, 4);
      expect(
        countries.map((c) => c.isoCode),
        containsAll(['CA', 'JP', 'IT', 'BR']),
      );
    });

    test('visitedCountryCodesProvider streams visited set', () async {
      final emissions = <Set<String>>[];
      final completer = Completer<void>();

      final sub = container.listen<AsyncValue<Set<String>>>(
        visitedCountryCodesProvider,
        (previous, next) {
          next.whenData((val) {
            emissions.add(val);
            if (emissions.length == 2 && !completer.isCompleted) {
              completer.complete();
            }
          });
        },
        fireImmediately: true,
      );

      final repo = container.read(countryRepositoryProvider);
      await repo.toggleVisited('JP');

      await completer.future.timeout(const Duration(seconds: 3));

      expect(emissions.first, isEmpty);
      expect(emissions.last, contains('JP'));

      sub.close();
    });

    test('worldStatsProvider calculates reactive statistics', () async {
      final statValues = <WorldStats>[];
      final completer = Completer<void>();

      // Pre-load countries
      await container.read(worldCountriesProvider.future);

      final sub = container.listen<AsyncValue<WorldStats>>(worldStatsProvider, (
        previous,
        next,
      ) {
        next.whenData((stats) {
          statValues.add(stats);
          if (statValues.length >= 3 && !completer.isCompleted) {
            completer.complete();
          }
        });
      }, fireImmediately: true);

      final repo = container.read(countryRepositoryProvider);

      // Give a tiny delay for first emission
      await pumpEventQueue();

      await repo.toggleVisited('CA');
      await pumpEventQueue();

      await repo.toggleVisited('JP');
      await pumpEventQueue();

      await completer.future.timeout(const Duration(seconds: 3));

      expect(statValues.first.visitedCount, 0);
      expect(statValues.first.totalCount, 4);

      expect(
        statValues.any((s) => s.visitedCount == 1 && s.percentage == 25.0),
        isTrue,
      );
      expect(
        statValues.any((s) => s.visitedCount == 2 && s.percentage == 50.0),
        isTrue,
      );

      sub.close();
    });
  });
}
