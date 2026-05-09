// Ultimate UI Components for ShunShi
// Based on Ultimate UI Structure v1.0

import 'package:flutter/material.dart';

// ==================== Color System ====================

class ShunShiColors {
  // Primary
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  
  // Secondary
  static const Color secondary = Color(0xFF8BC34A);
  static const Color secondaryLight = Color(0xFFAED581);
  
  // Neutrals
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Accents
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient morningGradient = LinearGradient(
    colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient nightGradient = LinearGradient(
    colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ==================== Typography ====================

class ShunShiTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ShunShiColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: ShunShiColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: ShunShiColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: ShunShiColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: ShunShiColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textHint,
    height: 1.3,
  );
  
  // Age-adaptive text styles
  static TextStyle adaptive({
    required int age,
    TextStyle? baseStyle,
  }) {
    final style = baseStyle ?? bodyLarge;
    if (age >= 60) {
      return style.copyWith(fontSize: style.fontSize! + 4);
    } else if (age >= 40) {
      return style.copyWith(fontSize: style.fontSize! + 2);
    }
    return style;
  }
}

// ==================== Spacing System ====================

class ShunShiSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ==================== Border Radius ====================

class ShunShiRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
  
  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get extraLarge => BorderRadius.circular(xl);
}

// ==================== Shadows ====================

class ShunShiShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withAlpha(13),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withAlpha(26),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withAlpha(38),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

// ==================== Card Components ====================

class ShunShiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool elevated;
  
  const ShunShiCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
    this.elevated = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? ShunShiColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? ShunShiRadius.lg),
        boxShadow: elevated ? ShunShiShadows.medium : ShunShiShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? ShunShiRadius.lg),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ==================== Insight Card ====================

class InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? accentColor;
  
  const InsightCard({
    super.key,
    this.title = '今日洞察',
    required this.content,
    this.icon,
    this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? ShunShiColors.primary;
    
    return ShunShiCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon ?? Icons.insights, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: ShunShiTextStyles.labelLarge.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: ShunShiTextStyles.bodyLarge.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Three Things Card ====================

class ThreeThingsCard extends StatelessWidget {
  final List<String> things;
  final VoidCallback? onTap;
  
  const ThreeThingsCard({
    super.key,
    required this.things,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShunShiCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: ShunShiColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '今日三件小事',
                style: ShunShiTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...things.asMap().entries.map((entry) {
            final index = entry.key;
            final thing = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ShunShiColors.primaryLight.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: ShunShiTextStyles.labelSmall.copyWith(
                        color: ShunShiColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      thing,
                      style: ShunShiTextStyles.bodyMedium.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==================== AI Chat Entry Card ====================

class AIChatEntryCard extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  
  const AIChatEntryCard({
    super.key,
    this.message = '今天想和我聊聊吗？',
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShunShiCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: ShunShiColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '小顺',
                  style: ShunShiTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: ShunShiTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: ShunShiColors.textHint,
          ),
        ],
      ),
    );
  }
}

// ==================== Follow Up Card ====================

class FollowUpCard extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  
  const FollowUpCard({
    super.key,
    required this.message,
    this.onTap,
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShunShiCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ShunShiColors.warning.withAlpha(26),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ShunShiColors.warning.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.update,
              color: ShunShiColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: ShunShiTextStyles.bodyMedium,
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: ShunShiColors.textHint,
            ),
        ],
      ),
    );
  }
}

// ==================== Solar Term Card ====================

class SolarTermCard extends StatelessWidget {
  final String name;
  final String suggestion;
  final VoidCallback? onTap;
  
  const SolarTermCard({
    super.key,
    required this.name,
    required this.suggestion,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ShunShiCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: ShunShiColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wb_sunny,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日节气',
                  style: ShunShiTextStyles.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: ShunShiTextStyles.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion,
                  style: ShunShiTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: ShunShiColors.textHint,
          ),
        ],
      ),
    );
  }
}

// ==================== Family Status Card ====================

class FamilyStatusCard extends StatelessWidget {
  final String memberName;
  final String status; // 'stable', 'concern', 'attention'
  final String? message;
  final VoidCallback? onTap;
  
  const FamilyStatusCard({
    super.key,
    required this.memberName,
    required this.status,
    this.message,
    this.onTap,
  });
  
  Color get statusColor {
    switch (status) {
      case 'stable':
        return ShunShiColors.success;
      case 'concern':
        return ShunShiColors.warning;
      case 'attention':
        return ShunShiColors.error;
      default:
        return ShunShiColors.success;
    }
  }
  
  IconData get statusIcon {
    switch (status) {
      case 'stable':
        return Icons.check_circle;
      case 'concern':
        return Icons.warning_amber;
      case 'attention':
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ShunShiCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.person,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      memberName,
                      style: ShunShiTextStyles.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Icon(statusIcon, color: statusColor, size: 16),
                  ],
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: ShunShiTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Quick Questions ====================

class QuickQuestionsBar extends StatelessWidget {
  final List<String> questions;
  final Function(String)? onTap;
  
  const QuickQuestionsBar({
    super.key,
    required this.questions,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 快捷问题',
            style: ShunShiTextStyles.labelSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((q) {
              return InkWell(
                onTap: () => onTap?.call(q),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ShunShiColors.primary.withAlpha(51),
                    ),
                  ),
                  child: Text(
                    q,
                    style: ShunShiTextStyles.bodySmall.copyWith(
                      color: ShunShiColors.primaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==================== Category Tab ====================

class CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  
  const CategoryTab({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? ShunShiColors.primary 
              : ShunShiColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : ShunShiColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: ShunShiTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : ShunShiColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Greeting Header ====================

class GreetingHeader extends StatelessWidget {
  final String greeting;
  final String? subtitle;
  final int age;
  
  const GreetingHeader({
    super.key,
    required this.greeting,
    this.subtitle,
    this.age = 25,
  });
  
  String get _timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👋 $_timeBasedGreeting',
            style: ShunShiTextStyles.adaptive(
              age: age,
              baseStyle: ShunShiTextStyles.headlineMedium,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: ShunShiTextStyles.adaptive(
                age: age,
                baseStyle: ShunShiTextStyles.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
