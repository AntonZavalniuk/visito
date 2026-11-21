import 'list_entry.dart';

/// What the country counters (stats, list headers, globe) count.
enum CountBasis {
  /// UN member states plus the two observers (195).
  un('UN', 'UN countries'),

  /// The UN list plus every disputed state (Kosovo, Abkhazia, Western
  /// Sahara, ...) and Taiwan; Crimea is not a state of its own.
  unDisputed('UN + DISP', 'countries'),

  /// Every country and territory of the list.
  all('All Territories', 'countries and territories');

  const CountBasis(this.label, this.noun);

  final String label;

  /// What the counted things are called ("Out of 195 UN countries").
  final String noun;

  /// Whether [e] is one of the things counted under this basis.
  ///
  /// Settings-only entries (Crimea) and disputed territories treated as part
  /// of their parent are never counted on their own.
  bool counts(ListEntry e) {
    if (e.hidden || e.followsParent) return false;
    return switch (this) {
      CountBasis.un =>
        !e.isTerritory &&
            (e.status == EntryStatus.un || e.status == EntryStatus.observer),
      CountBasis.unDisputed =>
        CountBasis.un.counts(e) ||
            (!e.isTerritory &&
                (e.status == EntryStatus.disputed || e.code == 'TW')),
      CountBasis.all => true,
    };
  }
}
