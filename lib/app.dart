import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/widgets/glass_container.dart';
import 'features/countries/countries_list_screen.dart';
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
      home: const VisitoHomeShell(),
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

/// Home shell holding the 3 primary screens and the floating glass navigation bar.
class VisitoHomeShell extends StatefulWidget {
  const VisitoHomeShell({super.key});

  @override
  State<VisitoHomeShell> createState() => _VisitoHomeShellState();
}

class _VisitoHomeShellState extends State<VisitoHomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WorldMapScreen(),
    CountriesListScreen(),
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
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Glass Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _buildFloatingGlassNavBar(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassNavBar() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: BorderRadius.circular(32),
      blur: 24,
      // Solid dark background — fully opaque so items are always visible
      color: AppColors.backgroundNavy.withValues(alpha: 0.95),
      borderColor: Colors.white.withValues(alpha: 0.14),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            label: 'Map',
            icon: Icons.map_outlined,
            activeIcon: Icons.map_rounded,
          ),
          _buildNavItem(
            index: 1,
            label: 'Countries',
            icon: Icons.format_list_bulleted_outlined,
            activeIcon: Icons.format_list_bulleted_rounded,
          ),
          _buildNavItem(
            index: 2,
            label: 'Stats',
            icon: Icons.pie_chart_outline_rounded,
            activeIcon: Icons.pie_chart_rounded,
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
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  width: 1,
                )
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              // Inactive items: bright white so they're visible on dark bg
              color: isSelected
                  ? AppColors.primaryLight
                  : Colors.white.withValues(alpha: 0.65),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
