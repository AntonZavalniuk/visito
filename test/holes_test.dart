import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/utils/geo_utils.dart';

void main() {
  const geojson = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","properties":{"NAME":"Host","ISO_A2":"HO"},
  "geometry":{"type":"Polygon","coordinates":[
   [[0,0],[10,0],[10,10],[0,10],[0,0]],
   [[4,4],[6,4],[6,6],[4,6],[4,4]]]}},
 {"type":"Feature","properties":{"NAME":"Enclave","ISO_A2":"EN"},
  "geometry":{"type":"Polygon","coordinates":[
   [[4,4],[6,4],[6,6],[4,6],[4,4]]]}}]}''';

  test('interior rings are holes, not extra polygons', () {
    final countries = const CountryGeoJsonLoader().parse(geojson);
    final host = countries.firstWhere((c) => c.isoCode == 'HO');
    expect(host.polygons, hasLength(1));
    expect(host.holes, hasLength(1));
    expect(isPointInCountry(const LatLng(5, 5), host), isFalse);
    expect(isPointInCountry(const LatLng(1, 1), host), isTrue);
    final enclave = countries.firstWhere((c) => c.isoCode == 'EN');
    expect(findCountryAtPoint(const LatLng(5, 5), countries), enclave);
  });
}
