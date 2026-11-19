import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/territories.dart';
import 'package:visito/models/country.dart';
import 'package:visito/models/list_entry.dart';
import 'package:visito/providers/countries_provider.dart';

Country _c(String iso, String name, {bool un = true}) => Country(
  isoCode: iso,
  name: name,
  continent: Continent.europe,
  unMember: un,
  polygons: [
    [const LatLng(0, 0), const LatLng(0, 1), const LatLng(1, 1)],
  ],
);

void main() {
  paintsWithParentTest();
  continentsTest();
  test('territories nest under parent and extras are top-level', () {
    final entries = buildListEntries(
      [
        _c('GB', 'United Kingdom'),
        _c('CN', 'China'),
        _c('TW', 'Taiwan', un: false),
      ],
      territories: territorySpecs,
      extras: extraCountrySpecs,
    );
    final codes = entries.map((e) => e.code).toList();
    final gb = codes.indexOf('GB');
    expect(codes[gb + 1], 'AI'); // Anguilla, alphabetical first
    expect(entries.firstWhere((e) => e.code == 'GI').parentCode, 'GB');
    expect(entries.firstWhere((e) => e.code == 'TW').isTerritory, isFalse);
    final kosovo = entries.firstWhere((e) => e.code == 'XK');
    expect(kosovo.status, EntryStatus.disputed);
    expect(kosovo.isTerritory, isFalse);
    expect(
      entries.firstWhere((e) => e.code == 'CK').status,
      EntryStatus.nonMember,
    );
    // Territories whose parent is absent are dropped.
    expect(codes.contains('GP'), isFalse);
  });

  test('a territory with map polygons is nested and keeps its status', () {
    final entries = buildListEntries(
      [_c('SO', 'Somalia'), _c('XSL', 'Somaliland', un: false)],
      territories: territorySpecs,
      extras: extraCountrySpecs,
    );
    final somaliland = entries.firstWhere((e) => e.code == 'XSL');
    expect(somaliland.parentCode, 'SO');
    expect(somaliland.status, EntryStatus.disputed);
    expect(entries.where((e) => e.code == 'XSL'), hasLength(1));
  });

  test('only badged territories follow a visited parent on the map', () {
    final entries = buildListEntries(
      [
        _c('SO', 'Somalia'),
        _c('XSL', 'Somaliland', un: false),
        _c('TZ', 'Tanzania'),
        _c('XZA', 'Zanzibar', un: false),
      ],
      territories: territorySpecs,
      extras: extraCountrySpecs,
    );
    final painted = paintedCodesOf(entries, {'SO', 'TZ'});
    expect(painted, containsAll(['SO', 'TZ', 'XSL']));
    expect(painted.contains('XZA'), isFalse);
    expect(paintedCodesOf(entries, {'XZA'}), {'XZA'});
  });

  test('independent alignable territory becomes a top-level DISP entry', () {
    final entries = buildListEntries(
      [_c('SO', 'Somalia'), _c('XSL', 'Somaliland', un: false)],
      territories: territorySpecs,
      extras: extraCountrySpecs,
      independentCodes: {'XSL'},
    );
    final somaliland = entries.firstWhere((e) => e.code == 'XSL');
    expect(somaliland.isTerritory, isFalse);
    expect(somaliland.status, EntryStatus.disputed);
    expect(paintedCodesOf(entries, {'SO'}), {'SO'});
  });

  test('nested Somaliland follows Somalia and ignores a stale own mark', () {
    final countries = [_c('SO', 'Somalia'), _c('XSL', 'Somaliland', un: false)];
    final nested = buildListEntries(
      countries,
      territories: territorySpecs,
      extras: extraCountrySpecs,
    );
    final somaliland = nested.firstWhere((e) => e.code == 'XSL');
    expect(somaliland.followsParent, isTrue);
    expect(paintedCodesOf(nested, {'SO'}), {'SO', 'XSL'});
    expect(paintedCodesOf(nested, {'XSL'}), isEmpty);

    final independent = buildListEntries(
      countries,
      territories: territorySpecs,
      extras: extraCountrySpecs,
      independentCodes: {'XSL'},
    );
    expect(
      independent.firstWhere((e) => e.code == 'XSL').followsParent,
      isFalse,
    );
    expect(paintedCodesOf(independent, {'XSL'}), {'XSL'});
  });

  test('tapping a following territory resolves to its parent', () {
    final so = _c('SO', 'Somalia');
    final xsl = _c('XSL', 'Somaliland', un: false);
    final entries = buildListEntries(
      [so, xsl],
      territories: territorySpecs,
      extras: extraCountrySpecs,
    );
    expect(resolveTapTarget(xsl, entries, [so, xsl]), so);
    expect(resolveTapTarget(so, entries, [so, xsl]), so);
    final independent = buildListEntries(
      [so, xsl],
      territories: territorySpecs,
      extras: extraCountrySpecs,
      independentCodes: {'XSL'},
    );
    expect(resolveTapTarget(xsl, independent, [so, xsl]), xsl);
  });
}

void continentsTest() {
  test('an independent territory keeps its extra continents', () {
    final entries = buildListEntries(
      [
        Country(
          isoCode: 'XNC',
          name: 'Northern Cyprus',
          continent: Continent.asia,
          extraContinents: {Continent.europe},
          disputed: true,
          polygons: const [],
        ),
      ],
      territories: territorySpecs,
      extras: const [],
      independentCodes: {'XNC'},
    );
    final nc = entries.firstWhere((e) => e.code == 'XNC');
    expect(nc.continents, {Continent.asia, Continent.europe});
  });
}

void paintsWithParentTest() {
  test('constituent countries are painted with the UK and on their own', () {
    final entries = buildListEntries(
      [
        Country(
          isoCode: 'GB',
          name: 'United Kingdom',
          continent: Continent.europe,
          unMember: true,
          polygons: const [],
        ),
        for (final (c, n) in [('XEN', 'England'), ('XSC', 'Scotland')])
          Country(
            isoCode: c,
            name: n,
            continent: Continent.europe,
            polygons: const [],
          ),
      ],
      territories: territorySpecs,
      extras: const [],
    );
    expect(paintedCodesOf(entries, {'GB'}), containsAll(['GB', 'XEN', 'XSC']));
    expect(paintedCodesOf(entries, {'XEN'}), {'XEN'});
  });
}
