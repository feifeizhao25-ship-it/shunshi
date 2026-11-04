import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/app_colors.dart';
import 'shell/desktop_shell.dart';

/// 平板和大屏不再收成 480 宽的手机条。
/// 内容加宽、字号放大，两侧用页面同色，避免米色空带。
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child, this.routeListenable, this.currentPath});

  final Widget child;

  /// Rebuilds the frame when the route changes, and [currentPath] tells which route is showing. On a desktop-wide
  /// window the main shell (sidebar + content column) needs the real window width, so the narrow frame below must
  /// not clamp it (live check 2026-11-04: it clamped to 720/880dp, so the 900dp desktop breakpoint was never reached).
  final Listenable? routeListenable;
  final String Function()? currentPath;

  @override
  Widget build(BuildContext context) {
    if (routeListenable == null) return _frame(context);
    return ListenableBuilder(listenable: routeListenable!, builder: (context, _) => _frame(context));
  }

  Widget _frame(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.shortestSide < 600) return child;
    if (media.size.width >= DesktopShell.breakpoint && currentPath != null && DesktopShell.isShellPath(currentPath!())) return child;

    final width = media.size.width;
    final frameWidth = width >= 1100 ? 880.0 : 760.0;
    final used = width < frameWidth ? width : frameWidth;
    final typeScale = width >= 1100 ? 1.28 : 1.16;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? ShunShiColors.darkBackground : AppColors.background(context);

    return ColoredBox(
      color: background,
      child: Center(
        child: MediaQuery(
          data: media.copyWith(
            size: Size(used, media.size.height),
            textScaler: TextScaler.linear(media.textScaler.scale(1) * typeScale),
          ),
          child: SizedBox(
            width: used,
            height: media.size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
