import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/country.dart';
import 'database_provider.dart';

/// Loads and parses the world countries GeoJSON dataset once.
final worldCountriesProvider = FutureProvider<List<Country>>((ref) async {
  final loader = ref.watch(countryGeoJsonLoaderProvider);
  return loader.loadFromBundle();
});

/// Streams the set of visited country ISO codes in real time from SQLite.
final visitedCountryCodesProvider = StreamProvider<Set<String>>((ref) {
  final repo = ref.watch(countryRepositoryProvider);
  return repo.watchVisitedCodes();
});

/// Streams when each visited country was marked (ISO code -> timestamp).
final visitedEntriesProvider = StreamProvider<Map<String, DateTime>>((ref) {
  final repo = ref.watch(countryRepositoryProvider);
  return repo.watchVisitedEntries();
});

/// Model holding statistical summary of visited countries.
class WorldStats {
  final int visitedCount;
  final int totalCount;

  const WorldStats({required this.visitedCount, required this.totalCount});

  /// Visited countries percentage (0.0% to 100.0%).
  double get percentage =>
      totalCount == 0 ? 0.0 : (visitedCount / totalCount) * 100.0;

  /// Progress fraction for progress bars (0.0 to 1.0).
  double get progress =>
      totalCount == 0 ? 0.0 : (visitedCount / totalCount).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldStats &&
          runtimeType == other.runtimeType &&
          visitedCount == other.visitedCount &&
          totalCount == other.totalCount;

  @override
  int get hashCode => Object.hash(visitedCount, totalCount);

  @override
  String toString() =>
      'WorldStats(visited: $visitedCount, total: $totalCount, percentage: ${percentage.toStringAsFixed(1)}%)';
}

/// Computes reactive statistics from loaded countries and visited codes.
final worldStatsProvider = Provider<AsyncValue<WorldStats>>((ref) {
  final countriesAsync = ref.watch(worldCountriesProvider);
  final visitedAsync = ref.watch(visitedCountryCodesProvider);

  if (countriesAsync.isLoading || visitedAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (countriesAsync.hasError) {
    return AsyncValue.error(countriesAsync.error!, countriesAsync.stackTrace!);
  }
  if (visitedAsync.hasError) {
    return AsyncValue.error(visitedAsync.error!, visitedAsync.stackTrace!);
  }

  // Only officially recognized countries (UN member states) are counted;
  // observers, disputed territories and Antarctica are excluded.
  final official = (countriesAsync.value ?? <Country>[])
      .where((c) => c.unMember)
      .toList();
  final visitedCodes = visitedAsync.value ?? {};

  final visitedCount = official
      .where((c) => visitedCodes.contains(c.isoCode))
      .length;

  return AsyncValue.data(
    WorldStats(visitedCount: visitedCount, totalCount: official.length),
  );
});

/// Visited / total official (UN member) countries for one continent.
class ContinentStats {
  const ContinentStats({
    required this.continent,
    required this.visited,
    required this.total,
  });

  final Continent continent;
  final int visited;
  final int total;

  /// Progress fraction for gauges (0.0 to 1.0).
  double get progress => total == 0 ? 0.0 : (visited / total).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is ContinentStats &&
      other.continent == continent &&
      other.visited == visited &&
      other.total == total;

  @override
  int get hashCode => Object.hash(continent, visited, total);
}

/// Computes per-continent stats from official (UN member) countries only,
/// in [Continent] display order. Continents without official countries
/// (e.g. Antarctica) are omitted.
List<ContinentStats> computeContinentStats(
  List<Country> countries,
  Set<String> visitedCodes,
) {
  final result = <ContinentStats>[];
  for (final continent in Continent.values) {
    final official = countries
        .where((c) => c.unMember && c.continent == continent)
        .toList();
    if (official.isEmpty) continue;
    result.add(
      ContinentStats(
        continent: continent,
        visited: official.where((c) => visitedCodes.contains(c.isoCode)).length,
        total: official.length,
      ),
    );
  }
  return result;
}

/// Reactive per-continent statistics.
final continentStatsProvider = Provider<List<ContinentStats>>((ref) {
  final countries = ref.watch(worldCountriesProvider).value ?? <Country>[];
  final visited = ref.watch(visitedCountryCodesProvider).value ?? <String>{};
  return computeContinentStats(countries, visited);
});

/// Continents (including Antarctica) with at least one visited country,
/// official or not.
Set<Continent> visitedContinentsOf(
  List<Country> countries,
  Set<String> visitedCodes,
) {
  final result = <Continent>{};
  for (final c in countries) {
    final continent = c.continent;
    if (continent != null && visitedCodes.contains(c.isoCode)) {
      result.add(continent);
    }
  }
  return result;
}
