import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_icon_button.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';
import '../../providers/database_provider.dart';
import '../../utils/geo_utils.dart';

/// Interactive world map screen with dark background, polygon overlays,
/// tap-to-toggle visited status, and modern frosted glass controls.
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  String? _tappedCountryMessage;
  bool _tappedIsVisited = false;
  Timer? _messageDismissTimer;

  late final AnimationController _bannerAnimController;
  late final Animation<Offset> _bannerSlideAnimation;
  late final Animation<double> _bannerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _bannerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _bannerAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bannerFadeAnimation = CurvedAnimation(
      parent: _bannerAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _messageDismissTimer?.cancel();
    _bannerAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _showMessage(String countryName, bool willBeVisited) {
    _messageDismissTimer?.cancel();
    setState(() {
      _tappedCountryMessage = willBeVisited
          ? 'Marked $countryName as visited! 🎉'
          : 'Removed $countryName from visited';
      _tappedIsVisited = willBeVisited;
    });

    _bannerAnimController.forward();

    _messageDismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _bannerAnimController.reverse().then((_) {
          if (mounted) {
            setState(() => _tappedCountryMessage = null);
          }
        });
      }
    });
  }

  Future<void> _handleMapTap(
    LatLng point,
    List<Country> countries,
    Set<String> visitedCodes,
  ) async {
    final country = findCountryAtPoint(point, countries);
    if (country == null) return;

    final isCurrentlyVisited = visitedCodes.contains(country.isoCode);
    final nextState = !isCurrentlyVisited;

    _showMessage(country.name, nextState);
    await ref.read(countryRepositoryProvider).toggleVisited(country.isoCode);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(1.5, 9.0),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(1.5, 9.0),
    );
  }

  void _resetView() {
    _mapController.move(const LatLng(20, 0), 2.2);
  }

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(worldCountriesProvider);
    final visitedCodesAsync = ref.watch(visitedCountryCodesProvider);
    final statsAsync = ref.watch(worldStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // 1. Map Layer — solid dark background, no tiles
          countriesAsync.when(
            loading: () => _buildLoadingState(),
            error: (err, stack) => _buildErrorState(err),
            data: (countries) {
              final visitedCodes = visitedCodesAsync.value ?? <String>{};

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(20, 0),
                  initialZoom: 2.2,
                  minZoom: 1.5,
                  maxZoom: 9.0,
                  backgroundColor: AppColors.backgroundDark,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (tapPosition, point) =>
                      _handleMapTap(point, countries, visitedCodes),
                ),
                children: [
                  // No TileLayer — plain dark background from MapOptions
                  PolygonLayer(
                    polygons: _buildCountryPolygons(countries, visitedCodes),
                  ),
                ],
              );
            },
          ),

          // 2. Top Frosted Header & Stats Pill
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
                    // Brand Pill
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Visito',
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

                    // Stats badge
                    statsAsync.when(
                      data: (stats) => GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public,
                              size: 16,
                              color: AppColors.accentCyan,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${stats.visitedCount} / ${stats.totalCount} (${stats.percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Right-side Glass Zoom & Controls
          Positioned(
            right: 16,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassIconButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 10),
                GlassIconButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 10),
                GlassIconButton(
                  icon: Icons.center_focus_strong,
                  tooltip: 'Reset view',
                  onTap: _resetView,
                ),
              ],
            ),
          ),

          // 4. Animated Toast / Notification Pill
          if (_tappedCountryMessage != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: SlideTransition(
                    position: _bannerSlideAnimation,
                    child: FadeTransition(
                      opacity: _bannerFadeAnimation,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        color: _tappedIsVisited
                            ? AppColors.visitedOrange.withValues(alpha: 0.30)
                            : AppColors.backgroundCard.withValues(alpha: 0.70),
                        borderColor: _tappedIsVisited
                            ? AppColors.visitedOrangeLight.withValues(
                                alpha: 0.5,
                              )
                            : Colors.white.withValues(alpha: 0.2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tappedIsVisited
                                  ? Icons.check_circle_rounded
                                  : Icons.remove_circle_outline_rounded,
                              size: 18,
                              color: _tappedIsVisited
                                  ? AppColors.visitedOrangeLight
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _tappedCountryMessage!,
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Polygon> _buildCountryPolygons(
    List<Country> countries,
    Set<String> visitedCodes,
  ) {
    final polygons = <Polygon>[];

    for (final country in countries) {
      final isVisited = visitedCodes.contains(country.isoCode);

      // Unvisited: medium-dark grey fill matching the screenshot style
      final fillColor = isVisited
          ? AppColors.visitedFill(0.85)
          : const Color(0xFF64748B).withValues(alpha: 0.55); // Slate 500
      final strokeColor = AppColors.backgroundNavy;
      final strokeWidth = isVisited ? 1.4 : 0.6;

      for (final ring in country.polygons) {
        polygons.add(
          Polygon(
            points: ring,
            color: fillColor,
            borderColor: strokeColor,
            borderStrokeWidth: strokeWidth,
          ),
        );
      }
    }

    return polygons;
  }

  Widget _buildLoadingState() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        borderRadius: BorderRadius.circular(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading world map...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load world map',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => ref.invalidate(worldCountriesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
