import 'package:flutter/material.dart';
import '../theme.dart';

/// 统一文本组件 - 禁止直接使用 Text()
enum AppTextLevel {
  displayLarge,
  displayMedium,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

class AppText extends StatelessWidget {
  final String text;
  final AppTextLevel level;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.level = AppTextLevel.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  const AppText.displayLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.displayLarge;

  const AppText.displayMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.displayMedium;

  const AppText.headlineLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.headlineLarge;

  const AppText.headlineMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.headlineMedium;

  const AppText.headlineSmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.headlineSmall;

  const AppText.titleLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.titleLarge;

  const AppText.titleMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.titleMedium;

  const AppText.bodyLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.bodyLarge;

  const AppText.bodyMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.bodyMedium;

  const AppText.bodySmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.bodySmall;

  const AppText.labelLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.labelLarge;

  const AppText.labelMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.labelMedium;

  const AppText.labelSmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : level = AppTextLevel.labelSmall;

  TextStyle get _style {
    switch (level) {
      case AppTextLevel.displayLarge:
        return AppTextStyles.displayLarge;
      case AppTextLevel.displayMedium:
        return AppTextStyles.displayMedium;
      case AppTextLevel.headlineLarge:
        return AppTextStyles.headlineLarge;
      case AppTextLevel.headlineMedium:
        return AppTextStyles.headlineMedium;
      case AppTextLevel.headlineSmall:
        return AppTextStyles.headlineSmall;
      case AppTextLevel.titleLarge:
        return AppTextStyles.titleLarge;
      case AppTextLevel.titleMedium:
        return AppTextStyles.titleMedium;
      case AppTextLevel.bodyLarge:
        return AppTextStyles.bodyLarge;
      case AppTextLevel.bodyMedium:
        return AppTextStyles.bodyMedium;
      case AppTextLevel.bodySmall:
        return AppTextStyles.bodySmall;
      case AppTextLevel.labelLarge:
        return AppTextStyles.labelLarge;
      case AppTextLevel.labelMedium:
        return AppTextStyles.labelMedium;
      case AppTextLevel.labelSmall:
        return AppTextStyles.labelSmall;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: color != null ? _style.copyWith(color: color) : _style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
