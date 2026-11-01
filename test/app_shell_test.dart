import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/app.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/features/countries/countries_list_screen.dart';
import 'package:visito/features/map/world_map_screen.dart';
import 'package:visito/features/stats/stats_screen.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/database_provider.dart';

class _FakeLoader extends CountryGeoJsonLoader {
  const _FakeLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async {
    return [
      Country(
        isoCode: 'IT',
        name: 'Italy',
        polygons: [
          [const LatLng(41, 12), const LatLng(42, 12), const LatLng(41, 13)]
        ],
      ),
    ];
  }
}

void main() {
  testWidgets('VisitoHomeShell navigates between Map, Countries, and Stats screens',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
        ],
        child: const VisitoApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Initially on Map screen
    expect(find.byType(WorldMapScreen), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);

    // Tap Countries tab icon
    await tester.tap(find.byIcon(Icons.format_list_bulleted_outlined));
    await tester.pumpAndSettle();

    // Countries screen should now be visible
    expect(find.byType(CountriesListScreen), findsOneWidget);
    expect(find.text('Countries'), findsWidgets);

    // Tap Stats tab icon
    await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
    await tester.pumpAndSettle();

    // Stats screen should now be visible
    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.text('Stats'), findsWidgets);
    expect(find.text('Travel Stats'), findsOneWidget);

    // Tap Map tab icon
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    // Map screen should be active again
    expect(find.byType(WorldMapScreen), findsOneWidget);
    expect(find.text('Map'), findsWidgets);

    await db.close();
  });
}
