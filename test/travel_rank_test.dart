import 'package:flutter_test/flutter_test.dart';
import 'package:visito/models/travel_rank.dart';

void main() {
  group('rankProgress', () {
    test('rank boundaries match the original tiers', () {
      const expected = {
        0: 'Aspiring Explorer 🌱',
        1: 'Curious Wanderer 🎒',
        5: 'Curious Wanderer 🎒',
        6: 'Globetrotter ✈️',
        15: 'Globetrotter ✈️',
        16: 'World Adventurer 🧭',
        30: 'World Adventurer 🧭',
        31: 'Master Voyager 🗺️',
        60: 'Master Voyager 🗺️',
        61: 'Legendary Citizen of Earth 👑',
        193: 'Legendary Citizen of Earth 👑',
      };
      expected.forEach((visited, title) {
        expect(rankProgress(visited).current.title, title, reason: '$visited');
      });
    });

    test('reports remaining countries and fraction to the next rank', () {
      final p = rankProgress(3); // Curious Wanderer (1) -> Globetrotter (6)
      expect(p.next!.title, 'Globetrotter ✈️');
      expect(p.remaining, 3);
      expect(p.fraction, closeTo(2 / 5, 1e-9));
      expect(p.isMax, isFalse);
    });

    test('starts at zero progress right at a boundary', () {
      final p = rankProgress(6);
      expect(p.fraction, 0);
      expect(p.remaining, 10);
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
