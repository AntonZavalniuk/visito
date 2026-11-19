import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/country.dart';

/// Loads and parses GeoJSON country boundaries into [Country] domain models.
class CountryGeoJsonLoader {
  final String assetPath;

  const CountryGeoJsonLoader({
    this.assetPath = 'assets/world_countries.geojson',
  });

  /// Loads the GeoJSON asset from the given [AssetBundle] (defaults to [rootBundle])
  /// and returns parsed [Country] objects sorted alphabetically by name.
  Future<List<Country>> loadFromBundle([AssetBundle? bundle]) async {
    final effectiveBundle = bundle ?? rootBundle;
    final jsonString = await effectiveBundle.loadString(assetPath);
    return parse(jsonString);
  }

  /// Parses a GeoJSON string into a list of [Country] models.
  List<Country> parse(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>? ?? [];

    final countries = <Country>[];

    for (final featureRaw in features) {
      if (featureRaw is! Map<String, dynamic>) continue;
      final properties =
          featureRaw['properties'] as Map<String, dynamic>? ?? {};
      final geometry = featureRaw['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;

      final name = properties['NAME']?.toString().trim() ?? 'Unknown';
      final isoCode = _resolveIsoCode(properties, name);

      final geomType = geometry['type']?.toString();
      final coordinates = geometry['coordinates'];
      final polygons = <List<LatLng>>[];
      final holes = <List<LatLng>>[];

      if (geomType == 'Polygon' && coordinates is List) {
        _addRings(coordinates, polygons, holes);
      } else if (geomType == 'MultiPolygon' && coordinates is List) {
        for (final poly in coordinates) {
          if (poly is List) _addRings(poly, polygons, holes);
        }
      }

      if (polygons.isNotEmpty) {
        countries.add(
          Country(
            isoCode: isoCode,
            name: name,
            continent: Continent.fromLabel(properties['CONTINENT']?.toString()),
            disputed: properties['DISPUTED'] == true,
            unMember: properties['UN_MEMBER'] == true,
            unObserver: properties['UN_OBSERVER'] == true,
            polygons: polygons,
            holes: holes,
          ),
        );
      }
    }

    // Sort alphabetically by name
    countries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return countries;
  }

  /// Natural Earth's `ISO_A2` is '-99' for some countries (e.g. France, Norway, Kosovo).
  /// Falls back to `ISO_A3` or `ADM0_A3` so no country fails to load or identify uniquely.
  static String _resolveIsoCode(
    Map<String, dynamic> props,
    String fallbackName,
  ) {
    final isoA2 = props['ISO_A2']?.toString().trim();
    if (isoA2 != null &&
        isoA2.isNotEmpty &&
        isoA2 != '-99' &&
        isoA2.toLowerCase() != 'none') {
      return isoA2;
    }

    final isoA3 = props['ISO_A3']?.toString().trim();
    if (isoA3 != null &&
        isoA3.isNotEmpty &&
        isoA3 != '-99' &&
        isoA3.toLowerCase() != 'none') {
      return isoA3;
    }

    final adm0 = props['ADM0_A3']?.toString().trim();
    if (adm0 != null &&
        adm0.isNotEmpty &&
        adm0 != '-99' &&
        adm0.toLowerCase() != 'none') {
      return adm0;
    }

    return fallbackName;
  }

  /// The first ring of a GeoJSON polygon is its outline, the rest are holes.
  static void _addRings(
    List<dynamic> rings,
    List<List<LatLng>> polygons,
    List<List<LatLng>> holes,
  ) {
    for (var i = 0; i < rings.length; i++) {
      final ring = rings[i];
      if (ring is! List || ring.isEmpty) continue;
      final points = _parseRing(ring);
      if (points.isEmpty) continue;
      (i == 0 ? polygons : holes).add(points);
    }
  }

  static List<LatLng> _parseRing(List<dynamic> ring) {
    final points = <LatLng>[];
    for (final coord in ring) {
      if (coord is List && coord.length >= 2) {
        final lng = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }
    }
    return points;
  }
}
