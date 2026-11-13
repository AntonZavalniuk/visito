import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/country.dart';
import '../../models/travel_rank.dart';
import '../../providers/countries_provider.dart';
import '../../models/achievement.dart';
import '../../providers/gamification_provider.dart';
import '../../models/timeline.dart';
import 'achievements_section.dart';
import 'continent_deck.dart';
import 'timeline_section.dart';

/// Modern frosted glass statistics screen visualizing travel progress,
/// world coverage percentage, travel rank, and metric cards.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(worldStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading statistics: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          data: (stats) {
            final continentStats = ref.watch(continentStatsProvider);
            final timeline = computeTimeline(
              ref.watch(visitedEntriesProvider).value ?? const {},
              ref.watch(worldCountriesProvider).value ?? const <Country>[],
              DateTime.now(),
            );
            final achievements =
                ref.watch(achievementsProvider).value ??
                const <AchievementStatus>[];
            final countries =
                ref.watch(worldCountriesProvider).value ?? <Country>[];
            final visitedCodes =
                ref.watch(visitedCountryCodesProvider).value ?? <String>{};

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                navBarClearance(context),
              ),
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

                  const SizedBox(height: 24),

                  // Continent cards or Empty Callout
                  if (stats.visitedCount > 0) ...[
                    const Text(
                      'Explored Lands',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ContinentDeck(
                      overall: stats,
                      continents: continentStats,
                      countries: countries,
                      visitedCodes: visitedCodes,
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
                              color: AppColors.accentCyan.withValues(
                                alpha: 0.15,
                              ),
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

                  const SizedBox(height: 24),

                  // Recent activity & streaks
                  TimelineSection(timeline: timeline, now: DateTime.now()),
                  if (timeline.recent.isNotEmpty) const SizedBox(height: 24),

                  // Achievements
                  AchievementsSection(statuses: achievements),
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
                    const SizedBox(height: 3),
                    const Text(
                      'UN member states only',
                      key: ValueKey('hero_scope_hint'),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
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
    final progress = rankProgress(visited);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
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
                      progress.current.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      progress.current.description,
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress.fraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                key: const ValueKey('rank_progress_bar'),
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: AppColors.accentAmber,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              progress.next == null
                  ? 'Highest rank reached'
                  : '${progress.remaining} more UN '
                        '${progress.remaining == 1 ? 'country' : 'countries'}'
                        ' to ${progress.next!.title}',
              key: const ValueKey('rank_progress_label'),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
