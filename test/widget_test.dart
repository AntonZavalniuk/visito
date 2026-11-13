import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/app.dart';
import 'package:visito/data/country_geo_loader.dart';
import 'package:visito/data/database.dart';
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
          [const LatLng(41, 12), const LatLng(42, 12), const LatLng(41, 13)],
        ],
      ),
    ];
  }
}

void main() {
  testWidgets('App smoke test: launches and displays navigation destinations', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());

    // Build the Visito app and trigger a frame
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

    // Verify app title and active map tab
    expect(find.text('Visito'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);

    // Verify the 3 bottom navigation destinations exist
    expect(find.byIcon(Icons.map_rounded), findsOneWidget); // Active Map icon
    expect(
      find.byIcon(Icons.format_list_bulleted_outlined),
      findsOneWidget,
    ); // Countries
    expect(
      find.byIcon(Icons.pie_chart_outline_rounded),
      findsOneWidget,
    ); // Stats

    await db.close();
  });
}
