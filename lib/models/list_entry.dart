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
  });

  final String code;
  final String name;
  final EntryStatus status;
  final Continent? continent;

  /// Further continents the entry is listed under (see [Country]).
  final Set<Continent> extraContinents;

  Set<Continent> get continents => {?continent, ...extraContinents};

  /// ISO code of the country this territory belongs to; null for countries.
  final String? parentCode;

  bool get isTerritory => parentCode != null;

  /// A nested territory carrying a status badge (e.g. Somaliland as part of
  /// Somalia): it cannot be marked on its own, its visited state follows
  /// [parentCode].
  bool get followsParent => isTerritory && status != EntryStatus.none;
}

/// How the user treats a disputed territory.
enum DisputedAlignment { partOfParent, independent }

/// Static description of a territory (dependent or autonomous).
class TerritorySpec {
  const TerritorySpec(
    this.code,
    this.name,
    this.parentCode,
    this.continent, {
    this.status = EntryStatus.none,
    this.alignable = false,
  });

  final String code;
  final EntryStatus status;

  /// Whether the user can choose to treat this territory as an independent
  /// state instead of a part of its parent (see [DisputedAlignment]).
  final bool alignable;
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
}) {
  final top = <ListEntry>[];
  final children = <ListEntry>[];
  final specByCode = {for (final t in territories) t.code: t};

  for (final c in countries) {
    // A territory that has map polygons is listed under its parent.
    final spec = specByCode[c.isoCode];
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
          parentCode: spec.parentCode,
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
    if (!topCodes.contains(t.parentCode)) continue;
    children.add(
      ListEntry(
        code: t.code,
        name: t.name,
        status: t.status,
        continent: t.continent,
        parentCode: t.parentCode,
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
