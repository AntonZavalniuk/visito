import 'package:latlong2/latlong.dart';

/// Continents used to group countries, in display order.
enum Continent {
  africa('Africa'),
  asia('Asia'),
  europe('Europe'),
  northAmerica('North America'),
  southAmerica('South America'),
  oceania('Oceania'),
  antarctica('Antarctica');

  const Continent(this.label);

  final String label;

  /// Parses a continent label (as stored in the GeoJSON) or returns null.
  static Continent? fromLabel(String? label) {
    if (label == null) return null;
    final normalized = label.trim().toLowerCase();
    for (final c in values) {
      if (c.label.toLowerCase() == normalized) return c;
    }
    return null;
  }
}

/// Represents a country with its boundary polygons and unique ISO code.
class Country {
  final String isoCode;
  final String name;
  final Continent? continent;

  /// Territory whose sovereignty is disputed; shown with a DISP badge.
  final bool disputed;

  /// Member state of the United Nations; shown with a UN badge.
  final bool unMember;

  /// UN non-member observer state; shown with an OBS badge.
  final bool unObserver;
  final List<List<LatLng>> polygons;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  Country({
    required this.isoCode,
    required this.name,
    required this.polygons,
    this.continent,
    this.disputed = false,
    this.unMember = false,
    this.unObserver = false,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) : minLat = minLat ?? _computeMinLat(polygons),
       maxLat = maxLat ?? _computeMaxLat(polygons),
       minLng = minLng ?? _computeMinLng(polygons),
       maxLng = maxLng ?? _computeMaxLng(polygons);

  static double _computeMinLat(List<List<LatLng>> polys) {
    if (polys.isEmpty) return 0;
    double min = 90.0;
    for (final poly in polys) {
      for (final pt in poly) {
        if (pt.latitude < min) min = pt.latitude;
      }
    }
    return min;
  }

  static double _computeMaxLat(List<List<LatLng>> polys) {
    if (polys.isEmpty) return 0;
    double max = -90.0;
    for (final poly in polys) {
      for (final pt in poly) {
        if (pt.latitude > max) max = pt.latitude;
      }
    }
    return max;
  }

  static double _computeMinLng(List<List<LatLng>> polys) {
    if (polys.isEmpty) return 0;
    double min = 180.0;
    for (final poly in polys) {
      for (final pt in poly) {
        if (pt.longitude < min) min = pt.longitude;
      }
    }
    return min;
  }

  static double _computeMaxLng(List<List<LatLng>> polys) {
    if (polys.isEmpty) return 0;
    double max = -180.0;
    for (final poly in polys) {
      for (final pt in poly) {
        if (pt.longitude > max) max = pt.longitude;
      }
    }
    return max;
  }

  /// Center point approximation of the country bounding box.
  LatLng get center => LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'Country(isoCode: $isoCode, name: $name)';
}
