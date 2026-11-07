import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';
import '../../providers/database_provider.dart';

enum CountryFilter { all, visited, unvisited }

/// Alphabetical, searchable country list screen with glassmorphic cards,
/// animated filter chips, and interactive visited toggles.
class CountriesListScreen extends ConsumerStatefulWidget {
  const CountriesListScreen({super.key});

  @override
  ConsumerState<CountriesListScreen> createState() =>
      _CountriesListScreenState();
}

class _CountriesListScreenState extends ConsumerState<CountriesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  CountryFilter _currentFilter = CountryFilter.all;
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

  List<Country> _filterCountries(
    List<Country> allCountries,
    Set<String> visitedCodes,
  ) {
    return allCountries.where((country) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          country.name.toLowerCase().contains(_searchQuery) ||
          country.isoCode.toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      final isVisited = visitedCodes.contains(country.isoCode);
      switch (_currentFilter) {
        case CountryFilter.all:
          return true;
        case CountryFilter.visited:
          return isVisited;
        case CountryFilter.unvisited:
          return !isVisited;
      }
    }).toList();
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

  /// Flattens [countries] into continent headers followed by their countries.
  /// Continents without matching countries are omitted.
  ///
  /// Header counters show count / total for the whole continent in
  /// [allCountries]: visited / total, or unvisited / total under the
  /// Unvisited filter. Search does not change them.
  List<Object> _buildGroupedItems(
    List<Country> countries,
    List<Country> allCountries,
    Set<String> visitedCodes,
  ) {
    ({int visited, int total}) countsFor(bool Function(Country) inGroup) {
      final all = allCountries.where(inGroup).toList();
      final visited = all.where((c) => visitedCodes.contains(c.isoCode)).length;
      // Under the Unvisited filter the counter shows unvisited / total.
      return (
        visited: _currentFilter == CountryFilter.unvisited
            ? all.length - visited
            : visited,
        total: all.length,
      );
    }

    final items = <Object>[];
    for (final continent in Continent.values) {
      final group = countries.where((c) => c.continent == continent).toList();
      if (group.isEmpty) continue;
      final counts = countsFor((c) => c.continent == continent);
      items.add(
        _ContinentHeader(
          continent: continent,
          visited: counts.visited,
          total: counts.total,
        ),
      );
      if (!_isCollapsed(continent.label)) items.addAll(group);
    }
    // Countries without a known continent are listed last.
    final other = countries.where((c) => c.continent == null).toList();
    if (other.isNotEmpty) {
      final counts = countsFor((c) => c.continent == null);
      items.add(
        _ContinentHeader(
          label: 'Other',
          visited: counts.visited,
          total: counts.total,
        ),
      );
      if (!_isCollapsed('Other')) items.addAll(other);
    }
    return items;
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
            Text(
              '${header.visited} / ${header.total}',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
    final statsAsync = ref.watch(worldStatsProvider);

    // Chip counters describe the list below (all entries), while the header
    // pill shows the official (UN member) stats.
    final allListCountries = countriesAsync.value;
    final visitedListCount = allListCountries
        ?.where((c) => (visitedCodesAsync.value ?? {}).contains(c.isoCode))
        .length;
    final unvisitedListCount =
        allListCountries == null || visitedListCount == null
        ? null
        : allListCountries.length - visitedListCount;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Countries',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      statsAsync.when(
                        data: (stats) => GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Text(
                            '${stats.visitedCount} / ${stats.totalCount}',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
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

                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          title: 'All',
                          filter: CountryFilter.all,
                          count: countriesAsync.value?.length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          title: 'Visited',
                          filter: CountryFilter.visited,
                          count: visitedListCount,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          title: 'Unvisited',
                          filter: CountryFilter.unvisited,
                          count: unvisitedListCount,
                        ),
                      ],
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
                data: (allCountries) {
                  final visitedCodes = visitedCodesAsync.value ?? <String>{};
                  final filtered = _filterCountries(allCountries, visitedCodes);

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  final items = _buildGroupedItems(
                    filtered,
                    allCountries,
                    visitedCodes,
                  );

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      navBarClearance(context),
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is _ContinentHeader) {
                        return _buildContinentHeader(item);
                      }
                      final country = item as Country;
                      final isVisited = visitedCodes.contains(country.isoCode);

                      return _buildCountryTile(country, isVisited);
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

  Widget _buildFilterChip({
    required String title,
    required CountryFilter filter,
    int? count,
  }) {
    final isSelected = _currentFilter == filter;

    return GestureDetector(
      key: ValueKey('filter_${filter.name}'),
      onTap: () => setState(() => _currentFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountryTile(Country country, bool isVisited) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(16),
          color: isVisited
              ? AppColors.primaryDark.withValues(alpha: 0.22)
              : AppColors.glassBackground(0.08),
          borderColor: isVisited
              ? AppColors.primaryLight.withValues(alpha: 0.45)
              : AppColors.glassBorder(0.12),
          onTap: () {
            ref.read(countryRepositoryProvider).toggleVisited(country.isoCode);
          },
          child: Row(
            children: [
              // ISO Code pill
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isVisited
                      ? AppColors.primary.withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVisited
                        ? AppColors.primaryLight.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    country.isoCode,
                    style: TextStyle(
                      color: isVisited
                          ? AppColors.primaryLight
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Country Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            country.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (country.disputed) ...[
                          const SizedBox(width: 8),
                          _buildTag('DISP', AppColors.textSecondary),
                        ] else if (country.unMember) ...[
                          const SizedBox(width: 8),
                          _buildTag('UN', AppColors.accentCyan),
                        ] else if (country.unObserver) ...[
                          const SizedBox(width: 8),
                          _buildTag('OBS', AppColors.primaryLight),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVisited ? 'Visited' : 'Not visited yet',
                      style: TextStyle(
                        color: isVisited
                            ? AppColors.primaryLight
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Switch Toggle
              Switch.adaptive(
                value: isVisited,
                activeThumbColor: AppColors.primaryLight,
                activeTrackColor: AppColors.primaryDark,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                onChanged: (_) {
                  ref
                      .read(countryRepositoryProvider)
                      .toggleVisited(country.isoCode);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small outlined badge shown next to a country name (e.g. UN, DISP).
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
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
