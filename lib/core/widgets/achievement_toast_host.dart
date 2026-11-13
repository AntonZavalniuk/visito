import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/travel_rank.dart';
import '../../providers/countries_provider.dart';
import '../../providers/gamification_provider.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class _Toast {
  const _Toast({
    required this.icon,
    required this.headline,
    required this.title,
    this.celebrate = false,
  });

  final IconData icon;
  final String headline;
  final String title;
  final bool celebrate;
}

/// Wraps the app and shows celebratory toasts on top of everything:
/// "Achievement unlocked" when a badge is earned and "New rank" (with
/// confetti) when the travel rank goes up. Nothing is shown for state that
/// already existed when the app loaded.
class AchievementToastHost extends ConsumerStatefulWidget {
  const AchievementToastHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AchievementToastHost> createState() =>
      _AchievementToastHostState();
}

class _AchievementToastHostState extends ConsumerState<AchievementToastHost>
    with SingleTickerProviderStateMixin {
  static const _toastDuration = Duration(milliseconds: 3000);

  /// Achievement ids already unlocked in this session (null until loaded).
  Set<String>? _seenUnlocked;

  /// Rank index at load time / last seen (null until loaded).
  int? _rankIndex;

  final List<_Toast> _queue = [];
  _Toast? _current;
  Timer? _timer;

  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _enqueue(_Toast toast) {
    _queue.add(toast);
    if (_current == null) _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    final next = _queue.removeAt(0);
    setState(() => _current = next);
    if (next.celebrate) _confetti.forward(from: 0);
    _timer?.cancel();
    _timer = Timer(_toastDuration, () {
      if (mounted) _showNext();
    });
  }

  void _onAchievements() {
    final list = ref.read(achievementsProvider).value;
    if (list == null) return;
    final unlocked = {
      for (final s in list)
        if (s.unlocked) s.achievement.id,
    };
    final seen = _seenUnlocked;
    if (seen == null) {
      _seenUnlocked = unlocked; // baseline: do not announce existing badges
      return;
    }
    for (final s in list) {
      final id = s.achievement.id;
      if (s.unlocked && !seen.contains(id)) {
        seen.add(id);
        _enqueue(
          _Toast(
            icon: s.achievement.icon,
            headline: 'Achievement unlocked',
            title: s.achievement.title,
          ),
        );
      }
    }
  }

  void _onStats(AsyncValue<WorldStats> next) {
    final stats = next.value;
    if (stats == null) return;
    final index = rankProgress(stats.visitedCount).index;
    final previous = _rankIndex;
    _rankIndex = index;
    if (previous != null && index > previous) {
      _enqueue(
        _Toast(
          icon: Icons.military_tech_rounded,
          headline: 'New rank',
          title: kTravelRanks[index].title,
          celebrate: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(achievementsProvider, (_, _) => _onAchievements());
    ref.listen(worldStatsProvider, (_, next) => _onStats(next));

    return Stack(
      children: [
        widget.child,
        // Confetti on rank-up (never intercepts touches).
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (context, _) => _confetti.isAnimating
                  ? CustomPaint(painter: _ConfettiPainter(_confetti.value))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 72),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.4),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _current == null
                        ? const SizedBox.shrink(key: ValueKey('no_toast'))
                        : _ToastPill(
                            key: ValueKey(
                              '${_current!.headline}:${_current!.title}',
                            ),
                            toast: _current!,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastPill extends StatelessWidget {
  const _ToastPill({super.key, required this.toast});

  final _Toast toast;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        borderRadius: BorderRadius.circular(30),
        color: AppColors.visitedAmber.withValues(alpha: 0.28),
        borderColor: AppColors.visitedAmberLight.withValues(alpha: 0.55),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(toast.icon, size: 22, color: AppColors.visitedAmberLight),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toast.headline,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  toast.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple confetti burst: particles fall from the top with a little drift.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t; // 0..1

  static const _colors = [
    AppColors.visitedAmber,
    AppColors.visitedAmberLight,
    AppColors.primaryLight,
    AppColors.accentCyan,
    AppColors.accentPurple,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7); // fixed seed: same burst every time
    final fade = (1 - ((t - 0.7) / 0.3)).clamp(0.0, 1.0);
    for (var i = 0; i < 70; i++) {
      final startX = rnd.nextDouble() * size.width;
      final drift = (rnd.nextDouble() - 0.5) * 120;
      final speed = 0.6 + rnd.nextDouble() * 0.7;
      final spin = rnd.nextDouble() * 6 * math.pi;
      final w = 5 + rnd.nextDouble() * 6;
      final color = _colors[rnd.nextInt(_colors.length)];

      final y = -20 + (size.height * 0.9) * (t * speed) * (0.6 + t);
      final x = startX + drift * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.5),
        Paint()..color = color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
