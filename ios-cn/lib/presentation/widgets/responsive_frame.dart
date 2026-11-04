import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../design_system/theme.dart';
import '../../design_system/app_colors.dart';
import 'shell/desktop_shell.dart';

/// 平板和大屏不再收成 480 宽的手机条。
/// 内容加宽、字号放大，两侧用页面同色，避免米色空带。
class ResponsiveFrame extends StatefulWidget {
  const ResponsiveFrame({super.key, required this.child, this.routeListenable, this.currentPath});

  final Widget child;

  /// Rebuilds the frame when the route changes, and [currentPath] tells which route is showing. On a desktop-wide
  /// window the main shell (sidebar + content column) needs the real window width, so the narrow frame below must
  /// not clamp it (live check 2026-11-04: it clamped to 720/880dp, so the 900dp desktop breakpoint was never reached).
  final Listenable? routeListenable;
  final String Function()? currentPath;

  @override
  State<ResponsiveFrame> createState() => _ResponsiveFrameState();
}

class _ResponsiveFrameState extends State<ResponsiveFrame> {
  @override
  void initState() {
    super.initState();
    widget.routeListenable?.addListener(_onRoute);
  }

  @override
  void didUpdateWidget(ResponsiveFrame old) {
    super.didUpdateWidget(old);
    if (old.routeListenable != widget.routeListenable) {
      old.routeListenable?.removeListener(_onRoute);
      widget.routeListenable?.addListener(_onRoute);
    }
  }

  @override
  void dispose() {
    widget.routeListenable?.removeListener(_onRoute);
    super.dispose();
  }

  /// GoRouter notifies while it is being built, so a plain setState here raised "setState() called during build"
  /// (N-02/N-03). Rebuild after the current frame instead.
  void _onRoute() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final media = MediaQuery.of(context);
    if (media.size.shortestSide < 600) return child;
    // The widget tree keeps one shape on every route, so the router's navigator (global keys) is never re-parented
    // when the route changes; only the numbers change. Main-tab routes on a desktop-wide window use the full width.
    final full = media.size.width >= DesktopShell.breakpoint && widget.currentPath != null && DesktopShell.isShellPath(widget.currentPath!());

    final width = media.size.width;
    final frameWidth = width >= 1100 ? 880.0 : 760.0;
    final used = full || width < frameWidth ? width : frameWidth;
    final typeScale = full ? 1.0 : (width >= 1100 ? 1.28 : 1.16);
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
