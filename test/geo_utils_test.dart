import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/models/country.dart';
import 'package:visito/utils/geo_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isPointInPolygon', () {
    final square = [
      const LatLng(0, 0),
      const LatLng(10, 0),
      const LatLng(10, 10),
      const LatLng(0, 10),
      const LatLng(0, 0),
    ];

    test('returns true for point strictly inside polygon', () {
      expect(isPointInPolygon(const LatLng(5, 5), square), isTrue);
    });

    test('returns false for point outside polygon', () {
      expect(isPointInPolygon(const LatLng(15, 5), square), isFalse);
      expect(isPointInPolygon(const LatLng(-5, 5), square), isFalse);
      expect(isPointInPolygon(const LatLng(5, 15), square), isFalse);
      expect(isPointInPolygon(const LatLng(5, -5), square), isFalse);
    });

    test('returns false for degenerate polygon with < 3 points', () {
      expect(isPointInPolygon(const LatLng(1, 1), []), isFalse);
      expect(
        isPointInPolygon(const LatLng(1, 1), [const LatLng(0, 0), const LatLng(2, 2)]),
        isFalse,
      );
    });

    test('correctly handles concave polygon', () {
      // U-shaped / concave polygon
      final concave = [
        const LatLng(0, 0),
        const LatLng(10, 0),
        const LatLng(10, 3),
        const LatLng(3, 3),
        const LatLng(3, 7),
        const LatLng(10, 7),
        const LatLng(10, 10),
        const LatLng(0, 10),
      ];

      // In the left bar
      expect(isPointInPolygon(const LatLng(2, 5), concave), isTrue);
      // In the empty dent of the U
      expect(isPointInPolygon(const LatLng(8, 5), concave), isFalse);
    });
  });

  group('isPointInCountry & findCountryAtPoint', () {
    final island1 = [
      const LatLng(10, 10),
      const LatLng(20, 10),
      const LatLng(20, 20),
      const LatLng(10, 20),
    ];
    final island2 = [
      const LatLng(30, 30),
      const LatLng(40, 30),
      const LatLng(40, 40),
      const LatLng(30, 40),
    ];

    final archipelago = Country(
      isoCode: 'ARC',
      name: 'Archipelago',
      polygons: [island1, island2],
    );

    final neighbor = Country(
      isoCode: 'NBR',
      name: 'Neighbor',
      polygons: [
        [
          const LatLng(-10, -10),
          const LatLng(-1, -10),
          const LatLng(-1, -1),
          const LatLng(-10, -1),
        ]
      ],
    );

    test('detects points inside multi-polygon country', () {
      expect(isPointInCountry(const LatLng(15, 15), archipelago), isTrue);
      expect(isPointInCountry(const LatLng(35, 35), archipelago), isTrue);
      // Between the islands
      expect(isPointInCountry(const LatLng(25, 25), archipelago), isFalse);
    });

    test('findCountryAtPoint resolves matching country', () {
      final countries = [archipelago, neighbor];

      expect(findCountryAtPoint(const LatLng(15, 15), countries)?.isoCode, 'ARC');
      expect(findCountryAtPoint(const LatLng(-5, -5), countries)?.isoCode, 'NBR');
      expect(findCountryAtPoint(const LatLng(0, 0), countries), isNull);
    });
  });

  group('Real world GeoJSON verification', () {
    test('resolves actual cities to correct country in assets/world_countries.geojson', () async {
      final loader = const CountryGeoJsonLoader();
      final countries = await loader.loadFromBundle();

      expect(countries.isNotEmpty, isTrue);

      // Paris, France: Lat 48.8566, Lng 2.3522
      final franceMatch = findCountryAtPoint(const LatLng(48.8566, 2.3522), countries);
      expect(franceMatch, isNotNull);
      expect(franceMatch!.name, 'France');

      // Berlin, Germany: Lat 52.5200, Lng 13.4050
      final germanyMatch = findCountryAtPoint(const LatLng(52.5200, 13.4050), countries);
      expect(germanyMatch, isNotNull);
      expect(germanyMatch!.name, 'Germany');

      // Tokyo, Japan: Lat 35.6762, Lng 139.6503
      final japanMatch = findCountryAtPoint(const LatLng(35.6762, 139.6503), countries);
      expect(japanMatch, isNotNull);
      expect(japanMatch!.name, 'Japan');

      // Mid-Atlantic Ocean: Lat 25.0, Lng -40.0 -> no country
      final oceanMatch = findCountryAtPoint(const LatLng(25.0, -40.0), countries);
      expect(oceanMatch, isNull);
    });
  });
}
