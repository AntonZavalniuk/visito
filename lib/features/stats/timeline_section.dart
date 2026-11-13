import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/country_status_tag.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/timeline.dart';

/// "Recent" section: this-year counter, month streak and the latest countries.
class TimelineSection extends StatelessWidget {
  const TimelineSection({super.key, required this.timeline, required this.now});

  final Timeline timeline;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (timeline.recent.isEmpty) return const SizedBox.shrink();

    final streak = timeline.monthStreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      key: const ValueKey('timeline_visited'),
                      icon: Icons.calendar_today_rounded,
                      value: '${timeline.visitedCount}',
                      label: 'Visited Countries',
                      hint: 'Incl. disputed & observer',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _stat(
                      key: const ValueKey('timeline_streak'),
                      icon: Icons.local_fire_department_rounded,
                      value: '$streak',
                      label: streak == 1 ? 'Month streak' : 'Months streak',
                      highlight: streak > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 6),
              for (final e in timeline.recent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    key: ValueKey('timeline_${e.country.isoCode}'),
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.visitedAmber.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          e.country.isoCode,
                          style: const TextStyle(
                            color: AppColors.visitedAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                e.country.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Mark non-official entries (DISP / OBS); UN
                            // members are the default and stay unmarked.
                            if (CountryStatusTag.labelFor(
                                  e.country,
                                  showUnMember: false,
                                ) !=
                                null) ...[
                              const SizedBox(width: 8),
                              CountryStatusTag(
                                country: e.country,
                                showUnMember: false,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        relativeDate(e.date, now),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat({
    required Key key,
    required IconData icon,
    required String value,
    required String label,
    String? hint,
    bool highlight = false,
  }) {
    final color = highlight ? AppColors.visitedAmber : AppColors.textSecondary;
    return Column(
      key: key,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hint != null)
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
