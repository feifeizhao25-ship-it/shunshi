import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import 'gentle_button.dart';

/// Error State — Seasons version
/// Gentle messaging, retry button
class ErrorState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.subtitle,
    this.onRetry,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final iconColor = isDark
        ? SeasonsDarkColors.error
        : SeasonsColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SeasonsSpacing.xxl,
          vertical: SeasonsSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: iconColor.withValues(alpha: 0.6),
            ),
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
            if (onRetry != null) ...[
              const SizedBox(height: SeasonsSpacing.xl),
              GentleButton(
                text: 'Retry',
                isPrimary: true,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
