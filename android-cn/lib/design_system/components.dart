// 通用组件库 - 顺时 Flutter 专用

import 'package:flutter/material.dart';
import '../design_system/theme.dart';

// ==================== AppButton ====================

enum ShunShiButtonVariant { primary, secondary, ghost, text }
enum ShunShiButtonSize { large, medium, small, mini }

class ShunShiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ShunShiButtonVariant variant;
  final ShunShiButtonSize size;
  final IconData? icon;
  
  const ShunShiButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ShunShiButtonVariant.primary,
    this.size = ShunShiButtonSize.medium,
    this.icon,
  });
  
  double get _height {
    switch (size) {
      case ShunShiButtonSize.large: return 56;
      case ShunShiButtonSize.medium: return 48;
      case ShunShiButtonSize.small: return 36;
      case ShunShiButtonSize.mini: return 28;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == ShunShiButtonVariant.primary 
                  ? Colors.white 
                  : ShunShiColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _height * 0.35),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );
    
    switch (variant) {
      case ShunShiButtonVariant.primary:
        return SizedBox(
          height: _height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case ShunShiButtonVariant.secondary:
        return SizedBox(
          height: _height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case ShunShiButtonVariant.ghost:
        return SizedBox(
          height: _height,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case ShunShiButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}

// ==================== AppCard ====================

class ShunShiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? background;
  final BorderRadius? radius;
  final List<BoxShadow>? shadow;
  
  const ShunShiCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.background,
    this.radius,
    this.shadow,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background ?? ShunShiColors.surface,
        borderRadius: radius ?? ShunShiRadius.cardRadius,
        boxShadow: shadow ?? ShunShiShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius ?? ShunShiRadius.cardRadius,
          child: Padding(
            padding: padding ?? EdgeInsets.all(ShunShiSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ==================== AppTextField ====================

class ShunShiTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const ShunShiTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onEditingComplete,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ==================== Loading ====================

class ShunShiLoading extends StatelessWidget {
  final String? message;
  final bool overlay;
  
  const ShunShiLoading({
    super.key,
    this.message,
    this.overlay = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          color: ShunShiColors.primary,
          strokeWidth: 3,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: ShunShiTypography.bodyMedium,
          ),
        ],
      ],
    );
    
    if (overlay) {
      return Container(
        color: Colors.black26,
        child: Center(child: content),
      );
    }
    
    return Center(child: content);
  }
}

// ==================== Empty State ====================

class ShunShiEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  
  const ShunShiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ShunShiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: ShunShiColors.textTertiary,
            ),
            const SizedBox(height: ShunShiSpacing.md),
            Text(
              title,
              style: ShunShiTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: ShunShiSpacing.xs),
              Text(
                description!,
                style: ShunShiTypography.bodyMedium.copyWith(
                  color: ShunShiColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ShunShiSpacing.lg),
              ShunShiButton(
                text: actionText!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== Error State ====================

class ShunShiErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  
  const ShunShiErrorState({
    super.key,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShunShiEmptyState(
      icon: Icons.error_outline,
      title: title,
      description: description,
      actionText: actionText ?? '重试',
      onAction: onAction ?? () {},
    );
  }
}

// ==================== Notice Card ====================

enum ShunShiNoticeType { info, success, warning, error }

class ShunShiNoticeCard extends StatelessWidget {
  final String title;
  final String? message;
  final ShunShiNoticeType type;
  final VoidCallback? onDismiss;
  final List<Widget>? actions;
  
  const ShunShiNoticeCard({
    super.key,
    required this.title,
    this.message,
    this.type = ShunShiNoticeType.info,
    this.onDismiss,
    this.actions,
  });
  
  Color get _backgroundColor {
    switch (type) {
      case ShunShiNoticeType.info: return ShunShiColors.blue.withValues(alpha: 0.1);
      case ShunShiNoticeType.success: return ShunShiColors.success.withValues(alpha: 0.1);
      case ShunShiNoticeType.warning: return ShunShiColors.warning.withValues(alpha: 0.1);
      case ShunShiNoticeType.error: return ShunShiColors.error.withValues(alpha: 0.1);
    }
  }
  
  Color get _iconColor {
    switch (type) {
      case ShunShiNoticeType.info: return ShunShiColors.blue;
      case ShunShiNoticeType.success: return ShunShiColors.success;
      case ShunShiNoticeType.warning: return ShunShiColors.warning;
      case ShunShiNoticeType.error: return ShunShiColors.error;
    }
  }
  
  IconData get _icon {
    switch (type) {
      case ShunShiNoticeType.info: return Icons.info_outline;
      case ShunShiNoticeType.success: return Icons.check_circle_outline;
      case ShunShiNoticeType.warning: return Icons.warning_amber_outlined;
      case ShunShiNoticeType.error: return Icons.error_outline;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ShunShiSpacing.md),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _iconColor, size: 24),
          const SizedBox(width: ShunShiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ShunShiTypography.titleMedium),
                if (message != null) ...[
                  const SizedBox(height: ShunShiSpacing.xxs),
                  Text(
                    message!,
                    style: ShunShiTypography.bodyMedium.copyWith(
                      color: ShunShiColors.textSecondary,
                    ),
                  ),
                ],
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: ShunShiSpacing.sm),
                  Row(children: actions!),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: ShunShiColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

// ==================== Bottom Navigation ====================

class ShunShiBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  
  const ShunShiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(Icons.chat),
          label: '对话',
        ),
        NavigationDestination(
          icon: Icon(Icons.spa_outlined),
          selectedIcon: Icon(Icons.spa),
          label: '养生',
        ),
        NavigationDestination(
          icon: Icon(Icons.family_restroom_outlined),
          selectedIcon: Icon(Icons.family_restroom),
          label: '家庭',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }
}
