import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_animations.dart';

/// 柔和卡片 — Seasons版
class SoftCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
  });

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: SeasonsAnimations.tapFeedback,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: SeasonsAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _backgroundColor(BuildContext context) {
    if (widget.color != null) return widget.color!;
    return _isDark(context)
        ? SeasonsDarkColors.surfaceDim
        : SeasonsColors.surfaceDim;
  }

  Color _borderColor(BuildContext context) {
    if (widget.borderColor != null) return widget.borderColor!;
    return _isDark(context)
        ? SeasonsDarkColors.border
        : SeasonsColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) {
        _controller.reverse();
        widget.onTap?.call();
      } : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: AnimatedScale(
        scale: _scaleAnimation.value,
        duration: SeasonsAnimations.tapFeedback,
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.all(SeasonsSpacing.cardPadding),
          decoration: BoxDecoration(
            color: _backgroundColor(context),
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? SeasonsSpacing.radiusLarge,
            ),
            border: Border.all(
              color: _borderColor(context),
              width: widget.borderWidth ?? 1.0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
