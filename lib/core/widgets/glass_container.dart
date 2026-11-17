import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A modern glassmorphic container with backdrop blur, subtle borders, and gradient tint.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.blur = AppColors.glassBlur,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
    this.shadows,
    this.onTap,
  });

  /// Saturation boost applied to what is behind the glass (Apple-style
  /// "vibrancy"), so colors under the blur stay lively instead of going gray.
  static const List<double> _vibrancy = [
    1.35, -0.18, -0.03, 0, 0, //
    -0.09, 1.26, -0.03, 0, 0, //
    -0.09, -0.18, 1.41, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppColors.glassBorderRadius);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.06),
        // Soft top-lit sheen, like light catching the glass edge.
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
        borderRadius: effectiveRadius,
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      foregroundDecoration: _GlassEdge(
        radius: effectiveRadius,
        width: borderWidth,
        solid: borderColor,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    final frosted = ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: const ColorFilter.matrix(_vibrancy),
          inner: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.mirror,
          ),
        ),
        child: content,
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: frosted);
    }
    return frosted;
  }
}

/// Hairline edge that is bright at the top-left and bottom-right corners and
/// fades in between, the signature rim light of Apple's glass material.
/// A [solid] color replaces the gradient (used for tinted status surfaces).
class _GlassEdge extends Decoration {
  const _GlassEdge({required this.radius, required this.width, this.solid});

  final BorderRadius radius;
  final double width;
  final Color? solid;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _EdgePainter(this);
}

class _EdgePainter extends BoxPainter {
  _EdgePainter(this.d);

  final _GlassEdge d;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size;
    if (size == null) return;
    final rect = offset & size;
    final rrect = d.radius.toRRect(rect).deflate(d.width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = d.width;
    if (d.solid != null) {
      paint.color = d.solid!;
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.30),
        ],
        stops: const [0, 0.35, 0.65, 1],
      ).createShader(rect);
    }
    canvas.drawRRect(rrect, paint);
  }
}
