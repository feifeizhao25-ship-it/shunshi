import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

/// MainShell — 5 Tab 底部导航
///
/// 聊天 / 今日 / 节气 / 养生 / 我的
/// V2: theme-aware nav bar, selected pill bg, raised center tab, animated switch
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabDef(path: '/chat', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '聊天'),
    _TabDef(path: '/today', icon: Icons.wb_sunny_outlined, activeIcon: Icons.wb_sunny, label: '今日'),
    _TabDef(path: '/solar', icon: Icons.eco_outlined, activeIcon: Icons.eco, label: '节气'),
    _TabDef(path: '/wellness', icon: Icons.spa_outlined, activeIcon: Icons.spa, label: '养生'),
    _TabDef(path: '/profile', icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  /// The center "today" tab index
  static const int _centerIndex = 1;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final navBg = isDark
        ? ShunShiColors.darkBackground.withValues(alpha: 0.9)
        : ShunShiColors.background.withValues(alpha: 0.85);
    final borderLine = isDark
        ? ShunShiColors.darkBorderGhost
        : ShunShiColors.borderGhost;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(color: borderLine, width: 0.5),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isActive = currentPath == tab.path;
                      final isCenter = index == _centerIndex;

                      if (isCenter) {
                        return _CenterNavTab(
                          icon: tab.icon,
                          activeIcon: tab.activeIcon,
                          label: tab.label,
                          isActive: isActive,
                          onTap: () => context.go(tab.path),
                        );
                      }

                      return _NavTab(
                        icon: tab.icon,
                        activeIcon: tab.activeIcon,
                        label: tab.label,
                        isActive: isActive,
                        isDark: isDark,
                        onTap: () => context.go(tab.path),
                      );
                    }).toList(),
                  ),
                ),
              ),
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

/// Regular nav tab with pill background on selection
class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = ShunShiColors.primary;
    final inactiveColor = isDark
        ? ShunShiColors.darkTextTertiary
        : ShunShiColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with optional pill background
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 14 : 0,
                vertical: isActive ? 4 : 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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

/// Center raised tab — large circle button with gradient
class _CenterNavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CenterNavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Raised circle button
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShunShiColors.primary,
                    ShunShiColors.primaryLight,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ShunShiColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Label below
          Transform.translate(
            offset: const Offset(0, -6),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? ShunShiColors.primary : ShunShiColors.textTertiary,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
