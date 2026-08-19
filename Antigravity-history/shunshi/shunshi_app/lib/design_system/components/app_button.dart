import 'package:flutter/material.dart';
import '../theme.dart';

enum AppButtonStyle { primary, secondary, outline, text, danger }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : style = AppButtonStyle.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : style = AppButtonStyle.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : style = AppButtonStyle.outline;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : style = AppButtonStyle.text;

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.lg);
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();

    Widget button;
    switch (style) {
      case AppButtonStyle.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            elevation: 0,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
          ),
          child: child,
        );
        break;
      case AppButtonStyle.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            elevation: 0,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
          ),
          child: child,
        );
        break;
      case AppButtonStyle.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
          ),
          child: child,
        );
        break;
      case AppButtonStyle.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: _padding,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
          ),
          child: child,
        );
        break;
      case AppButtonStyle.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onPrimary,
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            elevation: 0,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
          ),
          child: child,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        height: _fontSize + 4,
        width: _fontSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: style == AppButtonStyle.outline || style == AppButtonStyle.text
              ? AppColors.primary
              : AppColors.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _fontSize + 4),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
