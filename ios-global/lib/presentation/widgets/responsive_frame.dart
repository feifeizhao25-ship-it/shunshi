import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/app_colors.dart';
import 'shell/desktop_shell.dart';

/// Retest N06: on tablets and wide windows the app is no longer stretched edge to edge (1440 px wide).
/// Content is held to a centred column with slightly larger type; the sides use the page colour.
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
    final frameWidth = 720.0; // UI_WIDE_SCREEN_AND_GESTURES §2: reading column <= 720 dp
    final used = width < frameWidth ? width : frameWidth;
    final typeScale = width >= 1100 ? 1.28 : 1.16;
    final background = AppColors.background(context);

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
