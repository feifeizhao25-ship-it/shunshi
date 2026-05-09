import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import 'breathing_animation.dart';
import 'gentle_button.dart';

/// Empty State — Seasons version
/// Centered, gentle, no pressure
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
        ? SeasonsDarkColors.textHint
        : SeasonsColors.textHint;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SeasonsSpacing.xxl,
          vertical: SeasonsSpacing.xxl,
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
              const SizedBox(height: SeasonsSpacing.lg),
            Text(
              message,
              style: SeasonsTextStyles.body.copyWith(
                color: isDark
                    ? SeasonsDarkColors.textSecondary
                    : SeasonsColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: SeasonsSpacing.sm),
              Text(
                subtitle!,
                style: SeasonsTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: SeasonsSpacing.xl),
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
