import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import 'breathing_animation.dart';
import 'gentle_button.dart';

/// 空状态组件 — 居中、轻量、无压迫感
class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.subtitle,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final iconColor = isDark
        ? ShunshiDarkColors.textHint
        : ShunshiColors.textHint;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.xxl,
          vertical: ShunshiSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              BreathingAnimation(
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor,
                ),
              ),
            if (icon != null)
              const SizedBox(height: ShunshiSpacing.lg),
            Text(
              message,
              style: ShunshiTextStyles.body.copyWith(
                color: isDark
                    ? ShunshiDarkColors.textSecondary
                    : ShunshiColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: ShunshiSpacing.sm),
              Text(
                subtitle!,
                style: ShunshiTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ShunshiSpacing.xl),
              GentleButton(
                text: actionText!,
                isPrimary: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
