import 'package:flutter/material.dart';

import '../../models/country.dart';
import '../theme/app_colors.dart';

/// Small outlined badge describing a country's status: DISP (disputed),
/// UN (member) or OBS (UN observer). Renders nothing for other entries.
///
/// With [showUnMember] false the UN badge is hidden, which is useful where
/// official countries are the default and only exceptions need a mark.
class CountryStatusTag extends StatelessWidget {
  const CountryStatusTag({
    super.key,
    required this.country,
    this.showUnMember = true,
  });

  final Country country;
  final bool showUnMember;

  /// The badge label for [country], or null when it has none.
  static String? labelFor(Country country, {bool showUnMember = true}) {
    if (country.disputed) return 'DISP';
    if (country.unMember) return showUnMember ? 'UN' : null;
    if (country.unObserver) return 'OBS';
    return null;
  }

  static Color _colorFor(String label) => switch (label) {
    'DISP' => AppColors.textSecondary,
    'UN' => AppColors.accentCyan,
    _ => AppColors.primaryLight,
  };

  @override
  Widget build(BuildContext context) {
    final label = labelFor(country, showUnMember: showUnMember);
    if (label == null) return const SizedBox.shrink();
    return StatusBadge(label: label, color: _colorFor(label));
  }
}

/// Tiny outlined badge with a short [label] (e.g. UN, DISP, OBS).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}

/// "UN" badge with a tooltip, placed next to counters that only include UN
/// member states.
class UnScopeBadge extends StatelessWidget {
  const UnScopeBadge({super.key});

  static const String message = 'Counts UN member countries only';

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      child: StatusBadge(label: 'UN', color: AppColors.accentCyan),
    );
  }
}
