import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';

/// Modern frosted glass statistics screen visualizing travel progress,
/// world coverage percentage, travel rank, and metric cards.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  String _getTravelRank(int visited) {
    if (visited == 0) return 'Aspiring Explorer 🌱';
    if (visited <= 5) return 'Curious Wanderer 🎒';
    if (visited <= 15) return 'Globetrotter ✈️';
    if (visited <= 30) return 'World Adventurer 🧭';
    if (visited <= 60) return 'Master Voyager 🗺️';
    return 'Legendary Citizen of Earth 👑';
  }

  String _getRankDescription(int visited) {
    if (visited == 0) {
      return 'Your world journey is about to begin. Mark your first country!';
    }
    if (visited <= 5) {
      return 'Great start! You are taking your first steps across the globe.';
    }
    if (visited <= 15) {
      return 'Impressive wanderlust! You are collecting stamps and memories.';
    }
    if (visited <= 30) {
      return 'True adventurer! You have experienced diverse cultures and places.';
    }
    if (visited <= 60) {
      return 'Incredible voyager! A substantial portion of the world is familiar to you.';
    }
    return 'Extraordinary explorer! The whole planet is truly your home.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(worldStatsProvider);
    final countriesAsync = ref.watch(worldCountriesProvider);
    final visitedCodesAsync = ref.watch(visitedCountryCodesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryLight,
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading statistics: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          data: (stats) {
            final visitedCodes = visitedCodesAsync.value ?? <String>{};
            final allCountries = countriesAsync.value ?? <Country>[];
            final visitedCountries = allCountries
                .where((c) => visitedCodes.contains(c.isoCode))
                .toList();

            final remainingCount =
                (stats.totalCount - stats.visitedCount).clamp(0, stats.totalCount);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Travel Stats',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your global footprint and exploration overview',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hero Progress Glass Card
                  _buildHeroProgressCard(stats),

                  const SizedBox(height: 16),

                  // Travel Rank Card
                  _buildRankCard(stats.visitedCount),

                  const SizedBox(height: 16),

                  // Metric Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Visited',
                          value: '${stats.visitedCount}',
                          subtitle: 'Countries',
                          icon: Icons.check_circle_rounded,
                          accentColor: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Remaining',
                          value: '$remainingCount',
                          subtitle: 'To explore',
                          icon: Icons.flag_rounded,
                          accentColor: AppColors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total',
                          value: '${stats.totalCount}',
                          subtitle: 'In database',
                          icon: Icons.public_rounded,
                          accentColor: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Visited Countries Chips or Empty Callout
                  if (visitedCountries.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explored Lands',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${visitedCountries.length}',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: visitedCountries.map((c) {
                        return GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                          borderColor:
                              AppColors.primaryLight.withValues(alpha: 0.35),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    c.isoCode,
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: AppColors.accentCyan,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready to explore?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap countries on the map or in the list to track where you\'ve been!',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroProgressCard(WorldStats stats) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          AppColors.primaryDark.withValues(alpha: 0.12),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated Circular Progress Gauge
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: stats.progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    final percent = (value * 100).toStringAsFixed(1);

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background track
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 9,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        // Animated progress
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        // Center percentage text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'explored',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(width: 22),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'World Explored',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${stats.visitedCount} of ${stats.totalCount} countries visited',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Animated Linear bar
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: stats.progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 7,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(int visited) {
    final rank = _getTravelRank(visited);
    final desc = _getRankDescription(visited);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: AppColors.accentAmber,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
