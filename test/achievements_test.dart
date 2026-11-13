import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/models/achievement.dart';
import 'package:visito/models/country.dart';

Country _c(
  String iso,
  Continent continent, {
  bool un = true,
  String? name,
  double lat = 0.5,
}) => Country(
  isoCode: iso,
  name: name ?? iso,
  continent: continent,
  unMember: un,
  polygons: [
    [LatLng(lat, 0), LatLng(lat, 1), LatLng(lat + 0.1, 1)],
  ],
);

Map<String, AchievementStatus> _byId(List<AchievementStatus> list) => {
  for (final s in list) s.achievement.id: s,
};

void main() {
  // 4 official countries (2 Europe, 1 Asia, 1 Oceania) + non-official extras.
  final countries = [
    _c('FR', Continent.europe, lat: 46),
    _c('DE', Continent.europe, lat: 51),
    _c('JP', Continent.asia, lat: 36),
    _c('AU', Continent.oceania, lat: -25),
    _c('PS', Continent.asia, un: false),
    _c('AQ', Continent.antarctica, un: false, lat: -80),
  ];

  test('nothing is unlocked with no visited countries', () {
    final s = _byId(evaluateAchievements(countries, {}));
    expect(s.values.where((e) => e.unlocked), isEmpty);
    expect(s['first_stamp']!.current, 0);
    expect(s['first_stamp']!.progress, 0);
  });

  test('first stamp and count-based progress', () {
    final s = _byId(evaluateAchievements(countries, {'FR', 'DE'}));
    expect(s['first_stamp']!.unlocked, isTrue);
    expect(s['getting_started']!.unlocked, isFalse);
    expect(s['getting_started']!.current, 2);
    expect(s['getting_started']!.progress, closeTo(2 / 5, 1e-9));
  });

  test('only UN member countries count towards totals', () {
    // PS (observer) and AQ are visited but must not count.
    final s = _byId(evaluateAchievements(countries, {'PS', 'AQ'}));
    expect(s['first_stamp']!.unlocked, isFalse);
    expect(s['first_stamp']!.current, 0);
  });

  test('half the world uses half of the official total (rounded up)', () {
    var s = _byId(evaluateAchievements(countries, {'FR'}));
    expect(s['half_world']!.target, 2);
    expect(s['half_world']!.unlocked, isFalse);
    s = _byId(evaluateAchievements(countries, {'FR', 'JP'}));
    expect(s['half_world']!.unlocked, isTrue);
  });

  test('whole world needs every official country', () {
    var s = _byId(evaluateAchievements(countries, {'FR', 'DE', 'JP'}));
    expect(s['whole_world']!.unlocked, isFalse);
    s = _byId(evaluateAchievements(countries, {'FR', 'DE', 'JP', 'AU'}));
    expect(s['whole_world']!.unlocked, isTrue);
  });

  test(
    'continent complete is generated per continent with official countries',
    () {
      final all = _byId(evaluateAchievements(countries, {'FR', 'DE'}));
      expect(all['complete_europe']!.unlocked, isTrue);
      expect(all['complete_asia']!.unlocked, isFalse);
      expect(all['complete_oceania']!.unlocked, isFalse);
      // Antarctica has no official countries, so it has no "complete" badge.
      expect(all.containsKey('complete_antarctica'), isFalse);
    },
  );

  test('polar explorer unlocks when an Antarctica entry is visited', () {
    expect(
      _byId(
        evaluateAchievements(countries, {'FR'}),
      )['polar_explorer']!.unlocked,
      isFalse,
    );
    expect(
      _byId(
        evaluateAchievements(countries, {'AQ'}),
      )['polar_explorer']!.unlocked,
      isTrue,
    );
  });

  test('continent badges count continents with any visited country', () {
    final s = _byId(evaluateAchievements(countries, {'FR', 'PS', 'AQ'}));
    // Europe, Asia (via observer) and Antarctica.
    expect(s['seven_continents']!.current, 3);
    // Six continents excludes Antarctica.
    expect(s['six_continents']!.current, 2);
  });

  test('empty data never unlocks anything (no zero targets)', () {
    final s = evaluateAchievements(const [], {});
    expect(s.where((e) => e.unlocked), isEmpty);
  });

  test(
    'both hemispheres needs a country north and one south of the equator',
    () {
      ach(Set<String> v) =>
          _byId(evaluateAchievements(countries, v))['both_hemispheres']!;

      expect(ach({}).unlocked, isFalse);
      // Only northern countries.
      expect(ach({'FR', 'JP'}).unlocked, isFalse);
      expect(ach({'FR', 'JP'}).current, 1);
      // Only southern (Australia).
      expect(ach({'AU'}).unlocked, isFalse);
      expect(ach({'AU'}).current, 1);
      // One of each side.
      expect(ach({'FR', 'AU'}).unlocked, isTrue);
      expect(ach({'FR', 'AU'}).current, 2);
    },
  );

  test('non-official visited countries count for hemispheres', () {
    // Antarctica (south) + France (north).
    final s = _byId(evaluateAchievements(countries, {'FR', 'AQ'}));
    expect(s['both_hemispheres']!.unlocked, isTrue);
  });
}
