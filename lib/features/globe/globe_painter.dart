import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/country.dart';

/// Pre-computed trigonometry for one polygon ring so that repainting while
/// the globe rotates does not need to recompute sin/cos of every vertex.
class GlobeRing {
  GlobeRing({
    required this.isoCode,
    required this.sinLat,
    required this.cosLat,
    required this.lng,
    required this.centerLat,
    required this.centerLng,
    required this.angularRadius,
  });

  final String isoCode;
  final Float64List sinLat;
  final Float64List cosLat;
  final Float64List lng;

  /// Bounding-cap used to cheaply skip rings on the far side of the globe.
  final double centerLat;
  final double centerLng;
  final double angularRadius;

  int get length => lng.length;

  static List<GlobeRing> fromCountries(List<Country> countries) {
    final rings = <GlobeRing>[];
    for (final country in countries) {
      for (final ring in country.polygons) {
        if (ring.length < 3) continue;
        final n = ring.length;
        final sinLat = Float64List(n);
        final cosLat = Float64List(n);
        final lng = Float64List(n);
        double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
        for (var i = 0; i < n; i++) {
          final p = ring[i];
          final phi = p.latitude * math.pi / 180;
          sinLat[i] = math.sin(phi);
          cosLat[i] = math.cos(phi);
          lng[i] = p.longitude * math.pi / 180;
          minLat = math.min(minLat, p.latitude);
          maxLat = math.max(maxLat, p.latitude);
          minLng = math.min(minLng, p.longitude);
          maxLng = math.max(maxLng, p.longitude);
        }
        final cLat = (minLat + maxLat) / 2;
        final cLng = (minLng + maxLng) / 2;
        // Conservative radius: farthest bbox corner from the center (radians).
        final dLat = (maxLat - minLat) / 2;
        final dLng = (maxLng - minLng) / 2 * math.cos(cLat * math.pi / 180);
        final radius = math.sqrt(dLat * dLat + dLng * dLng) * math.pi / 180;
        rings.add(
          GlobeRing(
            isoCode: country.isoCode,
            sinLat: sinLat,
            cosLat: cosLat,
            lng: lng,
            centerLat: cLat * math.pi / 180,
            centerLng: cLng * math.pi / 180,
            angularRadius: math.min(math.pi, radius * 1.5 + 0.05),
          ),
        );
      }
    }
    return rings;
  }
}

/// Orthographic projection helper shared by the painter and hit-testing.
class GlobeView {
  const GlobeView({
    required this.centerLat,
    required this.centerLng,
    required this.radius,
    required this.center,
  });

  /// View center in radians.
  final double centerLat;
  final double centerLng;

  /// Globe radius in logical pixels.
  final double radius;
  final Offset center;

  /// Inverse projection: screen point -> (lat, lng) in degrees, or null if the
  /// point is outside of the globe disc.
  ({double lat, double lng})? unproject(Offset p) {
    final x = (p.dx - center.dx) / radius;
    final y = -(p.dy - center.dy) / radius;
    final rho = math.sqrt(x * x + y * y);
    if (rho > 1) return null;
    if (rho == 0) {
      return (lat: centerLat * 180 / math.pi, lng: centerLng * 180 / math.pi);
    }
    final c = math.asin(rho);
    final sinC = math.sin(c);
    final cosC = math.cos(c);
    final lat = math.asin(
      cosC * math.sin(centerLat) + y * sinC * math.cos(centerLat) / rho,
    );
    final lng =
        centerLng +
        math.atan2(
          x * sinC,
          rho * math.cos(centerLat) * cosC - y * math.sin(centerLat) * sinC,
        );
    var lngDeg = lng * 180 / math.pi;
    lngDeg = ((lngDeg + 180) % 360 + 360) % 360 - 180;
    return (lat: lat * 180 / math.pi, lng: lngDeg);
  }
}

/// Shared GPU resources for the textured (relief) globe.
class GlobeRelief {
  GlobeRelief({required this.program, required this.texture});

  final ui.FragmentProgram program;
  final ui.Image texture;
}

/// Paints a shaded 3D globe with countries (visited ones highlighted).
class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.rings,
    required this.visited,
    required this.view,
    this.selectedIso,
    this.relief,
  });

  /// When non-null the land is drawn from a shaded-relief texture and
  /// countries are overlaid as translucent tints.
  final GlobeRelief? relief;

  final List<GlobeRing> rings;
  final Set<String> visited;
  final GlobeView view;
  final String? selectedIso;

  @override
  void paint(Canvas canvas, Size size) {
    final c = view.center;
    final r = view.radius;
    final disc = Rect.fromCircle(center: c, radius: r);

    // Atmosphere glow.
    canvas.drawCircle(
      c,
      r * 1.08,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r * 1.08,
          [
            AppColors.accentCyan.withValues(alpha: 0.28),
            AppColors.accentCyan.withValues(alpha: 0.0),
          ],
          const [0.86, 1.0],
        ),
    );

    // Ocean sphere with light coming from the upper left.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-r * 0.35, -r * 0.4),
          r * 1.5,
          [const Color(0xFF16284A), const Color(0xFF0A1428)],
        ),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(disc));

    final relief = this.relief;
    if (relief != null) {
      final shader = relief.program.fragmentShader()
        ..setFloat(0, c.dx)
        ..setFloat(1, c.dy)
        ..setFloat(2, r)
        ..setFloat(3, view.centerLat)
        ..setFloat(4, view.centerLng)
        ..setFloat(5, 0)
        ..setImageSampler(0, relief.texture);
      canvas.drawCircle(c, r, Paint()..shader = shader);
    }
    final visitedPath = Path();

    final sinL0 = math.sin(view.centerLat);
    final cosL0 = math.cos(view.centerLat);

    final fillOther = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF64748B).withValues(alpha: 0.85);
    final fillVisited = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.visitedAmber;
    final fillSelected = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.visitedAmberLight;
    final strokeOther = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.backgroundNavy;
    final strokeVisited = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.backgroundNavy;

    for (final ring in rings) {
      // Cheap culling: skip rings whose bounding cap is fully on the far side.
      final cosDist =
          math.sin(view.centerLat) * math.sin(ring.centerLat) +
          cosL0 *
              math.cos(ring.centerLat) *
              math.cos(ring.centerLng - view.centerLng);
      final dist = math.acos(cosDist.clamp(-1.0, 1.0));
      if (dist - ring.angularRadius > math.pi / 2) continue;

      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final dLng = ring.lng[i] - view.centerLng;
        final cosLat = ring.cosLat[i];
        final x = cosLat * math.sin(dLng);
        final y = cosL0 * ring.sinLat[i] - sinL0 * cosLat * math.cos(dLng);
        final z = sinL0 * ring.sinLat[i] + cosL0 * cosLat * math.cos(dLng);

        var px = x;
        var py = y;
        if (z < 0) {
          // Far side: squash the point onto the horizon so polygons that
          // straddle the limb are still closed correctly.
          final len = math.sqrt(x * x + y * y);
          if (len > 1e-9) {
            px = x / len;
            py = y / len;
          }
        }
        final sx = c.dx + px * r;
        final sy = c.dy - py * r;
        if (i == 0) {
          path.moveTo(sx, sy);
        } else {
          path.lineTo(sx, sy);
        }
      }
      path.close();

      final isVisited = visited.contains(ring.isoCode);
      final isSelected = ring.isoCode == selectedIso;
      // With the relief texture, only visited countries get a tint so the
      // terrain stays visible everywhere else.
      if (relief == null) {
        canvas.drawPath(
          path,
          isSelected ? fillSelected : (isVisited ? fillVisited : fillOther),
        );
        canvas.drawPath(path, isVisited ? strokeVisited : strokeOther);
      } else if (isVisited || isSelected) {
        visitedPath.addPath(path, Offset.zero);
      } else {
        canvas.drawPath(path, strokeOther);
      }
    }

    if (relief != null && visitedPath.getBounds().isEmpty == false) {
      // Opaque saturated fill, then modulate it by the terrain shading so
      // mountains stay visible on visited countries too.
      canvas.saveLayer(disc, Paint());
      canvas.drawPath(visitedPath, fillVisited);
      final shade = relief.program.fragmentShader()
        ..setFloat(0, c.dx)
        ..setFloat(1, c.dy)
        ..setFloat(2, r)
        ..setFloat(3, view.centerLat)
        ..setFloat(4, view.centerLng)
        ..setFloat(5, 1)
        ..setImageSampler(0, relief.texture);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = shade
          ..blendMode = BlendMode.modulate,
      );
      canvas.restore();
      canvas.drawPath(visitedPath, strokeVisited);
    }

    // Spherical shading (terminator) for a 3D feel.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-r * 0.3, -r * 0.35),
          r * 1.45,
          [
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
          const [0.0, 0.45, 1.0],
        ),
    );
    canvas.restore();

    // Rim light.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.accentCyan.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(GlobePainter old) =>
      old.view.centerLat != view.centerLat ||
      old.view.centerLng != view.centerLng ||
      old.view.radius != view.radius ||
      old.view.center != view.center ||
      old.visited != visited ||
      old.selectedIso != selectedIso ||
      !identical(old.relief, relief) ||
      !identical(old.rings, rings);
}
