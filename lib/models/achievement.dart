import 'package:flutter/material.dart';

import '../providers/countries_provider.dart';
import 'country.dart';

/// Inputs an achievement is evaluated against.
class AchievementContext {
  AchievementContext({required this.countries, required this.visitedCodes})
    : continentStats = computeContinentStats(countries, visitedCodes),
      visitedContinents = visitedContinentsOf(countries, visitedCodes);

  final List<Country> countries;
  final Set<String> visitedCodes;

  /// Official (UN member) stats per continent.
  final List<ContinentStats> continentStats;

  /// Continents with any visited country, including Antarctica.
  final Set<Continent> visitedContinents;

  Iterable<Country> get _official => countries.where((c) => c.unMember);

  int get officialTotal => _official.length;

  int get officialVisited =>
      _official.where((c) => visitedCodes.contains(c.isoCode)).length;

  /// Visited countries whose center lies north of the equator.
  bool get visitedNorth => _visitedCenters.any((lat) => lat > 0);

  /// Visited countries whose center lies south of the equator.
  bool get visitedSouth => _visitedCenters.any((lat) => lat < 0);

  /// Latitudes of the centers of all visited countries (official or not).
  Iterable<double> get _visitedCenters => countries
      .where((c) => visitedCodes.contains(c.isoCode))
      .map((c) => c.center.latitude);

  bool get antarcticaVisited => countries.any(
    (c) =>
        c.continent == Continent.antarctica && visitedCodes.contains(c.isoCode),
  );
}

/// A badge that can be unlocked, with a measurable `current / target`.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.current,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int Function(AchievementContext) target;
  final int Function(AchievementContext) current;
}

/// An [Achievement] evaluated for the current state.
class AchievementStatus {
  const AchievementStatus({
    required this.achievement,
    required this.current,
    required this.target,
  });

  final Achievement achievement;
  final int current;
  final int target;

  /// Locked until there is a positive target that has been reached.
  bool get unlocked => target > 0 && current >= target;

  double get progress => target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
}

Achievement _countAchievement(
  String id,
  String title,
  String description,
  IconData icon,
  int n,
) => Achievement(
  id: id,
  title: title,
  description: description,
  icon: icon,
  target: (_) => n,
  current: (ctx) => ctx.officialVisited,
);

/// Static achievements plus one "X Complete" per continent that has
/// official countries.
List<Achievement> buildAchievements(AchievementContext ctx) {
  return [
    _countAchievement(
      'first_stamp',
      'First Stamp',
      'Visit your first UN country',
      Icons.flag_rounded,
      1,
    ),
    _countAchievement(
      'getting_started',
      'Getting Started',
      'Visit 5 UN countries',
      Icons.directions_walk_rounded,
      5,
    ),
    _countAchievement(
      'double_digits',
      'Double Digits',
      'Visit 10 UN countries',
      Icons.looks_one_rounded,
      10,
    ),
    _countAchievement(
      'quarter_century',
      'Quarter Century',
      'Visit 25 UN countries',
      Icons.hiking_rounded,
      25,
    ),
    _countAchievement(
      'half_century',
      'Half Century',
      'Visit 50 UN countries',
      Icons.flight_rounded,
      50,
    ),
    _countAchievement(
      'century_club',
      'Century Club',
      'Visit 100 UN countries',
      Icons.emoji_events_rounded,
      100,
    ),
    Achievement(
      id: 'half_world',
      title: 'Half the World',
      description: 'Visit half of all UN countries',
      icon: Icons.public_rounded,
      target: (c) => (c.officialTotal / 2).ceil(),
      current: (c) => c.officialVisited,
    ),
    Achievement(
      id: 'whole_world',
      title: 'Whole World',
      description: 'Visit every UN country',
      icon: Icons.workspace_premium_rounded,
      target: (c) => c.officialTotal,
      current: (c) => c.officialVisited,
    ),
    Achievement(
      id: 'six_continents',
      title: 'Six Continents',
      description: 'Visit all 6 inhabited continents',
      icon: Icons.travel_explore_rounded,
      target: (_) => 6,
      current: (c) =>
          c.visitedContinents.where((k) => k != Continent.antarctica).length,
    ),
    Achievement(
      id: 'seven_continents',
      title: 'Seven Continents',
      description: 'Visit all 7 continents incl. Antarctica',
      icon: Icons.language_rounded,
      target: (_) => 7,
      current: (c) => c.visitedContinents.length,
    ),
    Achievement(
      id: 'both_hemispheres',
      title: 'Both Hemispheres',
      description: 'Visit any countries north and south of the equator (incl. disputed & observer)',
      icon: Icons.swap_vert_circle_rounded,
      target: (_) => 2,
      current: (c) => (c.visitedNorth ? 1 : 0) + (c.visitedSouth ? 1 : 0),
    ),
    Achievement(
      id: 'polar_explorer',
      title: 'Polar Explorer',
      description: 'Set foot on Antarctica',
      icon: Icons.ac_unit_rounded,
      target: (_) => 1,
      current: (c) => c.antarcticaVisited ? 1 : 0,
    ),
    for (final cs in ctx.continentStats)
      Achievement(
        id: 'complete_${cs.continent.name}',
        title: '${cs.continent.label} Complete',
        description: 'Visit every UN country in ${cs.continent.label}',
        icon: Icons.verified_rounded,
        target: (c) => c.continentStats
            .firstWhere((s) => s.continent == cs.continent)
            .total,
        current: (c) => c.continentStats
            .firstWhere((s) => s.continent == cs.continent)
            .visited,
      ),
  ];
}

/// Evaluates all achievements for the given state.
List<AchievementStatus> evaluateAchievements(
  List<Country> countries,
  Set<String> visitedCodes,
) {
  final ctx = AchievementContext(
    countries: countries,
    visitedCodes: visitedCodes,
  );
  return [
    for (final a in buildAchievements(ctx))
      AchievementStatus(
        achievement: a,
        current: a.current(ctx),
        target: a.target(ctx),
      ),
  ];
}
