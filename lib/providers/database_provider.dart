import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/country_geo_loader.dart';
import '../data/country_repository.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';

/// Provides the singleton AppDatabase instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provides the CountryRepository instance backed by the database.
final countryRepositoryProvider = Provider<CountryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CountryRepository(db);
});

/// Provides the GeoJSON country loader.
final countryGeoJsonLoaderProvider = Provider<CountryGeoJsonLoader>((ref) {
  return const CountryGeoJsonLoader();
});

/// Provides the SettingsRepository instance backed by the database.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});
