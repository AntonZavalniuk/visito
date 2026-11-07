import 'dart:async';
import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';
import '../../providers/database_provider.dart';
import '../../utils/geo_utils.dart';
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
  List<Country>? _decorativeSource;

  String? _message;
  bool _messageIsVisited = false;
  Timer? _messageTimer;

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

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _showMessage(String countryName, bool willBeVisited) {
    _messageTimer?.cancel();
    setState(() {
      _message = willBeVisited
          ? 'Marked $countryName as visited! 🎉'
          : 'Removed $countryName from visited';
      _messageIsVisited = willBeVisited;
    });
    _messageTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _message = null);
    });
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

  List<GlobeRing> _ringsFor(List<Country> countries, List<Country> decorative) {
    if (!identical(_ringsSource, countries) ||
        !identical(_decorativeSource, decorative)) {
      _ringsSource = countries;
      _decorativeSource = decorative;
      _rings = GlobeRing.fromCountries([...countries, ...decorative]);
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

  Future<void> _onTapUp(
    TapUpDetails d,
    Size size,
    List<Country> countries,
    Set<String> visited,
  ) async {
    final geo = _viewFor(size).unproject(d.localPosition);
    if (geo == null) return;
    final country = findCountryAtPoint(LatLng(geo.lat, geo.lng), countries);
    if (country == null) return;

    // Same behavior as the Map tab: tapping toggles visited status.
    _showMessage(country.name, !visited.contains(country.isoCode));
    await ref.read(countryRepositoryProvider).toggleVisited(country.isoCode);
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
    final visited = ref.watch(visitedCountryCodesProvider).value ?? <String>{};
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
                // Antarctica is drawn on the globe only (not tappable, not counted).
                final antarctica =
                    ref.watch(antarcticaProvider).value ?? const <Country>[];
                final rings = _ringsFor(countries, antarctica);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: (d) => _onScaleUpdate(d, size),
                      onTapUp: (d) => _onTapUp(d, size, countries, visited),
                      child: CustomPaint(
                        size: size,
                        painter: GlobePainter(
                          rings: rings,
                          visited: visited,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public,
                            size: 18,
                            color: AppColors.accentCyan,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Globe',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    statsAsync.maybeWhen(
                      data: (s) => GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        child: Text(
                          '${s.visitedCount} / ${s.totalCount} (${s.percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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

          // Toast
          if (_message != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: navBarClearance(context, gap: 12),
                ),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  color: _messageIsVisited
                      ? AppColors.visitedAmber.withValues(alpha: 0.30)
                      : AppColors.backgroundCard.withValues(alpha: 0.70),
                  borderColor: _messageIsVisited
                      ? AppColors.visitedAmberLight.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _messageIsVisited
                            ? Icons.check_circle_rounded
                            : Icons.remove_circle_outline_rounded,
                        size: 18,
                        color: _messageIsVisited
                            ? AppColors.visitedAmberLight
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _message!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
