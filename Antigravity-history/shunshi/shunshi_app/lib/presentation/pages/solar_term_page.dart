import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// 节气数据
class SolarTermInfo {
  final String name;
  final String date;
  final String greeting;
  final String tip;
  final String element;
  final Color color;

  const SolarTermInfo({
    required this.name,
    required this.date,
    required this.greeting,
    required this.tip,
    required this.element,
    required this.color,
  });
}

class SolarTermPage extends StatelessWidget {
  const SolarTermPage({super.key});

  // 当期节气（实际项目中从服务端获取）
  static const _currentTerm = SolarTermInfo(
    name: '惊蛰',
    date: '2026年3月6日',
    greeting: '春雷乍动，万物复苏',
    tip: '惊蛰时节，阳气生发，宜早睡早起，多食甘味食物以护脾胃。',
    element: '木',
    color: AppColors.secondary,
  );

  static const _weeklyGuide = [
    _DayGuide(day: '第1天', focus: '调肝护脾', detail: '饮食以甘为主，少食酸。'),
    _DayGuide(day: '第2天', focus: '晨练养阳', detail: '早晨7-9时散步，配合呼吸调节。'),
    _DayGuide(day: '第3天', focus: '穴位保健', detail: '按揉足三里，每侧2分钟。'),
    _DayGuide(day: '第4天', focus: '饮食调养', detail: '可食枸杞红枣粥，温阳补血。'),
    _DayGuide(day: '第5天', focus: '情志舒畅', detail: '避免忧郁，适当音乐放松。'),
    _DayGuide(day: '第6天', focus: '睡眠调整', detail: '22:30前入睡，养足肝气。'),
    _DayGuide(day: '第7天', focus: '回顾总结', detail: '感受一周的身体变化。'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: '节气'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current solar term card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _currentTerm.color,
                    _currentTerm.color.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: AppRadius.xlAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText.displayLarge(
                        _currentTerm.name,
                        color: AppColors.textOnDark,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: AppText.labelMedium(
                          '五行·${_currentTerm.element}',
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText.bodyMedium(
                    _currentTerm.date,
                    color: AppColors.textOnDark,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText.headlineSmall(
                    _currentTerm.greeting,
                    color: AppColors.textOnDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tip card
            AppCard.elevated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tips_and_updates_outlined,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: AppSpacing.xs),
                      AppText.labelMedium('节气养生提示', color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText.bodyLarge(_currentTerm.tip),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 7-day guide
            const AppText.titleLarge('七日养生游程'),
            const SizedBox(height: AppSpacing.md),
            ..._weeklyGuide.asMap().entries.map((entry) {
              final i = entry.key;
              final guide = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DayCard(guide: guide, index: i + 1),
              );
            }),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _DayGuide {
  final String day;
  final String focus;
  final String detail;

  const _DayGuide({
    required this.day,
    required this.focus,
    required this.detail,
  });
}

class _DayCard extends StatelessWidget {
  final _DayGuide guide;
  final int index;

  const _DayCard({required this.guide, required this.index});

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppText.labelMedium(
              '$index',
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(guide.focus),
                const SizedBox(height: AppSpacing.xs),
                AppText.bodySmall(guide.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
