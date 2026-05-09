import 'package:flutter/material.dart';

/// SEASONS颜色系统 V2.0 — "水墨画" 设计规范
///
/// 基于 ui参考-SEASONS/shunshi_zen_ritual/DESIGN.md
/// Creative North Star: "The Digital Scroll"
/// New Chinese Editorial Aesthetic: 不对称、大量留白、无硬线
class ShunshiColors {
  ShunshiColors._();

  // ── 核心色：墨绿 ──
  static const Color primary = Color(0xFF144227);
  static const Color primaryContainer = Color(0xFF2D5A3D);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── 次要色：暖杏 ──
  static const Color secondary = Color(0xFF74593C);
  static const Color secondaryContainer = Color(0xFFFFD9B4);
  static const Color onSecondary = Color(0xFF795D40);

  // ── 高级色：淡金（Premium专用） ──
  static const Color tertiary = Color(0xFF4C3605);
  static const Color tertiaryFixed = Color(0xFFE4C285);
  static const Color tertiaryFixedDim = Color(0xFFD4B275);

  // ── 画布：宣纸白 ──
  static const Color surface = Color(0xFFFDF9F4);
  static const Color surfaceContainerLow = Color(0xFFF7F3EE);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF1EDE7);
  static const Color surfaceContainerHigh = Color(0xFFEBE7E1);
  static const Color surfaceContainerHighest = Color(0xFFE5E1DB);
  static const Color surfaceBright = Color(0xFFFFFBF5);

  // ── 背景 ──
  static const Color background = Color(0xFFFDF9F4);
  static const Color onBackground = Color(0xFF1C1C19);

  // ── 文字 ──
  static const Color textPrimary = Color(0xFF1C1C19);
  static const Color textSecondary = Color(0xFF6B7B7D);
  static const Color textTertiary = Color(0xFF9CA3A5);
  static const Color textHint = Color(0xFFB5BBBD);

  // ── 辅助色：自然系 ──
  static const Color warm = Color(0xFFD4A574);
  static const Color calm = Color(0xFF9BB8C9);
  static const Color earth = Color(0xFFC4B5A0);
  static const Color blush = Color(0xFFD4A5A5);

  // ── 语义色：温和版 ──
  static const Color success = Color(0xFF144227);
  static const Color warning = Color(0xFFE8C87A);
  static const Color error = Color(0xFFB85450);

  // ── Ghost Border（20%透明度） ──
  static const Color outline = Color(0xFF1C1C19);
  static const Color outlineVariant = Color(0xFFC1C9C0);

  // ── 边框（无硬线原则） ──
  static const Color divider = Color(0xFFEBE7E1);
  static const Color border = Color(0xFFC1C9C0);

  // ── 兼容别名 ──
  static const Color accent = calm;
  static const Color accentLight = Color(0xFFC2D7E4);
  static const Color primaryLight = primaryContainer;
  static const Color primaryDark = primary;
  static const Color cardBackground = surfaceContainerLowest;
  static const Color surfaceDim = surfaceContainerLow;
  static const Color borderLight = surfaceContainerHigh;

  // ── 季节色 ──
  static const Color springGreen = Color(0xFF4A7C59);
  static const Color summerRed = Color(0xFFC4564F);
  static const Color autumnGold = Color(0xFFC4956A);
  static const Color winterBlue = Color(0xFF6B8FAD);

  // ── 暗色模式 ──
  static const ShunshiDarkColors dark = ShunshiDarkColors();
}

/// 暗色模式 — 深色禅意
class ShunshiDarkColors {
  const ShunshiDarkColors();

  static const Color primary = Color(0xFFA8B89E);
  static const Color primaryContainer = Color(0xFF2D5A3D);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceDim = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFE8E6E1);
  static const Color textSecondary = Color(0xFF9C9C96);
  static const Color textHint = Color(0xFF6E6E68);
  static const Color divider = Color(0xFF3A3A36);
  static const Color border = Color(0xFF3A3A36);
  static const Color error = Color(0xFFE57373);
  static const Color warm = Color(0xFFC4956A);
  static const Color calm = Color(0xFF8AAABB);
  static const Color primaryLight = Color(0xFFC5D1BB);
}
