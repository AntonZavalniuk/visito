import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/countries_provider.dart';
import 'package:visito/utils/geo_utils.dart';

void main() {
  test('every bundled country has a continent', () {
    final json = File('assets/world_countries.geojson').readAsStringSync();
    final countries = const CountryGeoJsonLoader().parse(json);
    expect(countries, isNotEmpty);
    expect(countries.where((c) => c.continent == null), isEmpty);
  });

  test('Western Sahara is a disputed country distinct from Morocco', () {
    final json = File('assets/world_countries.geojson').readAsStringSync();
    final countries = const CountryGeoJsonLoader().parse(json);
    final ws = countries.firstWhere((c) => c.name == 'Western Sahara');
    expect(ws.disputed, isTrue);
    expect(ws.continent, Continent.africa);
    final inWs = LatLng(24.5, -13);
    expect(findCountryAtPoint(inWs, countries)?.name, 'Western Sahara');
    expect(findCountryAtPoint(LatLng(34.0, -6.8), countries)?.name, 'Morocco');
  });

  test('193 UN member states are flagged; Western Sahara is not', () {
    final json = File('assets/world_countries.geojson').readAsStringSync();
    final countries = const CountryGeoJsonLoader().parse(json);
    expect(countries.where((c) => c.unMember).length, 193);
    final ws = countries.firstWhere((c) => c.name == 'Western Sahara');
    expect(ws.unMember, isFalse);
  });

  test('Palestine is an Asian UN observer, not a member', () {
    final json = File('assets/world_countries.geojson').readAsStringSync();
    final countries = const CountryGeoJsonLoader().parse(json);
    final ps = countries.firstWhere((c) => c.name == 'Palestine');
    expect(ps.continent, Continent.asia);
    expect(ps.unObserver, isTrue);
    expect(ps.unMember, isFalse);
    expect(
      findCountryAtPoint(LatLng(32.0, 35.25), countries)?.name,
      'Palestine',
    );
  });

  test('Siachen Glacier is a disputed Asian territory', () {
    final json = File('assets/world_countries.geojson').readAsStringSync();
    final countries = const CountryGeoJsonLoader().parse(json);
    final sg = countries.firstWhere(
      (c) => c.name == 'Siachen Glacier (Kashmir)',
    );
    expect(sg.disputed, isTrue);
    expect(sg.continent, Continent.asia);
    expect(
      findCountryAtPoint(LatLng(35.39, 77.24), countries)?.name,
      'Siachen Glacier (Kashmir)',
    );
  });

  test('transcontinental countries use one continent everywhere', () {
    final json = File('assets/world_countries.geojson').readAsStringSync();
    final countries = const CountryGeoJsonLoader().parse(json);
    Continent? of(String name) =>
        countries.firstWhere((c) => c.name == name).continent;

    // The Countries list, the Stats cards and the card backdrops all read
    // Country.continent, so pinning it here keeps them consistent.
    expect(of('Russia'), Continent.europe);
    expect(of('Turkey'), Continent.asia);
    expect(of('Kazakhstan'), Continent.asia);
    expect(of('Egypt'), Continent.africa);

    final europe = computeContinentStats(countries, {});
    expect(
      europe.firstWhere((s) => s.continent == Continent.europe).total,
      countries
          .where((c) => c.unMember && c.continent == Continent.europe)
          .length,
    );
  });

  test('Continent.fromLabel parses GeoJSON labels', () {
    expect(Continent.fromLabel('North America'), Continent.northAmerica);
    expect(Continent.fromLabel(' asia '), Continent.asia);
    expect(Continent.fromLabel('Seven seas'), isNull);
    expect(
      jsonEncode(Continent.values.map((c) => c.label).toList()),
      contains('Antarctica'),
    );
  });
}
