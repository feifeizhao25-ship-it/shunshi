import 'package:flutter/material.dart';

import '../core/theme/shunshi_colors.dart';
import 'app_colors.dart' as ac;
import 'theme.dart' show ShunShiColors;

/// 旧版 `ShunshiTextStyles` / `ShunShiTypography` 的颜色写死为浅色值；
/// 用 `.themed(context)` 让文字颜色跟随深浅色主题（浅色下颜色不变）。
extension ShunshiTextStyleTheming on TextStyle {
  TextStyle themed(BuildContext context) {
    final c = color;
    if (c == ShunshiColors.textPrimary || c == ShunShiColors.textPrimary) {
      return copyWith(color: ac.AppColors.textPrimary(context));
    }
    if (c == ShunshiColors.textSecondary || c == ShunShiColors.textSecondary) {
      return copyWith(color: ac.AppColors.textSecondary(context));
    }
    if (c == ShunshiColors.textHint || c == ShunShiColors.textTertiary) {
      return copyWith(color: ac.AppColors.textTertiary(context));
    }
    if (c == ShunshiColors.primary || c == ShunShiColors.primary) {
      return copyWith(color: ac.AppColors.primary(context));
    }
    return this;
  }
}
