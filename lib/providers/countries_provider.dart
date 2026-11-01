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

/// Model holding statistical summary of visited countries.
class WorldStats {
  final int visitedCount;
  final int totalCount;

  const WorldStats({
    required this.visitedCount,
    required this.totalCount,
  });

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

  final countries = countriesAsync.value ?? [];
  final visitedCodes = visitedAsync.value ?? {};

  final visitedCount =
      countries.where((c) => visitedCodes.contains(c.isoCode)).length;

  return AsyncValue.data(
    WorldStats(
      visitedCount: visitedCount,
      totalCount: countries.length,
    ),
  );
});
