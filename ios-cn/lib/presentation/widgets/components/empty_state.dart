import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import 'breathing_animation.dart';
import 'gentle_button.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/style_theming.dart';

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
        : AppColors.textTertiary(context);

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
                    : AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: ShunshiSpacing.sm),
              Text(
                subtitle!,
                style: ShunshiTextStyles.caption.themed(context),
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
