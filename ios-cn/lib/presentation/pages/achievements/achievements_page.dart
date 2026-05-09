import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('成就勋章', style: ShunShiTypography.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunShiSpacing.screenPadding,
          vertical: ShunShiSpacing.sm,
        ),
        children: [
          _buildStatsRow(),
          const SizedBox(height: ShunShiSpacing.xl),
          _buildProgressSection(),
          const SizedBox(height: ShunShiSpacing.xl),
          _sectionHeader('我的勋章'),
          _buildBadgeGrid(),
          const SizedBox(height: ShunShiSpacing.xl),
          _sectionHeader('近期成就'),
          ..._recentAchievements(),
          const SizedBox(height: ShunShiSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ShunShiSpacing.sm),
      child: Text(title, style: ShunShiTypography.labelLarge.copyWith(color: ShunShiColors.textSecondary)),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('累计打卡', '128', Icons.check_circle_outline),
        const SizedBox(width: ShunShiSpacing.sm),
        _statCard('养生天数', '96', Icons.eco_outlined),
        const SizedBox(width: ShunShiSpacing.sm),
        _statCard('获得勋章', '12', Icons.emoji_events_outlined),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: ShunShiSpacing.md, horizontal: ShunShiSpacing.sm),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: ShunShiRadius.cardRadius,
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: ShunShiColors.primary),
            const SizedBox(height: 6),
            Text(value, style: ShunShiTypography.headlineSmall),
            const SizedBox(height: 2),
            Text(label, style: ShunShiTypography.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(ShunShiSpacing.cardPadding),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('养生达人 Lv.5', style: ShunShiTypography.titleMedium),
              Text('Lv.6', style: ShunShiTypography.labelMedium),
            ],
          ),
          const SizedBox(height: ShunShiSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 8,
              backgroundColor: ShunShiColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(ShunShiColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text('还需 28 天升级至 Lv.6', style: ShunShiTypography.caption),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid() {
    final badges = [
      {'name': '早起鸟', 'icon': Icons.wb_sunny_outlined, 'earned': true},
      {'name': '茶道初窥', 'icon': Icons.local_cafe_outlined, 'earned': true},
      {'name': '节气守望', 'icon': Icons.nights_stay_outlined, 'earned': true},
      {'name': '百草辨识', 'icon': Icons.local_florist_outlined, 'earned': true},
      {'name': '太极入门', 'icon': Icons.self_improvement, 'earned': true},
      {'name': '食养家', 'icon': Icons.restaurant_outlined, 'earned': false},
      {'name': '四季行者', 'icon': Icons.hiking, 'earned': false},
      {'name': '经络达人', 'icon': Icons.healing_outlined, 'earned': false},
      {'name': '养生大师', 'icon': Icons.school_outlined, 'earned': false},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: ShunShiSpacing.sm,
        crossAxisSpacing: ShunShiSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final b = badges[index];
        final earned = b['earned'] as bool;
        return Container(
          decoration: BoxDecoration(
            color: earned
                ? ShunShiColors.primaryLight.withValues(alpha: 0.08)
                : ShunShiColors.surfaceContainerLow,
            borderRadius: ShunShiRadius.cardRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                b['icon'] as IconData,
                size: 32,
                color: earned ? ShunShiColors.primary : ShunShiColors.textDisabled,
              ),
              const SizedBox(height: 6),
              Text(
                b['name'] as String,
                style: ShunShiTypography.labelMedium.copyWith(
                  color: earned ? ShunShiColors.textPrimary : ShunShiColors.textDisabled,
                ),
              ),
              if (earned)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle, size: 14, color: ShunShiColors.success),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _recentAchievements() {
    final achievements = [
      {'title': '节气守望', 'desc': '连续记录 10 个节气变化', 'date': '2026-04-02', 'icon': Icons.nights_stay_outlined},
      {'title': '太极入门', 'desc': '完成 7 天太极晨练挑战', 'date': '2026-03-28', 'icon': Icons.self_improvement},
      {'title': '百草辨识', 'desc': '学习 30 种常见中草药', 'date': '2026-03-20', 'icon': Icons.local_florist_outlined},
    ];
    return achievements.map((a) {
      return Container(
        margin: const EdgeInsets.only(bottom: ShunShiSpacing.xs),
        padding: const EdgeInsets.all(ShunShiSpacing.md),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: ShunShiRadius.cardRadius,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ShunShiColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ShunShiRadius.sm),
              ),
              child: Icon(a['icon'] as IconData, size: 20, color: ShunShiColors.primary),
            ),
            const SizedBox(width: ShunShiSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'] as String, style: ShunShiTypography.titleMedium),
                  Text(a['desc'] as String, style: ShunShiTypography.caption),
                ],
              ),
            ),
            Text(a['date'] as String, style: ShunShiTypography.caption),
          ],
        ),
      );
    }).toList();
  }
}
