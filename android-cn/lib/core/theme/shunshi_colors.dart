import 'package:flutter/material.dart';

/// 顺时颜色系统 — 温暖、自然、低饱和度
///
/// 核心原则：永远不用纯白/纯黑，永远用低饱和度
/// 所有颜色都经过精心调配，营造"慢下来"的视觉氛围
class ShunshiColors {
  ShunshiColors._();

  // ── 主色：温暖绿（鼠尾草绿） ──
  static const Color primary = Color(0xFF8B9E7E);
  static const Color primaryLight = Color(0xFFB5C7A8);
  static const Color primaryDark = Color(0xFF6B7E5E);

  // ── 背景：米白暖色 ──
  static const Color background = Color(0xFFF8F6F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF0EDE6);

  // ── 文字：深灰不是纯黑 ──
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF8C8C8C);
  static const Color textHint = Color(0xFFBFBFBF);

  // ── 辅助色：温和低饱和 ──
  static const Color warm = Color(0xFFD4A574);
  static const Color calm = Color(0xFF9BB8C9);
  static const Color earth = Color(0xFFC4B5A0);
  static const Color blush = Color(0xFFD4A5A5);

  // ── 语义色：温和版 ──
  static const Color success = Color(0xFF8B9E7E);
  static const Color warning = Color(0xFFE8C87A);
  static const Color error = Color(0xFFD4A5A5);

  // ── 边框与分割 ──
  static const Color divider = Color(0xFFE8E4DD);
  static const Color border = Color(0xFFE8E4DD);
  static const Color borderLight = Color(0xFFF0EDE6);

  // ── 别名（兼容） ──
  static const Color accent = calm;
  static const Color accentLight = Color(0xFFC2D7E4);
  static const Color cardBackground = surface;
  static const Color textTertiary = textHint;

  // ── 暗色模式预设 ──
  static const ShunshiDarkColors dark = ShunshiDarkColors();
}

/// 暗色模式颜色预设
///
/// 保持温暖调性，不做冷灰暗色
/// 始终低于纯黑，避免刺眼
class ShunshiDarkColors {
  const ShunshiDarkColors();

  // 主色：稍亮
  static const Color primary = Color(0xFFA8B89E);
  static const Color primaryLight = Color(0xFFC5D1BB);
  static const Color primaryDark = Color(0xFF8B9E7E);

  // 背景：深灰暖色
  static const Color background = Color(0xFF1A1A18);
  static const Color surface = Color(0xFF252523);
  static const Color surfaceDim = Color(0xFF2E2E2B);

  // 文字：柔和白
  static const Color textPrimary = Color(0xFFE8E6E1);
  static const Color textSecondary = Color(0xFF9C9C96);
  static const Color textHint = Color(0xFF6E6E68);

  // 辅助色：暗调版
  static const Color warm = Color(0xFFC4956A);
  static const Color calm = Color(0xFF8AAABB);
  static const Color earth = Color(0xFFB0A28E);
  static const Color blush = Color(0xFFC09090);

  // 语义色
  static const Color success = Color(0xFFA8B89E);
  static const Color warning = Color(0xFFD4B86A);
  static const Color error = Color(0xFFC09090);

  // 边框
  static const Color divider = Color(0xFF3A3A36);
  static const Color border = Color(0xFF3A3A36);
}
