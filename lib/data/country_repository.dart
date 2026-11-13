import 'package:drift/drift.dart';

import 'database.dart';

/// Repository managing visited country persistence backed by Drift SQLite.
class CountryRepository {
  final AppDatabase _db;

  CountryRepository(this._db);

  /// Streams the set of all visited country ISO codes.
  Stream<Set<String>> watchVisitedCodes() {
    return _db.select(_db.visitedCountries).watch().map((rows) {
      return rows.map((r) => r.isoCode).toSet();
    });
  }

  /// Streams visited country ISO codes together with when they were marked.
  Stream<Map<String, DateTime>> watchVisitedEntries() {
    return _db.select(_db.visitedCountries).watch().map((rows) {
      return {for (final r in rows) r.isoCode: r.visitedAt};
    });
  }

  /// Fetches the set of all visited country ISO codes once.
  Future<Set<String>> getVisitedCodes() async {
    final rows = await _db.select(_db.visitedCountries).get();
    return rows.map((r) => r.isoCode).toSet();
  }

  /// Checks if a country is marked as visited.
  Future<bool> isVisited(String isoCode) async {
    final query = _db.select(_db.visitedCountries)
      ..where((tbl) => tbl.isoCode.equals(isoCode));
    final row = await query.getSingleOrNull();
    return row != null;
  }

  /// Toggles the visited status of a country.
  Future<void> toggleVisited(String isoCode) async {
    final exists = await isVisited(isoCode);
    if (exists) {
      final deleteQuery = _db.delete(_db.visitedCountries)
        ..where((tbl) => tbl.isoCode.equals(isoCode));
      await deleteQuery.go();
    } else {
      await _db.into(_db.visitedCountries).insert(
            VisitedCountriesCompanion.insert(
              isoCode: isoCode,
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  /// Explicitly sets the visited status for a country.
  Future<void> setVisited(String isoCode, bool visited) async {
    final exists = await isVisited(isoCode);
    if (visited && !exists) {
      await _db.into(_db.visitedCountries).insert(
            VisitedCountriesCompanion.insert(
              isoCode: isoCode,
            ),
            mode: InsertMode.insertOrReplace,
          );
    } else if (!visited && exists) {
      final deleteQuery = _db.delete(_db.visitedCountries)
        ..where((tbl) => tbl.isoCode.equals(isoCode));
      await deleteQuery.go();
    }
  }
}
