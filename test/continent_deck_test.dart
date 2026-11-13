import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:visito/features/stats/continent_deck.dart';
import 'package:visito/models/country.dart';
import 'package:visito/providers/countries_provider.dart';

void main() {
  testWidgets('deck ends with an Antarctica card drawn with its outline', (
    tester,
  ) async {
    final ring = [
      const LatLng(-70, -60),
      const LatLng(-70, 60),
      const LatLng(-80, 0),
    ];
    final countries = [
      Country(
        isoCode: 'JP',
        name: 'Japan',
        continent: Continent.asia,
        unMember: true,
        polygons: [ring],
      ),
      Country(
        isoCode: 'AQ',
        name: 'Antarctica',
        continent: Continent.antarctica,
        polygons: [ring],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContinentDeck(
            overall: const WorldStats(visitedCount: 1, totalCount: 1),
            continents: computeContinentStats(countries, {'JP', 'AQ'}),
            countries: countries,
            visitedCodes: const {'JP', 'AQ'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Total, Continents, Asia, Antarctica -> swipe three times.
    final deck = find.byKey(const ValueKey('deck_gesture'));
    for (var i = 0; i < 3; i++) {
      await tester.drag(deck, const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('continent_antarctica')), findsOneWidget);
    expect(find.text('Antarctica'), findsOneWidget);
    expect(find.text('No UN member countries'), findsOneWidget);
    expect(find.text('1 / 1', findRichText: true), findsOneWidget);
  });
}
