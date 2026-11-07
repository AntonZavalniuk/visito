import 'package:flutter/material.dart';

/// Design tokens and color palette for the Visito glassmorphism UI.
class AppColors {
  AppColors._();

  // Background gradients
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color backgroundCard = Color(0xFF1E293B); // Slate 800
  static const Color backgroundNavy = Color(0xFF0A0F1D);

  // Brand / Accents
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color accentPurple = Color(0xFF8B5CF6); // Violet 500
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500

  // Glass tokens
  static const double glassBlur = 16.0;
  static const double glassBorderRadius = 20.0;

  static Color glassBackground([double opacity = 0.12]) =>
      Colors.white.withValues(alpha: opacity);

  static Color glassBorder([double opacity = 0.20]) =>
      Colors.white.withValues(alpha: opacity);

  // Map polygon colors — visited = amber
  static const Color visitedAmber = Color(0xFFF4A900); // Amber
  static const Color visitedAmberLight = Color(0xFFFFC233); // Amber, lighter

  static Color visitedFill([double opacity = 0.55]) =>
      visitedAmber.withValues(alpha: opacity);

  static const Color visitedStroke = visitedAmberLight;
  static Color unvisitedStroke([double opacity = 0.35]) =>
      Colors.white.withValues(alpha: opacity);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
}
