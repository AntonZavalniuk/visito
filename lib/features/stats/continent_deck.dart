import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/country.dart';
import '../../providers/countries_provider.dart';
import '../globe/globe_painter.dart';

/// Geographic window (degrees) used to draw each continent's silhouette.
/// Windows crop overseas territories and anti-meridian leftovers.
class _Window {
  const _Window(this.minLng, this.maxLng, this.minLat, this.maxLat);
  final double minLng, maxLng, minLat, maxLat;
}

const Map<Continent, _Window> _windows = {
  Continent.africa: _Window(-20, 53, -36, 38),
  Continent.asia: _Window(25, 150, -11, 78),
  Continent.europe: _Window(-15, 50, 34, 72),
  Continent.northAmerica: _Window(-170, -50, 5, 84),
  Continent.southAmerica: _Window(-82, -34, -56, 13),
  Continent.oceania: _Window(110, 180, -48, -1),
  Continent.antarctica: _Window(-180, 180, -90, -60),
};

/// Swipeable "deck" of statistic cards in the style of the Been app:
/// In Total (globe backdrop), Continents, then one card per continent
/// (continent silhouette backdrop).
class ContinentDeck extends StatefulWidget {
  const ContinentDeck({
    super.key,
    required this.overall,
    required this.continents,
    required this.countries,
    required this.visitedCodes,
  });

  final WorldStats overall;
  final List<ContinentStats> continents;
  final List<Country> countries;
  final Set<String> visitedCodes;

  @override
  State<ContinentDeck> createState() => _ContinentDeckState();
}

class _ContinentDeckState extends State<ContinentDeck>
    with SingleTickerProviderStateMixin {
  static const double _cardHeight = 220;
  static const double _stackPeek = 22;

  /// Index of the card currently on top of the deck.
  int _top = 0;

  /// Horizontal drag offset of the top card (logical pixels).
  double _dx = 0;

  late final AnimationController _anim = AnimationController(vsync: this);
  Animation<double>? _dxTween;
  VoidCallback? _onAnimDone;

  List<GlobeRing>? _rings;
  List<Country>? _ringsSource;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      final tween = _dxTween;
      if (tween != null) setState(() => _dx = tween.value);
    });
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final done = _onAnimDone;
        _onAnimDone = null;
        done?.call();
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  int _cardCount(BuildContext context) =>
      2 + widget.continents.length + (_hasAntarctica ? 1 : 0);

  void _animateTo(
    double target,
    Duration duration,
    Curve curve, {
    VoidCallback? onDone,
  }) {
    _onAnimDone = onDone;
    _dxTween = Tween<double>(
      begin: _dx,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: curve));
    _anim
      ..duration = duration
      ..forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_anim.isAnimating) return;
    setState(() => _dx += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d, double width, int count) {
    if (_anim.isAnimating) return;
    final velocity = d.primaryVelocity ?? 0;
    final dismiss = _dx.abs() > width * 0.28 || velocity.abs() > 800;
    if (count <= 1 || !dismiss) {
      _animateTo(0, const Duration(milliseconds: 220), Curves.easeOutBack);
      return;
    }
    // Fling the card off-screen in the swipe direction, then send it to the
    // back of the deck.
    final direction = (velocity.abs() > 800 ? velocity : _dx).sign;
    _animateTo(
      direction * width * 1.4,
      const Duration(milliseconds: 240),
      Curves.easeIn,
      onDone: () => setState(() {
        _top = (_top + 1) % count;
        _dx = 0;
        _dxTween = null;
      }),
    );
  }

  List<GlobeRing> get _globeRings {
    if (!identical(_ringsSource, widget.countries)) {
      _ringsSource = widget.countries;
      _rings = GlobeRing.fromCountries(widget.countries);
    }
    return _rings!;
  }

  /// Continents (of 7, including Antarctica) with at least one visited
  /// country, official or not.
  int get _visitedContinents {
    final set = <Continent>{};
    for (final c in widget.countries) {
      final continent = c.continent;
      if (continent != null && widget.visitedCodes.contains(c.isoCode)) {
        set.add(continent);
      }
    }
    return set.length;
  }

  List<Country> get _antarcticaEntries => widget.countries
      .where((c) => c.continent == Continent.antarctica)
      .toList();

  bool get _hasAntarctica => _antarcticaEntries.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final count = _cardCount(context);
    final top = _top % count;
    final next = (top + 1) % count;

    return Column(
      children: [
        SizedBox(
          height: _cardHeight + _stackPeek,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // 0..1: how far the top card has been pulled away.
              final progress = (_dx.abs() / (width * 0.5)).clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cards "underneath" the current one, peeking out on top.
                  _stackLayer(inset: 28, top: 0, alpha: 0.35),
                  _stackLayer(inset: 14, top: 10, alpha: 0.6),

                  // Next card: grows into place as the top card leaves.
                  if (count > 1)
                    Positioned(
                      top: _stackPeek,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      // Scaled around the center and fully covered by the top
                      // card at rest, so nothing pokes out above the stack.
                      child: Transform.scale(
                        scale: 0.94 + 0.06 * progress,
                        child: _buildPage(next),
                      ),
                    ),

                  // Top card: follows the finger, tilts and flies away.
                  Positioned(
                    top: _stackPeek,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      key: const ValueKey('deck_gesture'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: (d) => _onDragEnd(d, width, count),
                      child: Transform.translate(
                        offset: Offset(_dx, _dx.abs() * 0.12),
                        child: Transform.rotate(
                          angle: (_dx / width) * 0.4,
                          child: _buildPage(top),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: top == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: top == i
                      ? AppColors.visitedAmber
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stackLayer({
    required double inset,
    required double top,
    required double alpha,
  }) {
    // Opaque tones between the screen background and the card color, so the
    // layers read as cards lying underneath the top one.
    final color = Color.lerp(
      AppColors.backgroundDark,
      AppColors.backgroundCard,
      alpha,
    )!;
    return Positioned(
      top: top,
      left: inset,
      right: inset,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _totalCard();
      case 1:
        return _simpleCard(
          key: const ValueKey('deck_continents'),
          title: 'Continents',
          value: '$_visitedContinents',
          total: '7',
          subtitle: 'Including Antarctica',
          backdrop: _globeBackdrop(lat: 15, lng: -50),
        );
      default:
        if (index - 2 >= widget.continents.length) return _antarcticaCard();
        final cs = widget.continents[index - 2];
        return _simpleCard(
          key: ValueKey('continent_${cs.continent.name}'),
          title: cs.continent.label,
          value: '${cs.visited}',
          total: '${cs.total}',
          subtitle: 'Countries recognized by the UN',
          backdrop: RepaintBoundary(
            child: CustomPaint(
              painter: _SilhouettePainter(
                countries: widget.countries,
                continent: cs.continent,
                color: Colors.white.withValues(alpha: 0.04),
                outline: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
        );
    }
  }

  /// Antarctica has no UN member countries, so its card counts the
  /// territories listed under it instead.
  Widget _antarcticaCard() {
    final entries = _antarcticaEntries;
    final visited = entries
        .where((c) => widget.visitedCodes.contains(c.isoCode))
        .length;
    return _simpleCard(
      key: const ValueKey('continent_antarctica'),
      title: Continent.antarctica.label,
      value: '$visited',
      total: '${entries.length}',
      subtitle: 'No UN member countries',
      backdrop: RepaintBoundary(
        child: CustomPaint(
          painter: _SilhouettePainter(
            countries: widget.countries,
            continent: Continent.antarctica,
            color: Colors.white.withValues(alpha: 0.04),
            outline: Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
    );
  }

  /// Faded globe filling the card height (slightly cropped by the card).
  Widget _globeBackdrop({required double lat, required double lng}) {
    return Opacity(
      opacity: 0.16,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CardGlobePainter(
            rings: _globeRings,
            visited: widget.visitedCodes,
            centerLat: lat,
            centerLng: lng,
          ),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.backgroundCard,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _cardTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );

  Widget _subtitle(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _simpleCard({
    required Key key,
    required String title,
    required String value,
    required String total,
    required String subtitle,
    required Widget? backdrop,
  }) {
    return Container(
      key: key,
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (backdrop != null) Positioned.fill(child: backdrop),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTitle(title),
                Expanded(child: Center(child: _bigNumber(value, ' / $total'))),
                Center(child: _subtitle(subtitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigNumber(String value, String suffix) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          text: value,
          style: const TextStyle(
            color: AppColors.visitedAmber,
            fontSize: 72,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
          children: [
            TextSpan(
              text: suffix,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalCard() {
    final stats = widget.overall;
    final percent = (stats.progress * 100).round();

    return Container(
      key: const ValueKey('deck_total'),
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _globeBackdrop(lat: 20, lng: 20)),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTitle('In Total'),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('$percent', 'World', suffix: '%'),
                      _statColumn('${stats.visitedCount}', 'Countries'),
                    ],
                  ),
                ),
                Center(
                  child: _subtitle('Out of ${stats.totalCount} UN Countries'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label, {String? suffix}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.visitedAmber,
              fontSize: 54,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
            children: [
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Draws a faint silhouette of one continent's countries, fitted into the
/// available box with an aspect-preserving equirectangular projection.
class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({
    required this.countries,
    required this.continent,
    required this.color,
    required this.outline,
  });

  final List<Country> countries;
  final Continent continent;
  final Color color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final polar = continent == Continent.antarctica;
    final w = _windows[continent]!;
    final midLat = (w.minLat + w.maxLat) / 2 * math.pi / 180;
    final cosMid = math.cos(midLat);

    // Antarctica is drawn with a south-polar azimuthal projection (as seen
    // from below), everything else with an equirectangular window.
    const polarRadiusDeg = 32.0; // 90 - 58 degrees of latitude
    final spanX = polar ? 2 * polarRadiusDeg : (w.maxLng - w.minLng) * cosMid;
    final spanY = polar ? 2 * polarRadiusDeg : w.maxLat - w.minLat;
    // Fill the whole card height; a wide shape may be cropped at the sides.
    final scale = size.height / spanY * 1.1;
    final offX = (size.width - spanX * scale) / 2;
    final offY = (size.height - spanY * scale) / 2;

    Offset project(double lat, double lng) {
      if (polar) {
        final rho = lat + 90; // degrees from the south pole
        final theta = lng * math.pi / 180;
        return Offset(
          offX + (polarRadiusDeg + rho * math.sin(theta)) * scale,
          offY + (polarRadiusDeg - rho * math.cos(theta)) * scale,
        );
      }
      return Offset(
        offX + (lng - w.minLng) * cosMid * scale,
        offY + (w.maxLat - lat) * scale,
      );
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = outline;

    final path = Path();
    for (final country in countries) {
      if (country.continent != continent) continue;
      for (final ring in country.polygons) {
        for (var i = 0; i < ring.length; i++) {
          final p = ring[i];
          final o = project(p.latitude, p.longitude);
          if (i == 0) {
            path.moveTo(o.dx, o.dy);
          } else {
            path.lineTo(o.dx, o.dy);
          }
        }
        path.close();
      }
    }
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) =>
      !identical(old.countries, countries) ||
      old.continent != continent ||
      old.color != color;
}

/// Static globe used as the faded backdrop of the "In Total" and
/// "Continents" cards. It spans the full card height, so it is slightly
/// cropped at the top and bottom.
class _CardGlobePainter extends CustomPainter {
  _CardGlobePainter({
    required this.rings,
    required this.visited,
    required this.centerLat,
    required this.centerLng,
  });

  final List<GlobeRing> rings;
  final Set<String> visited;
  final double centerLat; // degrees
  final double centerLng; // degrees

  @override
  void paint(Canvas canvas, Size size) {
    final view = GlobeView(
      centerLat: centerLat * math.pi / 180,
      centerLng: centerLng * math.pi / 180,
      radius: size.height * 0.62,
      center: Offset(size.width / 2, size.height / 2),
    );
    GlobePainter(
      rings: rings,
      visited: visited,
      view: view,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_CardGlobePainter old) =>
      !identical(old.rings, rings) ||
      old.visited != visited ||
      old.centerLat != centerLat ||
      old.centerLng != centerLng;
}
