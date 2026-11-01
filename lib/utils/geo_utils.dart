import 'package:latlong2/latlong.dart';

import '../models/country.dart';

/// Checks if [point] is inside the polygon [ring] using ray casting algorithm (even-odd rule).
bool isPointInPolygon(LatLng point, List<LatLng> ring) {
  if (ring.length < 3) return false;

  final lat = point.latitude;
  final lng = point.longitude;

  bool inside = false;
  final n = ring.length;

  for (int i = 0, j = n - 1; i < n; j = i++) {
    final yi = ring[i].latitude;
    final xi = ring[i].longitude;
    final yj = ring[j].latitude;
    final xj = ring[j].longitude;

    final intersect = ((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);

    if (intersect) {
      inside = !inside;
    }
  }

  return inside;
}

/// Checks if [point] is inside any of the boundary polygons of [country].
/// Uses bounding box optimization before performing ray-casting.
bool isPointInCountry(LatLng point, Country country) {
  if (point.latitude < country.minLat ||
      point.latitude > country.maxLat ||
      point.longitude < country.minLng ||
      point.longitude > country.maxLng) {
    return false;
  }

  for (final ring in country.polygons) {
    if (isPointInPolygon(point, ring)) {
      return true;
    }
  }

  return false;
}

/// Finds the first country from [countries] containing [point], or returns `null`.
Country? findCountryAtPoint(LatLng point, List<Country> countries) {
  for (final country in countries) {
    if (isPointInCountry(point, country)) {
      return country;
    }
  }
  return null;
}
