import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_text.dart';

enum AppNoticeType { info, warning, safety, success }

class AppNoticeCard extends StatelessWidget {
  final String message;
  final AppNoticeType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const AppNoticeCard({
    super.key,
    required this.message,
    this.type = AppNoticeType.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  const AppNoticeCard.safety({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  }) : type = AppNoticeType.safety;

  const AppNoticeCard.warning({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  }) : type = AppNoticeType.warning;

  Color get _bgColor {
    switch (type) {
      case AppNoticeType.info:
        return const Color(0xFFE8F0FE);
      case AppNoticeType.warning:
        return const Color(0xFFFFF3E0);
      case AppNoticeType.safety:
        return AppColors.safetyBg;
      case AppNoticeType.success:
        return const Color(0xFFE8F5E9);
    }
  }

  Color get _borderColor {
    switch (type) {
      case AppNoticeType.info:
        return AppColors.info;
      case AppNoticeType.warning:
        return AppColors.warning;
      case AppNoticeType.safety:
        return AppColors.safetyBorder;
      case AppNoticeType.success:
        return AppColors.success;
    }
  }

  IconData get _icon {
    if (icon != null) return icon!;
    switch (type) {
      case AppNoticeType.info:
        return Icons.info_outline_rounded;
      case AppNoticeType.warning:
        return Icons.warning_amber_rounded;
      case AppNoticeType.safety:
        return Icons.shield_outlined;
      case AppNoticeType.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: _borderColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _borderColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  message,
                  color: AppColors.textPrimary,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: onAction,
                    child: AppText.labelMedium(
                      actionLabel!,
                      color: _borderColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
