import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

/// MainShell — 5 Tab 底部导航
///
/// 聊天 / 今日 / 节气 / 养生 / 我的
/// 参考: FINAL_UI_STRUCTURE.md
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

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final line = isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: background,
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: line, width: 0.5),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _tabs.map((tab) {
                      final isActive = currentPath == tab.path;
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
    final active = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;
    final inactive = isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive ? active : inactive,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? active : inactive,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: active,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
