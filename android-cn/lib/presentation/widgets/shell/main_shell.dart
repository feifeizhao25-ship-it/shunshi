import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// MainShell — 5 Tab 底部导航容器
///
/// 由 GoRouter ShellRoute 驱动，使用 Row + GestureDetector + AnimatedContainer
/// 实现 emoji 风格底部导航栏。
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  // ── 主色 ──────────────────────────────────────────────
  static const _primaryColor = Color(0xFF8B9E7E);
  static const _inactiveColor = Color(0xFF999999);
  static const _borderColor = Color(0xFFE0E0E0);

  // ── 5个Tab定义 ──────────────────────────────────────────
  static const _tabs = [
    _TabDef(path: '/companion', emoji: '💬', label: '聊天'),
    _TabDef(path: '/home', emoji: '📅', label: '今日'),
    _TabDef(path: '/seasons', emoji: '🌞', label: '节气'),
    _TabDef(path: '/library', emoji: '📚', label: '养生'),
    _TabDef(path: '/profile', emoji: '👤', label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return PopScope(
      canPop: false, // Shell内按返回键不退出app
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F6),
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: _borderColor,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: _tabs.map((tab) {
                  final isActive = currentPath == tab.path ||
                      (tab.path != '/home' &&
                          currentPath.startsWith(tab.path));
                  return _NavTab(
                    emoji: tab.emoji,
                    label: tab.label,
                    isActive: isActive,
                    activeColor: _primaryColor,
                    inactiveColor: _inactiveColor,
                    onTap: () => context.go(tab.path),
                  );
                }).toList(),
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
  final String emoji;
  final String label;
  const _TabDef({
    required this.path,
    required this.emoji,
    required this.label,
  });
}

/// Emoji 风格导航 Tab
///
/// - 选中时文字变为主色 + 加粗，字号 12→13
/// - 选中时上方显示主色小圆点（直径6）
/// - 未选中 emoji 灰色，文字灰色
/// - 颜色/字号过渡动画 200ms
class _NavTab extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavTab({
    required this.emoji,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    final fontSize = isActive ? 13.0 : 12.0;
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 选中指示圆点
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isActive ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            // Emoji
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 20,
                color: color,
              ),
              child: Text(emoji),
            ),
            const SizedBox(height: 2),
            // 标签文字
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
