import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

/// MainShell — 5 Tab Bottom Navigation
///
/// Chat / Today / Solar / Wellness / Profile
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabDef(path: '/chat', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat'),
    _TabDef(path: '/today', icon: Icons.today_outlined, activeIcon: Icons.today, label: 'Today'),
    _TabDef(path: '/solar', icon: Icons.wb_sunny_outlined, activeIcon: Icons.wb_sunny, label: 'Solar'),
    _TabDef(path: '/wellness', icon: Icons.spa_outlined, activeIcon: Icons.spa, label: 'Wellness'),
    _TabDef(path: '/profile', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ShunShiColors.darkBackground,
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: ShunShiColors.darkBackground.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: ShunShiColors.borderGhost, width: 0.5),
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
  final VoidCallback onTap;

  const _NavTab({
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
                color: isActive ? ShunShiColors.primary : ShunShiColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? ShunShiColors.primary : ShunShiColors.textTertiary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: ShunShiColors.primary,
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
