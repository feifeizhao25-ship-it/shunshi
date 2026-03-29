import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/colors.dart';

/// MainShell — 5 Tab bottom navigation container
///
/// Driven by GoRouter ShellRoute. child is the current route page.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabDef(
      path: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _TabDef(
      path: '/companion',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Companion',
    ),
    _TabDef(
      path: '/seasons',
      icon: Icons.eco_outlined,
      activeIcon: Icons.eco,
      label: 'Seasons',
    ),
    _TabDef(
      path: '/library',
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: 'Library',
    ),
    _TabDef(
      path: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? SeasonsColors.darkSurface
              : SeasonsColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SeasonsColors.textTertiaryDark
                  : SeasonsColors.textTertiaryLight,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isActive = currentPath == tab.path ||
                    (tab.path != '/home' &&
                        currentPath.startsWith(tab.path));
                return _NavTab(
                  icon: tab.icon,
                  activeIcon: tab.activeIcon,
                  label: tab.label,
                  isActive: isActive,
                  activeColor: SeasonsColors.primary,
                  inactiveColor: isDark
                      ? SeasonsColors.textTertiaryDark
                      : SeasonsColors.textTertiaryLight,
                  isCenter: index == 1,
                  onTap: () => context.go(tab.path),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabDef({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Minimal nav tab: 64dp height, 24dp icon, 12sp label
/// Color fade 200ms, no scale, no bounce.
/// Center tab (Companion) slightly larger icon for emphasis.
class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    this.isCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCenter ? 26.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: iconSize,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
