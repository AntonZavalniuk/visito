/// A travel rank earned by visiting a number of (official) countries.
class TravelRank {
  const TravelRank({
    required this.title,
    required this.minVisited,
    required this.description,
  });

  /// Display name including its emoji, e.g. `Globetrotter ✈️`.
  final String title;

  /// Minimum number of visited countries required to hold this rank.
  final int minVisited;

  final String description;
}

/// All ranks in ascending order of [TravelRank.minVisited].
const List<TravelRank> kTravelRanks = [
  TravelRank(
    title: 'Aspiring Explorer 🌱',
    minVisited: 0,
    description:
        'Your world journey is about to begin. Mark your first country!',
  ),
  TravelRank(
    title: 'Curious Wanderer 🎒',
    minVisited: 1,
    description:
        'Great start! You are taking your first steps across the globe.',
  ),
  TravelRank(
    title: 'Globetrotter ✈️',
    minVisited: 6,
    description:
        'Impressive wanderlust! You are collecting stamps and memories.',
  ),
  TravelRank(
    title: 'World Adventurer 🧭',
    minVisited: 16,
    description:
        'True adventurer! You have experienced diverse cultures and places.',
  ),
  TravelRank(
    title: 'Master Voyager 🗺️',
    minVisited: 31,
    description: 'Incredible voyager! A substantial portion of the world is familiar to you.',
  ),
  TravelRank(
    title: 'Legendary Citizen of Earth 👑',
    minVisited: 61,
    description: 'Extraordinary explorer! The whole planet is truly your home.',
  ),
];

/// Where a visitor stands on the rank ladder.
class RankProgress {
  const RankProgress({
    required this.index,
    required this.current,
    required this.next,
    required this.remaining,
    required this.fraction,
  });

  /// Index of [current] in [kTravelRanks].
  final int index;
  final TravelRank current;

  /// The next rank, or null when the highest rank is reached.
  final TravelRank? next;

  /// Countries still needed for [next] (0 at the highest rank).
  final int remaining;

  /// Progress from [current] to [next] in 0.0..1.0 (1.0 at the highest rank).
  final double fraction;

  bool get isMax => next == null;
}

/// Computes the rank and the progress towards the next one.
RankProgress rankProgress(int visited) {
  final count = visited < 0 ? 0 : visited;
  var index = 0;
  for (var i = 0; i < kTravelRanks.length; i++) {
    if (count >= kTravelRanks[i].minVisited) index = i;
  }
  final current = kTravelRanks[index];
  final next = index + 1 < kTravelRanks.length ? kTravelRanks[index + 1] : null;
  if (next == null) {
    return RankProgress(
      index: index,
      current: current,
      next: null,
      remaining: 0,
      fraction: 1,
    );
  }
  final span = next.minVisited - current.minVisited;
  return RankProgress(
    index: index,
    current: current,
    next: next,
    remaining: next.minVisited - count,
    fraction: ((count - current.minVisited) / span).clamp(0.0, 1.0),
  );
}
