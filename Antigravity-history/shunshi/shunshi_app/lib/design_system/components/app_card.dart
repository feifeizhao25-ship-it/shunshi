import 'package:flutter/material.dart';
import '../theme.dart';

enum AppCardVariant { elevated, outlined, filled }

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.width,
    this.height,
  });

  const AppCard.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.width,
    this.height,
  }) : variant = AppCardVariant.elevated;

  const AppCard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.width,
    this.height,
  }) : variant = AppCardVariant.outlined;

  const AppCard.filled({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.width,
    this.height,
  }) : variant = AppCardVariant.filled;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surface;
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);

    BoxDecoration decoration;
    switch (variant) {
      case AppCardVariant.elevated:
        decoration = BoxDecoration(
          color: effectiveBg,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.soft,
        );
        break;
      case AppCardVariant.outlined:
        decoration = BoxDecoration(
          color: effectiveBg,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.divider, width: 1),
        );
        break;
      case AppCardVariant.filled:
        decoration = BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.lgAll,
        );
        break;
    }

    Widget card = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
