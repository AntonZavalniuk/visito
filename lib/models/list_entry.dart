import 'country.dart';

/// Political status of a list entry, shown as a badge.
enum EntryStatus {
  un('UN'),
  observer('OBS'),
  nonMember('NMS'),
  disputed('DISP'),
  none('');

  const EntryStatus(this.label);

  final String label;
}

/// One row of the countries list: a country or a territory nested under the
/// country it belongs to. Territories can be marked as visited on their own
/// and never count towards the official country statistics.
class ListEntry {
  const ListEntry({
    required this.code,
    required this.name,
    required this.status,
    this.continent,
    this.extraContinents = const {},
    this.parentCode,
    this.paintsWithParent = false,
    this.hidden = false,
  });

  /// Not shown in the countries list; it is configured in the Profile tab and
  /// only appears on the map and globe.
  final bool hidden;

  final String code;
  final String name;
  final EntryStatus status;
  final Continent? continent;

  /// Further continents the entry is listed under (see [Country]).
  final Set<Continent> extraContinents;

  Set<Continent> get continents => {?continent, ...extraContinents};

  /// ISO code of the country this territory belongs to; null for countries.
  final String? parentCode;

  /// A territory that is also painted whenever its parent is marked (the
  /// constituent countries of the United Kingdom), yet can be marked itself.
  final bool paintsWithParent;

  bool get isTerritory => parentCode != null;

  /// A nested territory carrying a status badge (e.g. Somaliland as part of
  /// Somalia): it cannot be marked on its own, its visited state follows
  /// [parentCode].
  bool get followsParent => isTerritory && status != EntryStatus.none;
}

/// How the user treats a disputed territory: part of its parent, part of
/// the other claimant ([TerritorySpec.altParentCode]) or a state of its own.
enum DisputedAlignment { partOfParent, independent, partOfAlt }

/// Static description of a territory (dependent or autonomous).
class TerritorySpec {
  const TerritorySpec(
    this.code,
    this.name,
    this.parentCode,
    this.continent, {
    this.status = EntryStatus.none,
    this.alignable = false,
    this.paintsWithParent = false,
    this.altParentCode,
    this.hidden = false,
    this.defaultAlignment = DisputedAlignment.independent,
  });

  final String code;
  final EntryStatus status;

  /// A second country claiming this territory (Russia for Crimea). When set,
  /// the user chooses between the two parents instead of "independent".
  final String? altParentCode;

  /// See [ListEntry.hidden].
  final bool hidden;

  /// Alignment used until the user chooses one.
  final DisputedAlignment defaultAlignment;

  /// The alignments offered to the user, in display order.
  List<DisputedAlignment> get options => altParentCode == null
      ? const [DisputedAlignment.independent, DisputedAlignment.partOfParent]
      : const [DisputedAlignment.partOfParent, DisputedAlignment.partOfAlt];

  /// The country this territory belongs to under [alignment], or null when
  /// it is independent.
  String? parentFor(DisputedAlignment alignment) => switch (alignment) {
    DisputedAlignment.independent => null,
    DisputedAlignment.partOfParent => parentCode,
    DisputedAlignment.partOfAlt => altParentCode,
  };

  /// Whether the user can choose to treat this territory as an independent
  /// state instead of a part of its parent (see [DisputedAlignment]).
  final bool alignable;

  /// See [ListEntry.paintsWithParent].
  final bool paintsWithParent;
  final String name;
  final String parentCode;
  final Continent continent;
}

/// Static description of a list-only country without map geometry
/// (non-member and disputed states).
class ExtraCountrySpec {
  const ExtraCountrySpec(this.code, this.name, this.status, this.continent);

  final String code;
  final String name;
  final EntryStatus status;
  final Continent continent;
}

EntryStatus statusOf(Country c) {
  if (c.disputed) return EntryStatus.disputed;
  if (c.unMember) return EntryStatus.un;
  if (c.unObserver) return EntryStatus.observer;
  return EntryStatus.none;
}

/// Builds the flat list model: top-level countries (sorted by name), each
/// followed by its territories (sorted by name).
List<ListEntry> buildListEntries(
  List<Country> countries, {
  required List<TerritorySpec> territories,
  required List<ExtraCountrySpec> extras,
  Set<String> independentCodes = const {},
  Set<String> altParentCodes = const {},
}) {
  final top = <ListEntry>[];
  final children = <ListEntry>[];
  final specByCode = {for (final t in territories) t.code: t};

  for (final c in countries) {
    // A territory that has map polygons is listed under its parent.
    final spec = specByCode[c.isoCode];
    final parent = spec == null
        ? null
        : altParentCodes.contains(spec.code)
        ? spec.altParentCode!
        : spec.parentCode;
    if (spec != null &&
        spec.alignable &&
        independentCodes.contains(spec.code)) {
      // Chosen as an independent state: a top-level row keeping its status.
      top.add(
        ListEntry(
          code: c.isoCode,
          name: spec.name,
          status: spec.status,
          continent: c.continent ?? spec.continent,
          extraContinents: c.extraContinents,
        ),
      );
    } else if (spec != null) {
      children.add(
        ListEntry(
          code: c.isoCode,
          name: spec.name,
          status: spec.status,
          continent: c.continent ?? spec.continent,
          extraContinents: c.extraContinents,
          parentCode: parent,
          paintsWithParent: spec.paintsWithParent,
          hidden: spec.hidden,
        ),
      );
    } else {
      top.add(
        ListEntry(
          code: c.isoCode,
          name: c.name,
          status: statusOf(c),
          continent: c.continent,
          extraContinents: c.extraContinents,
        ),
      );
    }
  }
  final known = {for (final c in countries) c.isoCode};
  for (final e in extras) {
    if (known.contains(e.code)) continue;
    top.add(
      ListEntry(
        code: e.code,
        name: e.name,
        status: e.status,
        continent: e.continent,
      ),
    );
  }
  final topCodes = {for (final t in top) t.code};
  for (final t in territories) {
    if (known.contains(t.code)) continue;
    if (t.alignable && independentCodes.contains(t.code)) {
      top.add(
        ListEntry(
          code: t.code,
          name: t.name,
          status: t.status,
          continent: t.continent,
        ),
      );
      continue;
    }
    final parent = altParentCodes.contains(t.code)
        ? t.altParentCode!
        : t.parentCode;
    if (!topCodes.contains(parent)) continue;
    children.add(
      ListEntry(
        code: t.code,
        name: t.name,
        status: t.status,
        continent: t.continent,
        parentCode: parent,
        paintsWithParent: t.paintsWithParent,
        hidden: t.hidden,
      ),
    );
  }

  int byName(ListEntry a, ListEntry b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  top.sort(byName);
  children.sort(byName);

  return [
    for (final t in top) ...[
      t,
      ...children.where((c) => c.parentCode == t.code),
    ],
  ];
}
