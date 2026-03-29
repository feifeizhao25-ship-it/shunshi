import 'package:flutter/animation.dart';

/// 顺时动画系统 — 慢节奏、不弹跳
///
/// 核心原则：
/// - 时长偏长（200-500ms），让用户"慢下来"
/// - 曲线统一easeOut系列，不使用弹簧/弹跳曲线
/// - 所有动画可预览、可预期、不突兀
/// - 呼吸动画是品牌特色，贯穿始终
class ShunshiAnimations {
  ShunshiAnimations._();

  // ── 时长 ──

  /// 页面切换 350ms
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// 卡片展开 300ms
  static const Duration cardExpand = Duration(milliseconds: 300);

  /// 呼吸动画 3000ms — 品牌特色
  static const Duration breathing = Duration(milliseconds: 3000);

  /// 点击反馈 150ms
  static const Duration tapFeedback = Duration(milliseconds: 150);

  /// 淡入 250ms
  static const Duration fadeIn = Duration(milliseconds: 250);

  /// 滑入 300ms
  static const Duration slideIn = Duration(milliseconds: 300);

  /// 状态变化 200ms
  static const Duration stateChange = Duration(milliseconds: 200);

  // ── 曲线 ──

  /// 通用缓出
  static const Curve easeOut = Curves.easeOut;

  /// 慢速缓出 — 用于重要转场
  static const Curve slowEase = Curves.easeOutCubic;

  /// 标准缓入缓出
  static const Curve easeInOut = Curves.easeInOut;

  // ── 预制Tween ──

  /// 呼吸缩放 0.97 → 1.0
  static final Tween<double> breathingScale = Tween<double>(begin: 0.97, end: 1.0);

  /// 点击缩放 1.0 → 0.97
  static final Tween<double> tapScale = Tween<double>(begin: 1.0, end: 0.97);

  /// 标准淡入 0.0 → 1.0
  static final Tween<double> fadeInTween = Tween<double>(begin: 0.0, end: 1.0);

  /// 轻微上滑偏移 16 → 0
  static final Tween<Offset> slideUpTween = Tween<Offset>(
    begin: const Offset(0, 16),
    end: Offset.zero,
  );
}
