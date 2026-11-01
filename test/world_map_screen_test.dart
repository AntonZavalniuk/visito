import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
import 'package:visito/features/map/world_map_screen.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/database_provider.dart';

class _FakeLoader extends CountryGeoJsonLoader {
  const _FakeLoader();

  @override
  Future<List<Country>> loadFromBundle([dynamic bundle]) async {
    return [
      Country(
        isoCode: 'FR',
        name: 'France',
        polygons: [
          [
            const LatLng(42, -5),
            const LatLng(51, -5),
            const LatLng(51, 8),
            const LatLng(42, 8),
          ]
        ],
      ),
    ];
  }
}

void main() {
  testWidgets('WorldMapScreen renders map and glass controls', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          countryGeoJsonLoaderProvider.overrideWithValue(const _FakeLoader()),
        ],
        child: const MaterialApp(
          home: WorldMapScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify brand pill is rendered
    expect(find.text('Visito'), findsOneWidget);

    // Verify zoom controls exist
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Reset view'), findsOneWidget);

    // Verify FlutterMap is rendered
    expect(find.byType(FlutterMap), findsOneWidget);

    // Tap zoom in
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();

    await db.close();
  });
}
