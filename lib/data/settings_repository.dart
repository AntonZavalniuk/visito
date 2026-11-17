import 'package:drift/drift.dart';

import 'database.dart';

/// Key/value user settings persisted in Drift SQLite.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// Streams every stored setting as a key -> value map.
  Stream<Map<String, String>> watchAll() {
    return _db.select(_db.appSettings).watch().map((rows) {
      return {for (final r in rows) r.key: r.value};
    });
  }

  Future<String?> getValue(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(key: key, value: value),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> delete(String key) {
    return (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();
  }
}
