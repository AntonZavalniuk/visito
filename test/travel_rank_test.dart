import 'package:flutter_test/flutter_test.dart';
import 'package:visito/models/travel_rank.dart';

void main() {
  group('rankProgress', () {
    test('rank boundaries match the tiers', () {
      const expected = {
        0: 'Aspiring Explorer 🌱',
        1: 'Curious Wanderer 🎒',
        4: 'Curious Wanderer 🎒',
        5: 'Globetrotter ✈️',
        19: 'Globetrotter ✈️',
        20: 'World Adventurer 🧭',
        49: 'World Adventurer 🧭',
        50: 'Master Voyager 🗺️',
        74: 'Master Voyager 🗺️',
        75: 'Legendary Citizen of Earth 👑',
        193: 'Legendary Citizen of Earth 👑',
      };
      expected.forEach((visited, title) {
        expect(rankProgress(visited).current.title, title, reason: '$visited');
      });
    });

    test('reports remaining countries and fraction to the next rank', () {
      final p = rankProgress(3); // Curious Wanderer (1) -> Globetrotter (5)
      expect(p.next!.title, 'Globetrotter ✈️');
      expect(p.remaining, 2);
      expect(p.fraction, closeTo(2 / 4, 1e-9));
      expect(p.isMax, isFalse);
    });

    test('starts at zero progress right at a boundary', () {
      final p = rankProgress(5);
      expect(p.fraction, 0);
      expect(p.remaining, 15);
    });

    test('highest rank has no next rank and full progress', () {
      final p = rankProgress(100);
      expect(p.isMax, isTrue);
      expect(p.next, isNull);
      expect(p.remaining, 0);
      expect(p.fraction, 1);
    });

    test('negative counts are treated as zero', () {
      expect(rankProgress(-4).index, 0);
    });
  });
}
