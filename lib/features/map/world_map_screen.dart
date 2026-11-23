import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_icon_button.dart';
import '../countries/countries_list_screen.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';
import '../../utils/geo_utils.dart';

/// Interactive world map screen with dark background, polygon overlays,
/// and modern frosted glass controls. Marking countries is done in the
/// countries list; the map itself is view-only (pan and zoom).
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  final MapController _mapController = MapController();

  // Visible part of the world (Mercator-friendly: no polar caps).
  static const double _northLat = 84;
  static const double _southLat = -58;
  static const double _maxZoomLevel = 9.0;

  // Shifts the fitted view horizontally: positive moves the map to the left.
  static const double _centerLngOffset = 0;

  double _fitZoom = 1.5;
  LatLng _fitCenter = const LatLng(20, 0);
  bool _zoomedIn = false;
  double _zoom = 0;

  static double _mercY(double lat) =>
      math.log(math.tan(math.pi / 4 + lat * math.pi / 360));

  /// Computes zoom/center at which the whole world fits the viewport.
  void _computeFit(Size size) {
    const tile = 256.0;
    final yN = _mercY(_northLat);
    final yS = _mercY(_southLat);
    final zoomW = math.log(size.width / tile) / math.ln2;
    final zoomH =
        math.log(size.height * 2 * math.pi / (tile * (yN - yS))) / math.ln2;
    _fitZoom = math.min(zoomW, zoomH);
    final yMid = (yN + yS) / 2;
    final latMid =
        (2 * math.atan(math.exp(yMid)) - math.pi / 2) * 180 / math.pi;
    _fitCenter = LatLng(latMid, _centerLngOffset);
  }

  /// After the window is resized (e.g. entering full screen) a map that was
  /// showing the whole world must be re-fitted, otherwise it keeps the zoom of
  /// the previous size.
  void _refitAfterResize(double previousFit) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final zoom = _mapController.camera.zoom;
        final wasFitted = zoom <= previousFit + 0.01;
        if (wasFitted || zoom < _fitZoom) {
          _mapController.move(_fitCenter, _fitZoom);
        }
      } catch (_) {
        // Controller not attached yet: the initial camera is already correct.
      }
    });
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final zoomed = camera.zoom > _fitZoom + 0.01;
    // Quantized so tiny-country markers update without rebuilding every frame.
    final zoom = (camera.zoom * 4).round() / 4;
    if (zoomed != _zoomedIn || zoom != _zoom) {
      setState(() {
        _zoomedIn = zoomed;
        _zoom = zoom;
      });
    }
  }

  /// Countries too small to see or hit at map scale (Vatican City, Monaco).
  static bool _isTiny(Country c) =>
      math.max(c.maxLat - c.minLat, c.maxLng - c.minLng) < 0.5;

  /// Marker dot radius (px); a country smaller than this on screen gets one.
  static const double _markerRadius = 5;

  /// Whether [c]'s polygon is currently too small on screen to see.
  bool _isTinyOnScreen(Country c) {
    final span = math.max(c.maxLat - c.minLat, c.maxLng - c.minLng);
    final pixels = span / 360 * 256 * math.pow(2, _zoom);
    return pixels < _markerRadius * 2;
  }

  /// Fixed-size dots for visited tiny countries, shown only while their
  /// polygons are too small to see (they vanish once zoomed in far enough).
  List<CircleMarker> _buildTinyMarkers(
    List<Country> countries,
    Set<String> painted,
  ) {
    return [
      for (final c in countries)
        if (_isTiny(c) && _isTinyOnScreen(c) && painted.contains(c.isoCode))
          CircleMarker(
            point: c.center,
            radius: _markerRadius,
            color: AppColors.visitedFill(0.95),
            borderColor: AppColors.backgroundNavy,
            borderStrokeWidth: 1.4,
          ),
    ];
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(_fitZoom, _maxZoomLevel),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(_fitZoom, _maxZoomLevel),
    );
    if (_mapController.camera.zoom <= _fitZoom + 0.01) {
      _mapController.move(_fitCenter, _fitZoom);
    }
  }

  void _resetView() {
    _mapController.move(_fitCenter, _fitZoom);
  }

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(worldCountriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // 1. Map Layer — solid dark background, no tiles
          countriesAsync.when(
            loading: () => _buildLoadingState(),
            error: (err, stack) => _buildErrorState(err),
            data: (allCountries) {
              // Antarctica is shown on the Globe only.
              final countries = allCountries
                  .where((c) => c.continent != Continent.antarctica)
                  .toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final previousFit = _fitZoom;
                  _computeFit(constraints.biggest);
                  if ((_fitZoom - previousFit).abs() > 1e-6) {
                    _refitAfterResize(previousFit);
                  }
                  return FlutterMap(
                    key: ValueKey(
                      '${constraints.maxWidth.round()}x${constraints.maxHeight.round()}',
                    ),
                    mapController: _mapController,
                    options: MapOptions(
                      crs: const _SingleWorldMercator(),
                      initialCenter: _fitCenter,
                      initialZoom: _fitZoom,
                      minZoom: _fitZoom,
                      maxZoom: _maxZoomLevel,
                      backgroundColor: AppColors.backgroundDark,
                      cameraConstraint: CameraConstraint.containCenter(
                        bounds: LatLngBounds(
                          const LatLng(_southLat, -180),
                          const LatLng(_northLat, 180),
                        ),
                      ),
                      onPositionChanged: _onPositionChanged,
                      // Whole world is shown static; panning only after zoom-in.
                      interactionOptions: InteractionOptions(
                        flags: _zoomedIn
                            ? InteractiveFlag.all & ~InteractiveFlag.rotate
                            : InteractiveFlag.pinchZoom |
                                  InteractiveFlag.scrollWheelZoom |
                                  InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      PolygonLayer(
                        // Never repeat the world horizontally on wide screens.
                        drawInSingleWorld: true,
                        polygons: _buildCountryPolygons(
                          countries,
                          ref.watch(paintedCodesProvider),
                        ),
                      ),
                      CircleLayer(
                        circles: _buildTinyMarkers(
                          countries,
                          ref.watch(paintedCodesProvider),
                        ),
                      ),
                    ],
                  );
                },
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
                  children: [
                    // Countries list button
                    GlassIconButton(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Countries',
                      onTap: () => showCountriesSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Right-side Glass Zoom & Controls
          Positioned(
            right: 16,
            bottom: navBarClearance(context),
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
            holePointsList: [
              for (final hole in country.holes)
                if (isPointInPolygon(hole.first, ring)) hole,
            ],
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
              onPressed: () => ref.invalidate(rawCountriesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Web-mercator CRS that does not repeat the world horizontally, so wide
/// (e.g. full-screen) windows show a single world instead of copies.
class _SingleWorldMercator extends Epsg3857 {
  const _SingleWorldMercator();

  @override
  bool get replicatesWorldLongitude => false;
}
