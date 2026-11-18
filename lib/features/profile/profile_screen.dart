import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/country_status_tag.dart';
import '../../core/widgets/flag_badge.dart';
import '../../core/widgets/glass_container.dart';
import '../../data/territories.dart';
import '../../data/transcontinental.dart';
import '../../models/country.dart';
import '../../models/list_entry.dart';
import '../../providers/countries_provider.dart';

/// Profile tab: personal preferences, including how disputed territories
/// are treated in the list and on the map.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices =
        ref.watch(disputedAlignmentProvider).value ??
        const <String, DisputedAlignment>{};
    final countries = ref.watch(worldCountriesProvider).value ?? <Country>[];
    final transcontinental = ref.watch(transcontinentalChoicesProvider);
    final alignable = territorySpecs.where((t) => t.alignable).toList();

    String parentName(TerritorySpec t) {
      for (final c in countries) {
        if (c.isoCode == t.parentCode) return c.name;
      }
      return t.parentCode;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, navBarClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'DISPUTED TERRITORIES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(
                    label: 'DISP',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how each territory is treated in the list and on the map.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    for (var i = 0; i < alignable.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      _DisputedRow(
                        spec: alignable[i],
                        parentName: parentName(alignable[i]),
                        alignment:
                            choices[alignable[i].code] ??
                            kDefaultDisputedAlignment,
                        onChanged: (a) =>
                            setDisputedAlignment(ref, alignable[i].code, a),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TRANSCONTINENTAL',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Continents to include dual-continent countries in.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    for (var i = 0; i < transcontinentalSpecs.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      _TranscontinentalRow(
                        spec: transcontinentalSpecs[i],
                        choice:
                            transcontinental[transcontinentalSpecs[i].code] ??
                            kDefaultTranscontinentalChoice,
                        onChanged: (c) => setTranscontinentalChoice(
                          ref,
                          transcontinentalSpecs[i].code,
                          c,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the disputed-territories list: flag, name, the current choice
/// as a subtitle and a chevron. Tapping opens a sheet to change the choice.
class _DisputedRow extends StatelessWidget {
  const _DisputedRow({
    required this.spec,
    required this.parentName,
    required this.alignment,
    required this.onChanged,
  });

  final TerritorySpec spec;
  final String parentName;
  final DisputedAlignment alignment;
  final ValueChanged<DisputedAlignment> onChanged;

  String _label(DisputedAlignment a) => a == DisputedAlignment.independent
      ? 'Independent state'
      : 'Part of $parentName';

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FlagBadge(code: spec.code),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    spec.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EntryStatusTag(status: spec.status),
              ],
            ),
            const SizedBox(height: 16),
            for (final option in DisputedAlignment.values) ...[
              _option(
                key: ValueKey(
                  '${spec.code}_${option == DisputedAlignment.independent ? 'independent' : 'part'}',
                ),
                label: _label(option),
                selected: alignment == option,
                onTap: () {
                  onChanged(option);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('${spec.code}_header'),
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openSheet(context),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              FlagBadge(code: spec.code),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _label(alignment),
                      key: ValueKey('${spec.code}_summary'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      key: key,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      borderRadius: BorderRadius.circular(14),
      color: selected
          ? AppColors.primaryDark.withValues(alpha: 0.22)
          : AppColors.glassBackground(0.05),
      borderColor: selected
          ? AppColors.primaryLight.withValues(alpha: 0.45)
          : AppColors.glassBorder(0.10),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// One row of the transcontinental list: flag, name and the current choice;
/// tapping opens a sheet with the options.
class _TranscontinentalRow extends StatelessWidget {
  const _TranscontinentalRow({
    required this.spec,
    required this.choice,
    required this.onChanged,
  });

  final TranscontinentalSpec spec;
  final TranscontinentalChoice choice;
  final ValueChanged<TranscontinentalChoice> onChanged;

  static String _label(TranscontinentalChoice c) => switch (c) {
    TranscontinentalChoice.both => 'Both',
    TranscontinentalChoice.europe => 'Europe',
    TranscontinentalChoice.asia => 'Asia',
  };

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FlagBadge(code: spec.code),
                const SizedBox(width: 12),
                Text(
                  spec.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final option in TranscontinentalChoice.values) ...[
              GlassContainer(
                key: ValueKey('${spec.code}_trans_${option.name}'),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(14),
                color: option == choice
                    ? AppColors.primaryDark.withValues(alpha: 0.22)
                    : AppColors.glassBackground(0.05),
                borderColor: option == choice
                    ? AppColors.primaryLight.withValues(alpha: 0.45)
                    : AppColors.glassBorder(0.10),
                onTap: () {
                  onChanged(option);
                  Navigator.of(ctx).pop();
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _label(option),
                          style: TextStyle(
                            color: option == choice
                                ? AppColors.primaryLight
                                : AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (option == choice)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryLight,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('${spec.code}_trans_header'),
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openSheet(context),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              FlagBadge(code: spec.code),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  spec.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _label(choice),
                key: ValueKey('${spec.code}_trans_value'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.unfold_more_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
