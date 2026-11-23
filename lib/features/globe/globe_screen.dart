import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/country_status_tag.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';
import 'globe_painter.dart';

/// Globe tab: an interactive 3D globe with visited countries highlighted.
class GlobeScreen extends ConsumerStatefulWidget {
  const GlobeScreen({super.key});

  @override
  ConsumerState<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends ConsumerState<GlobeScreen> {
  static const double _minScale = 0.8;
  static const double _maxScale = 4.0;

  // View center in radians.
  double _lat = 20 * math.pi / 180;
  double _lng = 20 * math.pi / 180;
  double _scale = 1.0;
  double _startScale = 1.0;

  List<GlobeRing>? _rings;
  List<Country>? _ringsSource;

  GlobeRelief? _relief;

  @override
  void initState() {
    super.initState();
    _loadRelief();
  }

  /// Loads the relief shader + texture. On failure the globe silently falls
  /// back to flat vector fills.
  Future<void> _loadRelief() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/globe.frag');
      final data = await rootBundle.load('assets/globe_relief.jpg');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(
        () => _relief = GlobeRelief(program: program, texture: frame.image),
      );
    } catch (e) {
      debugPrint('Globe relief unavailable, using flat fills: $e');
    }
  }

  GlobeView _viewFor(Size size) {
    final base = math.min(size.width, size.height) / 2 * 0.86;
    return GlobeView(
      centerLat: _lat,
      centerLng: _lng,
      radius: base * _scale,
      center: Offset(size.width / 2, size.height / 2),
    );
  }

  List<GlobeRing> _ringsFor(List<Country> countries) {
    if (!identical(_ringsSource, countries)) {
      _ringsSource = countries;
      _rings = GlobeRing.fromCountries(countries);
    }
    return _rings!;
  }

  void _onScaleStart(ScaleStartDetails d) => _startScale = _scale;

  void _onScaleUpdate(ScaleUpdateDetails d, Size size) {
    final view = _viewFor(size);
    setState(() {
      _scale = (_startScale * d.scale).clamp(_minScale, _maxScale);
      // Drag rotates the globe; slower when zoomed in.
      final dx = d.focalPointDelta.dx / view.radius;
      final dy = d.focalPointDelta.dy / view.radius;
      _lng -= dx / math.cos(_lat).clamp(0.3, 1.0);
      _lat = (_lat + dy).clamp(-1.4, 1.4);
    });
  }

  void _resetView() {
    setState(() {
      _lat = 20 * math.pi / 180;
      _lng = 20 * math.pi / 180;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(worldCountriesProvider);
    final statsAsync = ref.watch(worldStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: countriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load globe\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              data: (countries) {
                final rings = _ringsFor(countries);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: (d) => _onScaleUpdate(d, size),
                      child: CustomPaint(
                        size: size,
                        painter: GlobePainter(
                          rings: rings,
                          visited: ref.watch(paintedCodesProvider),
                          view: _viewFor(size),
                          relief: _relief,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    statsAsync.maybeWhen(
                      data: (s) => GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${s.visitedCount} / ${s.totalCount} (${s.percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            UnScopeBadge(basis: ref.watch(countBasisProvider)),
                          ],
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Reset button
          Positioned(
            right: 16,
            bottom: navBarClearance(context),
            child: GestureDetector(
              onTap: _resetView,
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(30),
                child: const Icon(
                  Icons.center_focus_strong,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
