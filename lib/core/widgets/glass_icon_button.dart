import 'package:flutter/material.dart';

import 'glass_container.dart';

/// An animated frosted glass button with micro-interaction scaling on press.
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 46.0,
    this.iconSize = 22.0,
    this.iconColor,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget button = AnimatedScale(
      scale: _pressed ? 0.90 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: GlassContainer(
          width: widget.size,
          height: widget.size,
          borderRadius: BorderRadius.circular(widget.size / 2),
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
