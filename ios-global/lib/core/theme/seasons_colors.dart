import 'package:flutter/material.dart';

/// Seasons 颜色系统 — 极简、冷调、更留白
///
/// 国际版设计原则：
/// - 比国内版更极简、更冷调
/// - 主色从温暖绿转为静谧蓝
/// - 背景更白，文字更浅
/// - 辅助色偏冷，营造安静感
class SeasonsColors {
  SeasonsColors._();

  // ── 主色：静谧蓝 ──
  static const Color primary = Color(0xFF9BB8C9);
  static const Color primaryLight = Color(0xFFC5D8E5);
  static const Color primaryDark = Color(0xFF7A9BAC);

  // ── 背景：极浅灰白 ──
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF5F5F5);

  // ── 文字：更浅 ──
  static const Color textPrimary = Color(0xFF3C3C3C);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textHint = Color(0xFFCCCCCC);

  // ── 辅助：更冷调 ──
  static const Color warm = Color(0xFFD4B896);
  static const Color sage = Color(0xFFB5C7A8);
  static const Color sand = Color(0xFFE8DDD0);
  static const Color sky = Color(0xFFB8D4E3);

  // ── 语义色 ──
  static const Color success = Color(0xFF9BB8C9);
  static const Color warning = Color(0xFFE8C87A);
  static const Color error = Color(0xFFD4A5A5);

  // ── 边框与分割 ──
  static const Color divider = Color(0xFFEDEDED);
  static const Color border = Color(0xFFEDEDED);

  // ── 暗色模式 ──
  static const SeasonsDarkColors dark = SeasonsDarkColors();
}

/// 暗色模式颜色 — 冷灰调
class SeasonsDarkColors {
  const SeasonsDarkColors();

  static const Color primary = Color(0xFFB0C8D5);
  static const Color primaryLight = Color(0xFFD0E0EA);
  static const Color primaryDark = Color(0xFF9BB8C9);

  static const Color background = Color(0xFF181818);
  static const Color surface = Color(0xFF222222);
  static const Color surfaceDim = Color(0xFF2C2C2C);

  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF909090);
  static const Color textHint = Color(0xFF606060);

  static const Color warm = Color(0xFFC0A888);
  static const Color sage = Color(0xFFA5B89A);
  static const Color sand = Color(0xFFD0C8BC);
  static const Color sky = Color(0xFFA0C0D0);

  static const Color success = Color(0xFFB0C8D5);
  static const Color warning = Color(0xFFD0B860);
  static const Color error = Color(0xFFC09898);

  static const Color divider = Color(0xFF383838);
  static const Color border = Color(0xFF383838);
}
