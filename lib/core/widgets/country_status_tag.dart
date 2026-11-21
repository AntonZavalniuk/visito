import 'package:flutter/material.dart';

import '../../models/count_basis.dart';
import '../../models/country.dart';
import '../../models/list_entry.dart';
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

  static Color colorForLabel(String label) => switch (label) {
    'DISP' => AppColors.textSecondary,
    'UN' => AppColors.accentCyan,
    'NMS' => AppColors.textSecondary,
    _ => AppColors.primaryLight,
  };

  @override
  Widget build(BuildContext context) {
    final label = labelFor(country, showUnMember: showUnMember);
    if (label == null) return const SizedBox.shrink();
    return StatusBadge(label: label, color: colorForLabel(label));
  }
}

/// Status badge for a [ListEntry]; renders nothing for entries without one
/// (e.g. territories).
class EntryStatusTag extends StatelessWidget {
  const EntryStatusTag({super.key, required this.status});

  final EntryStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == EntryStatus.none) return const SizedBox.shrink();
    return StatusBadge(
      label: status.label,
      color: CountryStatusTag.colorForLabel(status.label),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
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

/// Small badge with a tooltip, placed next to counters; it names what the
/// counter includes under the chosen [CountBasis].
class UnScopeBadge extends StatelessWidget {
  const UnScopeBadge({super.key, this.basis = CountBasis.un});

  final CountBasis basis;

  static const String message = 'Counts UN member countries only';

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: basis == CountBasis.un ? message : 'Counts ${basis.noun}',
      triggerMode: TooltipTriggerMode.tap,
      child: StatusBadge(
        label: switch (basis) {
          CountBasis.un => 'UN',
          CountBasis.unDisputed => 'UN+',
          CountBasis.all => 'ALL',
        },
        color: AppColors.accentCyan,
      ),
    );
  }
}
