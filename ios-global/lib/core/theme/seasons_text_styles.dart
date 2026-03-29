import 'package:flutter/material.dart';
import 'seasons_colors.dart';

/// Seasons 字体系统 — 更大、更轻
///
/// 国际版字体原则：
/// - 比国内版大1-2号
/// - weight更轻（w300为主）
/// - 间距更大，信息密度更低
/// - 西文友好（letter-spacing稍宽）
class SeasonsTextStyles {
  SeasonsTextStyles._();

  // ── Greeting：超大、极轻 ──
  static const TextStyle greeting = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w200,
    color: SeasonsColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.3,
  );

  // ── Daily Insight：大号、空气感 ──
  static const TextStyle insight = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    color: SeasonsColors.textPrimary,
    height: 1.6,
    letterSpacing: 0.2,
  );

  // ── Heading ──
  static const TextStyle heading = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    color: SeasonsColors.textPrimary,
    height: 1.4,
  );

  // ── Body：舒适 ──
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w300,
    color: SeasonsColors.textPrimary,
    height: 1.8,
  );

  // ── Body Secondary ──
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w300,
    color: SeasonsColors.textSecondary,
    height: 1.8,
  );

  // ── Caption ──
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: SeasonsColors.textSecondary,
    height: 1.5,
  );

  // ── Button ──
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SeasonsColors.textPrimary,
    letterSpacing: 0.5,
  );

  // ── Button Small ──
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: SeasonsColors.textPrimary,
    letterSpacing: 0.3,
  );

  // ── Hint ──
  static const TextStyle hint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    color: SeasonsColors.textHint,
    height: 1.6,
  );

  // ── Overline ──
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: SeasonsColors.textHint,
    letterSpacing: 1.0,
  );
}
