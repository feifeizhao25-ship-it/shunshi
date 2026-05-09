import 'package:flutter/material.dart';
import 'theme.dart';

/// 主题感知颜色辅助 — 一行获取亮/暗色
///
/// 用法: AppColors.textPrimary(context), AppColors.background(context)
class AppColors {
  AppColors._();

  // ── 判断暗色 ──
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── 背景 ──
  static Color background(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkBackground : ShunShiColors.background;

  static Color surface(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkSurface : ShunShiColors.surface;

  static Color surfaceContainerLow(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkSurfaceContainerLow : ShunShiColors.surfaceContainerLow;

  static Color surfaceContainerLowest(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest;

  // ── 文字 ──
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkTextTertiary ?? ShunShiColors.darkTextSecondary : ShunShiColors.textTertiary;

  static Color textDisabled(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkTextDisabled ?? ShunShiColors.darkTextSecondary : ShunShiColors.textDisabled;

  // ── 边框 ──
  static Color border(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkBorder : ShunShiColors.border;

  static Color borderGhost(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost;

  static Color divider(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkBorder : ShunShiColors.divider;

  // ── 主色 ──
  static Color primary(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkPrimary : ShunShiColors.primary;

  static Color primaryLight(BuildContext context) =>
      isDark(context) ? ShunShiColors.primaryLight : ShunShiColors.primaryLight;

  // ── 卡片 ──
  static Color card(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest;

  // ── 辅助色 ──
  static Color warm(BuildContext context) =>
      isDark(context) ? const Color(0xFFC4956A) : ShunShiColors.warm;

  static Color calm(BuildContext context) =>
      isDark(context) ? const Color(0xFF8AAABB) : ShunShiColors.calm;

  static Color error(BuildContext context) =>
      isDark(context) ? ShunShiColors.darkError : ShunShiColors.error;
}
