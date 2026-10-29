import 'package:flutter/material.dart';
import '../../design_system/theme.dart';

/// 平板和大屏不再收成 480 宽的手机条。
/// 内容加宽、字号放大，两侧用页面同色，避免米色空带。
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.shortestSide < 600) return child;

    final width = media.size.width;
    final frameWidth = width >= 1100 ? 880.0 : 760.0;
    final used = width < frameWidth ? width : frameWidth;
    final typeScale = width >= 1100 ? 1.28 : 1.16;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

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
