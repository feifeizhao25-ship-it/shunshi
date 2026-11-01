import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/app_colors.dart';

/// Retest N06: on tablets and wide windows the app is no longer stretched edge to edge (1440 px wide).
/// Content is held to a centred column with slightly larger type; the sides use the page colour.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.shortestSide < 600) return child;

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
