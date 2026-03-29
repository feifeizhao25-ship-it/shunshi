import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_animations.dart';
import '../../../core/theme/seasons_text_styles.dart';

/// 温和按钮 — Seasons版
class GentleButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final double? horizontalPadding;

  const GentleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.horizontalPadding,
  });

  @override
  State<GentleButton> createState() => _GentleButtonState();
}

class _GentleButtonState extends State<GentleButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    if (_isDark(context)) {
      return widget.isPrimary
          ? SeasonsDarkColors.primary
          : SeasonsDarkColors.surfaceDim;
    }
    return widget.isPrimary ? SeasonsColors.primary : SeasonsColors.surfaceDim;
  }

  Color _textColor(BuildContext context) {
    if (_isDark(context)) {
      return widget.isPrimary
          ? SeasonsDarkColors.background
          : SeasonsDarkColors.textPrimary;
    }
    return widget.isPrimary ? Colors.white : SeasonsColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled ? (_) {
        _controller.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      child: AnimatedScale(
        scale: _scaleAnimation.value,
        duration: SeasonsAnimations.tapFeedback,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding ?? SeasonsSpacing.lg,
              vertical: SeasonsSpacing.md,
            ),
            decoration: BoxDecoration(
              color: _backgroundColor(context),
              borderRadius:
                  BorderRadius.circular(SeasonsSpacing.radiusXL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textColor(context),
                    ),
                  )
                else if (widget.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: SeasonsSpacing.xs),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: _textColor(context),
                    ),
                  ),
                Text(
                  widget.text,
                  style: SeasonsTextStyles.button.copyWith(
                    color: _textColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
