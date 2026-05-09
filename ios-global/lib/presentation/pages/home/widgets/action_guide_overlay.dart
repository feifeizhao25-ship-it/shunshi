import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';

/// 行动引导断点 — 3-5-10秒法则的核心组件
///
/// 场景：
/// - 用户打开App → 立即看到"今天最重要的行动是什么"
/// - 完成行动后 → 看到下一个行动指引（断点）
/// - 没有行动时 → 看到默认引导
///
/// 视觉：半透明渐变卡片，带步骤指示器，引导下一步
class ActionGuideOverlay extends StatelessWidget {
  /// 步骤类型
  final String step;
  final VoidCallback onAction;

  const ActionGuideOverlay({
    super.key,
    required this.step,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final guide = _getGuide(step);

    return GestureDetector(
      onTap: onAction,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: guide.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: guide.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // 步骤图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: guide.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(guide.icon, color: guide.color, size: 18),
            ),
            const SizedBox(width: 12),
            // 引导文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guide.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: ShunShiColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 步骤指示器
            _buildStepIndicator(guide.stepNum),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: guide.color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int current) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i < current;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? ShunShiColors.primary : ShunShiColors.borderGhost,
          ),
        );
      }),
    );
  }

  _GuideData _getGuide(String step) {
    final h = DateTime.now().hour;
    switch (step) {
      // === 早起场景 ===
      case 'morning_wake':
        if (h >= 5 && h < 9) {
          return _GuideData(
            icon: Icons.water_drop_outlined,
            title: '一杯温水，开启养阳第一步',
            subtitle: '饮水提醒 → 完成今日第一个行动',
            color: const Color(0xFF43A047),
            stepNum: 1,
          );
        }
        return _defaultGuide();
      // === 早餐场景 ===
      case 'morning_breakfast':
        if (h >= 7 && h < 10) {
          return _GuideData(
            icon: Icons.restaurant_outlined,
            title: '辰时胃经旺，清淡早餐养脾胃',
            subtitle: '查看时令食谱 →',
            color: const Color(0xFFFF8A65),
            stepNum: 2,
          );
        }
        return _defaultGuide();
      // === 午间场景 ===
      case 'noon_rest':
        if (h >= 11 && h < 14) {
          return _GuideData(
            icon: Icons.self_improvement_outlined,
            title: '午时心经旺，小憩15分钟养心',
            subtitle: '冥想导引 →',
            color: const Color(0xFFEC407A),
            stepNum: 2,
          );
        }
        return _defaultGuide();
      // === 下午场景 ===
      case 'afternoon':
        if (h >= 14 && h < 18) {
          return _GuideData(
            icon: Icons.water_drop_outlined,
            title: '申时膀胱经当令，多喝水排毒',
            subtitle: '记录饮水 →',
            color: const Color(0xFF29B6F6),
            stepNum: 2,
          );
        }
        return _defaultGuide();
      // === 傍晚场景 ===
      case 'evening_wind_down':
        if (h >= 18 && h < 22) {
          return _GuideData(
            icon: Icons.directions_walk_outlined,
            title: '戌时心包经，散步放松身心',
            subtitle: '去走一走 →',
            color: const Color(0xFFAB47BC),
            stepNum: 3,
          );
        }
        return _defaultGuide();
      // === 夜间场景 ===
      case 'night_sleep':
        if (h >= 21 || h < 5) {
          return _GuideData(
            icon: Icons.bedtime_outlined,
            title: '亥时三焦经，早睡养阴',
            subtitle: '睡前记录 →',
            color: const Color(0xFF5C6BC0),
            stepNum: 3,
          );
        }
        return _defaultGuide();
      // === 默认 ===
      default:
        return _defaultGuide();
    }
  }

  _GuideData _defaultGuide() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) {
      return _GuideData(
        icon: Icons.auto_awesome_outlined,
        title: '开始今天的第一个行动',
        subtitle: '节气养生，从清晨开始',
        color: ShunShiColors.primary,
        stepNum: 1,
      );
    }
    if (h >= 9 && h < 14) {
      return _GuideData(
        icon: Icons.wb_sunny_outlined,
        title: '今日养生进行中',
        subtitle: '查看今日推荐 →',
        color: const Color(0xFFFF8A65),
        stepNum: 2,
      );
    }
    if (h >= 14 && h < 22) {
      return _GuideData(
        icon: Icons.eco_outlined,
        title: '下午时光，养生不间断',
        subtitle: '继续今日计划 →',
        color: const Color(0xFF29B6F6),
        stepNum: 2,
      );
    }
    return _GuideData(
      icon: Icons.nightlight_outlined,
      title: '养阴时刻，准备安睡',
      subtitle: '睡前记录 →',
      color: const Color(0xFF5C6BC0),
      stepNum: 3,
    );
  }
}

class _GuideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int stepNum;

  _GuideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.stepNum,
  });
}
