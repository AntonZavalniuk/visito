import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/country_repository.dart';
import 'package:visito/data/database.dart';
import 'package:visito/models/country.dart';

void main() {
  group('Country Model', () {
    test('computes bounds and center correctly', () {
      final country = Country(
        isoCode: 'TEST',
        name: 'Testland',
        polygons: [
          [
            const LatLng(10, 20),
            const LatLng(30, 40),
            const LatLng(10, 40),
          ]
        ],
      );

      expect(country.isoCode, 'TEST');
      expect(country.name, 'Testland');
      expect(country.minLat, 10.0);
      expect(country.maxLat, 30.0);
      expect(country.minLng, 20.0);
      expect(country.maxLng, 40.0);
      expect(country.center.latitude, 20.0);
      expect(country.center.longitude, 30.0);
    });
  });

  group('CountryGeoJsonLoader', () {
    const sampleGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "NAME": "France",
        "ISO_A2": "-99",
        "ISO_A3": "-99",
        "ADM0_A3": "FRA"
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [2.0, 48.0],
            [3.0, 49.0],
            [2.5, 48.5],
            [2.0, 48.0]
          ]
        ]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "NAME": "Germany",
        "ISO_A2": "DE",
        "ISO_A3": "DEU",
        "ADM0_A3": "DEU"
      },
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": [
          [
            [
              [10.0, 50.0],
              [11.0, 51.0],
              [10.5, 50.5],
              [10.0, 50.0]
            ]
          ]
        ]
      }
    }
  ]
}
''';

    test('parses features with -99 ISO_A2 fallback to ADM0_A3', () {
      final loader = const CountryGeoJsonLoader();
      final countries = loader.parse(sampleGeoJson);

      expect(countries.length, 2);

      final france = countries.firstWhere((c) => c.name == 'France');
      expect(france.isoCode, 'FRA');
      expect(france.polygons.length, 1);
      expect(france.polygons.first.length, 4);
      expect(france.polygons.first.first.latitude, 48.0);
      expect(france.polygons.first.first.longitude, 2.0);

      final germany = countries.firstWhere((c) => c.name == 'Germany');
      expect(germany.isoCode, 'DE');
      expect(germany.polygons.length, 1);
      expect(germany.polygons.first.length, 4);
    });
  });

  group('CountryRepository', () {
    late AppDatabase db;
    late CountryRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = CountryRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('initially has no visited countries', () async {
      final visited = await repository.getVisitedCodes();
      expect(visited, isEmpty);
    });

    test('toggles country visited status', () async {
      expect(await repository.isVisited('FR'), isFalse);

      await repository.toggleVisited('FR');
      expect(await repository.isVisited('FR'), isTrue);

      final visitedAfterAdd = await repository.getVisitedCodes();
      expect(visitedAfterAdd, contains('FR'));

      await repository.toggleVisited('FR');
      expect(await repository.isVisited('FR'), isFalse);
    });

    test('setVisited sets true and false correctly', () async {
      await repository.setVisited('IT', true);
      expect(await repository.isVisited('IT'), isTrue);

      // Idempotent
      await repository.setVisited('IT', true);
      expect(await repository.isVisited('IT'), isTrue);

      await repository.setVisited('IT', false);
      expect(await repository.isVisited('IT'), isFalse);
    });

    test('watchVisitedCodes emits updates on change', () async {
      expect(
        repository.watchVisitedCodes(),
        emitsInOrder([
          <String>{},
          {'JP'},
          {'JP', 'BR'},
          {'BR'},
        ]),
      );

      await repository.toggleVisited('JP');
      await repository.toggleVisited('BR');
      await repository.toggleVisited('JP');
    });
  });
}
