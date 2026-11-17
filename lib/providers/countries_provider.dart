import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/territories.dart';
import '../models/country.dart';
import '../models/list_entry.dart';
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

/// Settings key holding the alignment choice for disputed territory [code].
String disputedSettingKey(String code) => 'disputed.$code';

/// Alignment used until the user picks one: alignable disputed territories
/// are independent states.
const DisputedAlignment kDefaultDisputedAlignment =
    DisputedAlignment.independent;

/// The user's alignment choice per alignable disputed territory; a missing
/// entry means [kDefaultDisputedAlignment].
final disputedAlignmentProvider =
    StreamProvider<Map<String, DisputedAlignment>>((ref) {
      return ref.watch(settingsRepositoryProvider).watchAll().map((all) {
        return {
          for (final t in territorySpecs)
            if (t.alignable)
              t.code: switch (all[disputedSettingKey(t.code)]) {
                'independent' => DisputedAlignment.independent,
                'partOfParent' => DisputedAlignment.partOfParent,
                _ => kDefaultDisputedAlignment,
              },
        };
      });
    });

/// Codes of disputed territories the user treats as independent states.
/// Falls back to the defaults while settings are loading, so the list does
/// not flash the wrong layout.
final independentCodesProvider = Provider<Set<String>>((ref) {
  final choices =
      ref.watch(disputedAlignmentProvider).value ??
      {
        for (final t in territorySpecs)
          if (t.alignable) t.code: kDefaultDisputedAlignment,
      };
  return {
    for (final e in choices.entries)
      if (e.value == DisputedAlignment.independent) e.key,
  };
});

/// Rows for the countries list: countries (UN, observer, non-member,
/// disputed) each followed by their nested territories.
final listEntriesProvider = Provider<List<ListEntry>>((ref) {
  final countries = ref.watch(worldCountriesProvider).value ?? <Country>[];
  return buildListEntries(
    countries,
    territories: territorySpecs,
    extras: extraCountrySpecs,
    independentCodes: ref.watch(independentCodesProvider),
  );
});

/// Effective visited codes for display (map, globe, list): the stored codes,
/// except that entries which [ListEntry.followsParent] (e.g. Somaliland as
/// part of Somalia) are visited exactly when their parent is. Territories
/// without a badge are only visited when marked themselves.
Set<String> paintedCodesOf(List<ListEntry> entries, Set<String> visitedCodes) {
  final followers = {
    for (final e in entries)
      if (e.followsParent) e.code: e.parentCode!,
  };
  return {
    for (final code in visitedCodes)
      if (!followers.containsKey(code)) code,
    for (final f in followers.entries)
      if (visitedCodes.contains(f.value)) f.key,
  };
}

/// The country a tap on [tapped] should act on: the parent country when
/// [tapped] follows it (nested Somaliland), otherwise [tapped] itself.
Country resolveTapTarget(
  Country tapped,
  List<ListEntry> entries,
  List<Country> countries,
) {
  for (final e in entries) {
    if (e.code == tapped.isoCode && e.followsParent) {
      for (final c in countries) {
        if (c.isoCode == e.parentCode) return c;
      }
    }
  }
  return tapped;
}

/// Settings key holding what to restore when [code] goes back to independent.
String _savedMarksKey(String code) => '${disputedSettingKey(code)}.saved';

/// Saves the user's alignment for disputed territory [code].
///
/// Choosing "part of parent" moves a visited mark from the territory to its
/// parent (so the parent, and with it the territory, stays marked) and clears
/// the territory's own mark, since its state is derived from the parent from
/// then on. What was changed is remembered, so going back to independent
/// restores the territory's mark (with its original date) and unmarks the
/// parent again, unless the parent was marked before or the user touched it
/// in the meantime.
Future<void> setDisputedAlignment(
  WidgetRef ref,
  String code,
  DisputedAlignment alignment,
) async {
  final settings = ref.read(settingsRepositoryProvider);
  final repo = ref.read(countryRepositoryProvider);
  final key = disputedSettingKey(code);
  final spec = territorySpecs.firstWhere((t) => t.code == code);
  final parent = spec.parentCode;

  final current = await settings.getValue(key) == 'partOfParent'
      ? DisputedAlignment.partOfParent
      : DisputedAlignment.independent;
  if (current == alignment) return;

  if (alignment == DisputedAlignment.partOfParent) {
    final ownAt = await repo.visitedAt(code);
    DateTime? parentAutoAt;
    if (ownAt != null) {
      if (!await repo.isVisited(parent)) {
        await repo.markVisitedAt(parent, DateTime.now());
        // Read back: the database stores whole seconds.
        parentAutoAt = await repo.visitedAt(parent);
      }
      await repo.setVisited(code, false);
    }
    await settings.setValue(
      _savedMarksKey(code),
      jsonEncode({
        'ownAt': ownAt?.toIso8601String(),
        'parentAutoAt': parentAutoAt?.toIso8601String(),
      }),
    );
    await settings.setValue(key, 'partOfParent');
  } else {
    final raw = await settings.getValue(_savedMarksKey(code));
    if (raw != null) {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      final ownAt = DateTime.tryParse(saved['ownAt'] as String? ?? '');
      final parentAutoAt = DateTime.tryParse(
        saved['parentAutoAt'] as String? ?? '',
      );
      if (ownAt != null) await repo.markVisitedAt(code, ownAt);
      // Unmark the parent only if we marked it and it is still that row.
      if (parentAutoAt != null &&
          await repo.visitedAt(parent) == parentAutoAt) {
        await repo.setVisited(parent, false);
      }
      await settings.delete(_savedMarksKey(code));
    }
    await settings.setValue(key, 'independent');
  }
}

/// Reactive version of [paintedCodesOf].
final paintedCodesProvider = Provider<Set<String>>((ref) {
  final visited = ref.watch(visitedCountryCodesProvider).value ?? <String>{};
  return paintedCodesOf(ref.watch(listEntriesProvider), visited);
});
