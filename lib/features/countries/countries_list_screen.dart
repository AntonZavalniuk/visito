import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/country_status_tag.dart';
import '../../core/widgets/flag_badge.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_icon_button.dart';
import '../../models/country.dart';
import '../../models/list_entry.dart';
import '../../providers/countries_provider.dart';
import '../../providers/database_provider.dart';

/// Height shared by every row of the list.
const double _rowHeight = 52;

/// Slides the countries list up over the current screen.
Future<void> showCountriesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.backgroundDark,
    clipBehavior: Clip.antiAlias,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 1,
      child: CountriesListScreen(onClose: () => Navigator.of(ctx).pop()),
    ),
  );
}

/// Alphabetical, searchable country list screen with glassmorphic cards,
/// animated filter chips, and interactive visited toggles.
class CountriesListScreen extends ConsumerStatefulWidget {
  const CountriesListScreen({super.key, this.onClose});

  /// When set, the screen renders as a sheet: a drag handle and a close button.
  final VoidCallback? onClose;

  @override
  ConsumerState<CountriesListScreen> createState() =>
      _CountriesListScreenState();
}

class _CountriesListScreenState extends ConsumerState<CountriesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Titles of continent groups the user collapsed.
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Keeps entries matching the search. A country stays when one of its
  /// territories matches (with just those territories); a country that matches
  /// itself keeps all its territories.
  List<ListEntry> _filterEntries(List<ListEntry> all) {
    bool matches(ListEntry e) =>
        _searchQuery.isEmpty ||
        e.name.toLowerCase().contains(_searchQuery) ||
        e.code.toLowerCase().contains(_searchQuery);
    if (_searchQuery.isEmpty) return all;

    final result = <ListEntry>[];
    for (final top in all.where((e) => !e.isTerritory)) {
      final kids = all.where((e) => e.parentCode == top.code).toList();
      final topMatches = matches(top);
      final shownKids = topMatches ? kids : kids.where(matches).toList();
      if (topMatches || shownKids.isNotEmpty) {
        result
          ..add(top)
          ..addAll(shownKids);
      }
    }
    return result;
  }

  /// While searching, every matching group stays expanded so results are
  /// never hidden behind a collapsed header.
  bool _isCollapsed(String title) =>
      _searchQuery.isEmpty && _collapsedGroups.contains(title);

  void _toggleGroup(String title) {
    setState(() {
      if (!_collapsedGroups.remove(title)) _collapsedGroups.add(title);
    });
  }

  /// Flattens [entries] into continent headers followed by their countries
  /// and nested territories. Continents without matches are omitted.
  ///
  /// Header counters show visited / total countries (territories excluded)
  /// for the whole continent in [allEntries]. Search does not change them.
  List<Object> _buildGroupedItems(
    List<ListEntry> entries,
    List<ListEntry> allEntries,
    Set<String> visitedCodes,
  ) {
    ({int visited, int total}) countsFor(Continent? continent) {
      final all = allEntries
          .where(
            (e) =>
                !e.isTerritory &&
                _continentsOf(e, allEntries).contains(continent),
          )
          .toList();
      final visited = all.where((e) => visitedCodes.contains(e.code)).length;
      return (visited: visited, total: all.length);
    }

    final items = <Object>[];
    final groups = <Continent?>[...Continent.values, null];
    for (final continent in groups) {
      final group = entries
          .where((e) => _continentsOf(e, allEntries).contains(continent))
          .toList();
      if (group.isEmpty) continue;
      final counts = countsFor(continent);
      final header = _ContinentHeader(
        continent: continent,
        visited: counts.visited,
        total: counts.total,
      );
      items.add(header);
      if (!_isCollapsed(header.title)) items.addAll(group);
    }
    return items;
  }

  /// Territories are grouped under their parent country's continents; a
  /// transcontinental country appears in each of its continents. Entries
  /// without a continent land in the null ("Other") group.
  static Set<Continent?> _continentsOf(ListEntry e, List<ListEntry> all) {
    var continents = e.continents;
    if (e.isTerritory) {
      for (final p in all) {
        if (p.code == e.parentCode) continents = p.continents;
      }
    }
    return continents.isEmpty ? {null} : continents;
  }

  Widget _buildContinentHeader(_ContinentHeader header) {
    final collapsed = _isCollapsed(header.title);
    return InkWell(
      key: ValueKey('group_${header.title}'),
      borderRadius: BorderRadius.circular(12),
      onTap: _searchQuery.isEmpty ? () => _toggleGroup(header.title) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: collapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              header.title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: 'Countries only; incl. disputed, observer & non-member',
              child: Text(
                '${header.visited} / ${header.total}',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(worldCountriesProvider);
    final visitedCodesAsync = ref.watch(visitedCountryCodesProvider);
    // Settings-only territories (Crimea) are not rows of the list.
    final allEntries = ref
        .watch(listEntriesProvider)
        .where((e) => !e.hidden)
        .toList();
    final painted = ref.watch(paintedCodesProvider);

    // Counts countries only (incl. disputed, observer & non-member);
    // territories are marked separately and not counted here.
    final topEntries = allEntries.where((e) => !e.isTerritory).toList();
    final visitedListCount = countriesAsync.hasValue
        ? topEntries
              .where((e) => (visitedCodesAsync.value ?? {}).contains(e.code))
              .length
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (widget.onClose != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Header & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.onClose != null ? 'Select' : 'Countries',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: widget.onClose != null ? 20 : 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (visitedListCount != null)
                              Text(
                                'Visited: $visitedListCount of ${topEntries.length}',
                                key: const ValueKey('visited_summary'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.onClose != null)
                        GlassIconButton(
                          key: const ValueKey('countries_sheet_close'),
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          size: 38,
                          iconSize: 20,
                          onTap: widget.onClose!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    borderRadius: BorderRadius.circular(16),
                    height: 50,
                    child: Center(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        cursorColor: AppColors.primaryLight,
                        decoration: InputDecoration(
                          hintText: 'Search countries or ISO code...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Country List
            Expanded(
              child: countriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryLight,
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Failed to load countries: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (_) {
                  final visitedCodes = visitedCodesAsync.value ?? <String>{};
                  final filtered = _filterEntries(allEntries);

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  final items = _buildGroupedItems(
                    filtered,
                    allEntries,
                    visitedCodes,
                  );

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      widget.onClose != null
                          ? MediaQuery.paddingOf(context).bottom + 16
                          : navBarClearance(context),
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is _ContinentHeader) {
                        return _buildContinentHeader(item);
                      }
                      final entry = item as ListEntry;
                      final isVisited = painted.contains(entry.code);

                      return _buildEntryTile(entry, isVisited);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Row for a country or territory: flag, name, status badge and a check
  /// mark when visited. Every row has the same height; territories are
  /// indented under their parent with a dotted tree connector.
  Widget _buildEntryTile(ListEntry entry, bool isVisited) {
    final tile = GlassContainer(
      key: ValueKey(entry.isTerritory ? 'territory_${entry.code}' : entry.code),
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderRadius: BorderRadius.circular(14),
      color: isVisited
          ? AppColors.primaryDark.withValues(alpha: 0.22)
          : AppColors.glassBackground(entry.isTerritory ? 0.05 : 0.08),
      borderColor: isVisited
          ? AppColors.primaryLight.withValues(alpha: 0.45)
          : AppColors.glassBorder(entry.isTerritory ? 0.10 : 0.12),
      // A territory that follows its parent is marked through the parent.
      onTap: entry.followsParent
          ? null
          : () => ref.read(countryRepositoryProvider).toggleVisited(entry.code),
      // Full width so the check mark sits at the trailing edge.
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            FlagBadge(code: entry.code),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isVisited
                            ? AppColors.primaryLight
                            : (entry.isTerritory
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (entry.status != EntryStatus.none) ...[
                    const SizedBox(width: 8),
                    EntryStatusTag(status: entry.status),
                  ],
                ],
              ),
            ),
            if (isVisited)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: entry.followsParent ? 0.55 : 1,
        child: entry.isTerritory
            ? Row(
                children: [
                  const SizedBox(width: 14),
                  const SizedBox(
                    width: 22,
                    height: _rowHeight,
                    child: CustomPaint(painter: _TreeConnectorPainter()),
                  ),
                  Expanded(child: tile),
                ],
              )
            : tile,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(32),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No countries found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results matching "$_searchQuery"'
                  : 'Try changing your filter',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  foregroundColor: AppColors.primaryLight,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.primaryLight),
                ),
                onPressed: () => _searchController.clear(),
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header row shown above each continent's countries.
class _ContinentHeader {
  _ContinentHeader({
    Continent? continent,
    String? label,
    required this.visited,
    required this.total,
  }) : title = continent?.label ?? label ?? 'Other';

  final String title;
  final int visited;
  final int total;
}

/// Dotted elbow joining a territory row to its parent country.
class _TreeConnectorPainter extends CustomPainter {
  const _TreeConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1;
    const dash = 2.0;
    final midY = size.height / 2;
    for (double y = 0; y < midY; y += dash * 2) {
      canvas.drawLine(Offset(2, y), Offset(2, y + dash), paint);
    }
    for (double x = 2; x < size.width - 2; x += dash * 2) {
      canvas.drawLine(Offset(x, midY), Offset(x + dash, midY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
