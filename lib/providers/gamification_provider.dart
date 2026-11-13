import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import 'countries_provider.dart';

/// Achievements evaluated against the current visited countries. Stays in the
/// loading state until both the countries and the visited set are available,
/// so consumers can tell the initial load apart from a real change.
final achievementsProvider = Provider<AsyncValue<List<AchievementStatus>>>((
  ref,
) {
  final countries = ref.watch(worldCountriesProvider);
  final visited = ref.watch(visitedCountryCodesProvider);

  if (countries.hasError) {
    return AsyncValue.error(countries.error!, countries.stackTrace!);
  }
  if (visited.hasError) {
    return AsyncValue.error(visited.error!, visited.stackTrace!);
  }
  final c = countries.value;
  final v = visited.value;
  if (c == null || v == null) return const AsyncValue.loading();

  return AsyncValue.data(evaluateAchievements(c, v));
});
