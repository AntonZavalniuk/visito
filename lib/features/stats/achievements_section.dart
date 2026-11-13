import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/achievement.dart';

/// "Achievements" section: a grid of badges, unlocked ones highlighted in
/// amber and locked ones greyed out with their progress.
class AchievementsSection extends StatelessWidget {
  static const int _columns = 3;
  static const double _spacing = 8;

  const AchievementsSection({super.key, required this.statuses});

  final List<AchievementStatus> statuses;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();
    final unlocked = statuses.where((s) => s.unlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$unlocked / ${statuses.length}',
              key: const ValueKey('achievements_counter'),
              style: const TextStyle(
                color: AppColors.visitedAmber,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Rows of three tiles: every row is exactly as tall as its tallest
        // tile (no fixed height, so no wasted space), and tiles in a row
        // stretch to the same height.
        for (var i = 0; i < statuses.length; i += _columns) ...[
          if (i > 0) const SizedBox(height: _spacing),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < _columns; j++) ...[
                  if (j > 0) const SizedBox(width: _spacing),
                  Expanded(
                    child: i + j < statuses.length
                        ? _BadgeTile(status: statuses[i + j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.status});

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) {
    final a = status.achievement;
    final unlocked = status.unlocked;
    final accent = unlocked ? AppColors.visitedAmber : AppColors.textMuted;

    return Tooltip(
      message: a.description,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        key: ValueKey('achievement_${a.id}'),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.visitedAmber.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked
                ? AppColors.visitedAmber.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: unlocked ? 0.22 : 0.12),
              ),
              child: Icon(
                unlocked ? a.icon : Icons.lock_outline_rounded,
                size: 19,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              a.description,
              key: ValueKey('achievement_desc_${a.id}'),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            // Pushes the status to the bottom edge of the tile.
            const Spacer(),
            const SizedBox(height: 5),
            Text(
              unlocked ? 'Unlocked' : '${status.current} / ${status.target}',
              style: TextStyle(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
