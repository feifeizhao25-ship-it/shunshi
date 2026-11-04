import 'package:flutter/material.dart';

/// One entry of the desktop sidebar.
class DesktopNavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const DesktopNavItem({required this.path, required this.icon, required this.activeIcon, required this.label});
}

/// Desktop / wide-web layout for the main shell (UI test 2026-11-04: at 1440px the phone layout was just stretched,
/// with lines ~1100px long). From [breakpoint] up the bottom tab bar becomes a left sidebar and the page sits in a
/// centred column no wider than [contentMaxWidth] (a comfortable ~75-character line for body text).
/// Phones and narrow windows are untouched.
class DesktopShell extends StatelessWidget {
  static const double breakpoint = 900;
  static const double contentMaxWidth = 960;
  static const double sidebarWidth = 232;

  final List<DesktopNavItem> items;
  final String currentPath;
  final ValueChanged<String> onSelect;
  final Color background;
  final Color line;
  final Color active;
  final Color inactive;
  final String? title;
  final Widget child;

  const DesktopShell({
    super.key,
    required this.items,
    required this.currentPath,
    required this.onSelect,
    required this.background,
    required this.line,
    required this.active,
    required this.inactive,
    required this.child,
    this.title,
  });

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(color: background, border: Border(right: BorderSide(color: line, width: 0.5))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          child: Text(title!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: active)),
                        ),
                      for (final item in items) _SideTab(item: item, selected: currentPath == item.path || currentPath.startsWith('${item.path}/'), active: active, inactive: inactive, onTap: () => onSelect(item.path)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: contentMaxWidth), child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  final DesktopNavItem item;
  final bool selected;
  final Color active;
  final Color inactive;
  final VoidCallback onTap;
  const _SideTab({required this.item, required this.selected, required this.active, required this.inactive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? active : inactive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? active.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(item.label, style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: color))),
            ]),
          ),
        ),
      ),
    );
  }
}
