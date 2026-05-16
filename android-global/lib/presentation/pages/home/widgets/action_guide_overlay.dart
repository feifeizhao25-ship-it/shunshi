import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../../../core/theme/app_localizations.dart';
import '../../../../core/network/api_singleton.dart';

/// 行动引导断点 — 3-5-10秒法则的核Heart组件
///
/// 场景：
/// - User opens app → sees "What is the most important action today?"
/// - Done行动后 → 看到下一个行动指引（断点）
/// - 没有行动时 → 看到默认引导
///
/// 视觉：半透明渐变卡片，带步骤指示器，引导Next
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
    final guide = _getGuide(context, step);

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

  _GuideData _getGuide(BuildContext context, String step) {
    final h = DateTime.now().hour;
    switch (step) {
      // === 早起场景 ===
      case 'morning_wake':
        if (h >= 5 && h < 9) {
          return _GuideData(
            icon: Icons.water_drop_outlined,
            title: AppLocalizations.of(context).t('home_a_glass_of_warm_water_the_first_step_to_nouri'),
            subtitle: AppLocalizations.of(context).t('home_water_reminder_complete_your_first_action_tod'),
            color: const Color(0xFF43A047),
            stepNum: 1,
          );
        }
        return _defaultGuide(context);
      // === 早餐场景 ===
      case 'morning_breakfast':
        if (h >= 7 && h < 10) {
          return _GuideData(
            icon: Icons.restaurant_outlined,
            title: 'Chen (7-9) Stomach is active — a light breakfast nourishes the Spleen-Stomach',
            subtitle: AppLocalizations.of(context).t('home_view_seasonal_recipes'),
            color: const Color(0xFFFF8A65),
            stepNum: 2,
          );
        }
        return _defaultGuide(context);
      // === Wu间场景 ===
      case 'noon_rest':
        if (h >= 11 && h < 14) {
          return _GuideData(
            icon: Icons.self_improvement_outlined,
            title: 'Wu (11-13) Heart is active — rest for 15 min to nourish the Heart',
            subtitle: AppLocalizations.of(context).t('home_meditationqigong'),
            color: const Color(0xFFEC407A),
            stepNum: 2,
          );
        }
        return _defaultGuide(context);
      // === 下Wu场景 ===
      case 'afternoon':
        if (h >= 14 && h < 18) {
          return _GuideData(
            icon: Icons.water_drop_outlined,
            title: 'Shen (15-17) Bladder is active — drink more water to detoxify',
            subtitle: AppLocalizations.of(context).t('home_log_water_intake'),
            color: const Color(0xFF29B6F6),
            stepNum: 2,
          );
        }
        return _defaultGuide(context);
      // === 傍晚场景 ===
      case 'evening_wind_down':
        if (h >= 18 && h < 22) {
          return _GuideData(
            icon: Icons.directions_walk_outlined,
            title: AppLocalizations.of(context).t('home_xu_1921_pericardium_take_a_walk_to_relax_body'),
            subtitle: AppLocalizations.of(context).t('home_take_a_walk'),
            color: const Color(0xFFAB47BC),
            stepNum: 3,
          );
        }
        return _defaultGuide(context);
      // === 夜间场景 ===
      case 'night_sleep':
        if (h >= 21 || h < 5) {
          return _GuideData(
            icon: Icons.bedtime_outlined,
            title: AppLocalizations.of(context).t('home_hai_2123_triple_burner_sleep_early_to_nourish'),
            subtitle: AppLocalizations.of(context).t('home_presleep_log'),
            color: const Color(0xFF5C6BC0),
            stepNum: 3,
          );
        }
        return _defaultGuide(context);
      // === 默认 ===
      default:
        return _defaultGuide(context);
    }
  }

  _GuideData _defaultGuide(BuildContext context) {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) {
      return _GuideData(
        icon: Icons.auto_awesome_outlined,
        title: AppLocalizations.of(context).t('home_start_your_first_action_today'),
        subtitle: AppLocalizations.of(context).t('home_solar_term_wellness_starts_from_morning'),
        color: ShunShiColors.primary,
        stepNum: 1,
      );
    }
    if (h >= 9 && h < 14) {
      return _GuideData(
        icon: Icons.wb_sunny_outlined,
        title: AppLocalizations.of(context).t('action_guide_overlay_todays_wellness_in_progress'),
        subtitle: "View Today's Pick \u2192",
        color: const Color(0xFFFF8A65),
        stepNum: 2,
      );
    }
    if (h >= 14 && h < 22) {
      return _GuideData(
        icon: Icons.eco_outlined,
        title: AppLocalizations.of(context).t('home_afternoon_wu_1113_wellness_continues'),
        subtitle: "Continue Today's Plan \u2192",
        color: const Color(0xFF29B6F6),
        stepNum: 2,
      );
    }
    return _GuideData(
      icon: Icons.nightlight_outlined,
      title: AppLocalizations.of(context).t('home_time_to_nourish_yin_prepare_for_sleep'),
      subtitle: 'Pre-Sleep Log →',
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
