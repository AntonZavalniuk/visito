import 'package:flutter/material.dart';

import 'core/layout.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/achievement_toast_host.dart';
import 'core/widgets/glass_container.dart';
import 'features/globe/globe_screen.dart';
import 'features/map/world_map_screen.dart';
import 'features/stats/stats_screen.dart';

/// Root application widget configuring dark glass theme and home shell.
class VisitoApp extends StatelessWidget {
  const VisitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visito',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkGlassTheme(),
      home: const AchievementToastHost(child: VisitoHomeShell()),
    );
  }

  ThemeData _buildDarkGlassTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentCyan,
        surface: AppColors.backgroundCard,
      ),
      fontFamily: null, // default system font
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Home shell holding the 4 primary screens and the floating glass navigation bar.
class VisitoHomeShell extends StatefulWidget {
  const VisitoHomeShell({super.key});

  @override
  State<VisitoHomeShell> createState() => _VisitoHomeShellState();
}

class _VisitoHomeShellState extends State<VisitoHomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WorldMapScreen(),
    GlobeScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBody: true,
      body: Stack(
        children: [
          // Screens Stack (preserves map & scroll states)
          IndexedStack(index: _currentIndex, children: _screens),

          // Floating Glass Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  kNavBarBottomMargin,
                ),
                // Hugs its content: a compact pill, not a full-width bar.
                child: Center(child: _buildFloatingGlassNavBar()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassNavBar() {
    return GlassContainer(
      padding: const EdgeInsets.all(3),
      borderRadius: BorderRadius.circular(26),
      blur: 28,
      // Dark tint keeps icons legible while the map still shows through.
      color: AppColors.backgroundNavy.withValues(alpha: 0.45),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavItem(
            index: 0,
            label: 'Map',
            icon: Icons.map_outlined,
            activeIcon: Icons.map_rounded,
          ),
          _buildNavItem(
            index: 1,
            label: 'Globe',
            icon: Icons.language_rounded,
            activeIcon: Icons.language_rounded,
          ),
          _buildNavItem(
            index: 2,
            label: 'Stats',
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          // Selected tab is a lighter glass capsule floating in the bar.
          color: isSelected
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 21,
              color: isSelected
                  ? AppColors.visitedAmberLight
                  : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.visitedAmberLight
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
