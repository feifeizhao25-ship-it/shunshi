import 'package:flutter/material.dart';
import 'shunshi_colors.dart';

/// 顺时字体系统 — 舒适、留白、不压迫
///
/// 核心原则：
/// - 字号偏大，让内容有呼吸空间
/// - weight偏轻（w300-w400为主），柔和不强势
/// - line-height宽松（1.4-1.8），阅读不拥挤
/// - letterSpacing适度，中文紧缩、西文微展
class ShunshiTextStyles {
  ShunshiTextStyles._();

  // ── Greeting：超大、温暖 ──
  /// 用于首页问候语、大标题
  static const TextStyle greeting = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    color: ShunshiColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.5,
  );

  // ── Daily Insight：大号、留白 ──
  /// 用于每日洞察、引言
  static const TextStyle insight = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: ShunshiColors.textPrimary,
    height: 1.6,
  );

  // ── Heading：中等标题 ──
  /// 用于区块标题、卡片标题
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ShunshiColors.textPrimary,
    height: 1.4,
  );

  // ── Body：舒适阅读 ──
  /// 正文，默认文字样式
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ShunshiColors.textPrimary,
    height: 1.8,
  );

  // ── Body Secondary：次要正文 ──
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ShunshiColors.textSecondary,
    height: 1.8,
  );

  // ── Caption：轻量 ──
  /// 时间戳、标签、辅助信息
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ShunshiColors.textSecondary,
    height: 1.5,
  );

  // ── Button：中等 ──
  /// 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: ShunshiColors.textPrimary,
    letterSpacing: 0.3,
  );

  // ── Button Small：小号按钮 ──
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: ShunshiColors.textPrimary,
    letterSpacing: 0.2,
  );

  // ── Hint：提示文字 ──
  /// 占位符、未填写状态
  static const TextStyle hint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: ShunshiColors.textHint,
    height: 1.6,
  );

  // ── Overline：标注 ──
  /// 类别标签、小标注
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: ShunshiColors.textHint,
    letterSpacing: 0.8,
  );

  // ── Material 兼容别名 ──
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ShunshiColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ShunshiColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: ShunshiColors.textHint,
    letterSpacing: 0.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ShunshiColors.textPrimary,
    height: 1.4,
  );
}
