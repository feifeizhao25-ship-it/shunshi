import 'package:flutter/animation.dart';

/// Seasons 动画系统 — 更慢、更轻
///
/// 国际版动画原则：
/// - 在国内版基础上更慢50ms
/// - 呼吸周期更长（3.5s vs 3s）
/// - 营造更极致的慢节奏体验
class SeasonsAnimations {
  SeasonsAnimations._();

  // ── 时长 ──
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration cardExpand = Duration(milliseconds: 350);
  static const Duration breathing = Duration(milliseconds: 3500);
  static const Duration tapFeedback = Duration(milliseconds: 150);
  static const Duration fadeIn = Duration(milliseconds: 300);
  static const Duration slideIn = Duration(milliseconds: 350);
  static const Duration stateChange = Duration(milliseconds: 250);

  // ── 曲线 ──
  static const Curve easeOut = Curves.easeOut;
  static const Curve slowEase = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOut;

  // ── 预制Tween ──
  static final Tween<double> breathingScale = Tween<double>(begin: 0.97, end: 1.0);
  static final Tween<double> tapScale = Tween<double>(begin: 1.0, end: 0.97);
  static final Tween<double> fadeInTween = Tween<double>(begin: 0.0, end: 1.0);
  static final Tween<Offset> slideUpTween = Tween<Offset>(
    begin: const Offset(0, 16),
    end: Offset.zero,
  );
}
