import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import 'gentle_button.dart';

/// 错误状态组件 — 温和提示，重试按钮
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
        ? ShunshiDarkColors.error
        : ShunshiColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.xxl,
          vertical: ShunshiSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: iconColor.withValues(alpha: 0.6),
            ),
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
            if (onRetry != null) ...[
              const SizedBox(height: ShunshiSpacing.xl),
              GentleButton(
                text: '重试',
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
