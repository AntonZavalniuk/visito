import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Table storing visited country ISO codes and when they were marked visited.
class VisitedCountries extends Table {
  TextColumn get isoCode => text()();
  DateTimeColumn get visitedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {isoCode};
}

@DriftDatabase(tables: [VisitedCountries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'visito',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
