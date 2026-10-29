/// Growth Milestones Page — Reference: growth_milestones
/// SEASONS Global achievement system
///
/// Structure:
/// 1. Total XP + Level
/// 2. Progress to next level
/// 3. Unlocked milestones (cards)
/// 4. Locked milestones
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class GrowthMilestonesPage extends StatelessWidget {
  const GrowthMilestonesPage({super.key});

  static const _milestones = [
    _Milestone('🌅', '早起', '连续 7 天在 6 点前起床', false, 0, Color(0xFFF59E0B)),
    _Milestone('🌿', '节气', '完成一次节气练习', false, 0, Color(0xFF22C55E)),
    _Milestone('🧘', '静心', '连续 30 天做一段静坐', false, 0, Color(0xFF8B5CF6)),
    _Milestone('🍵', '时令茶', '喝过 10 种应季茶饮', false, 0, Color(0xFF06B6D4)),
    _Milestone('📖', '百日养生', '坚持养生练习100天', false, 500, null),
    _Milestone('🌍', '节气守护', '完成所有节气挑战', false, 800, null),
    _Milestone('🔥', '八段锦', '练完八段锦的八式', false, 0, null),
    _Milestone('✨', '全部完成', '完成上面每一项', false, 0, null),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    final unlocked = _milestones.where((m) => m.unlocked).toList();
    final locked = _milestones.where((m) => !m.unlocked).toList();
    final totalXp = unlocked.fold<int>(0, (sum, m) => sum + m.xp);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('成长里程碑', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.textPrimary,
        )),
        backgroundColor: bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '完成打卡以后，这里才会记下你做到的事',
              style: TextStyle(
                fontSize: 14, color: ShunShiColors.textSecondary,
                fontFamily: ShunShiTypography.sansFamily,
              ),
            ),
            const SizedBox(height: 24),

            // ── XP Overview ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShunShiColors.primary.withValues(alpha: 0.12),
                    ShunShiColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '$totalXp',
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w700,
                      color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.serifFamily,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '练习记录',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '完成后才会记在这里',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '目前没有打卡记录，不显示分数',
                    style: TextStyle(
                      fontSize: 12, color: ShunShiColors.textTertiary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: ShunShiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: totalXp / 2000,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Unlocked ──
            Text('已解锁', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 4),
            Text('已完成 ${unlocked.length} / ${_milestones.length}', style: TextStyle(
              fontSize: 13, color: ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 16),
            ...unlocked.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _milestoneCard(m),
            )),
            const SizedBox(height: 24),

            // ── Locked ──
            Text('前路漫漫', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 16),
            ...locked.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _lockedCard(m),
            )),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _milestoneCard(_Milestone m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: (m.color ?? ShunShiColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(m.icon, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 2),
            Text(m.desc, style: TextStyle(
              fontSize: 12, color: ShunShiColors.textSecondary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (m.color ?? ShunShiColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('+${m.xp}', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: m.color ?? ShunShiColors.primary,
            fontFamily: ShunShiTypography.sansFamily,
          )),
        ),
      ]),
    );
  }

  Widget _lockedCard(_Milestone m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: ShunShiColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(m.icon, style: TextStyle(
            fontSize: 24, color: ShunShiColors.textTertiary.withValues(alpha: 0.4),
          ))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 2),
            Text(m.desc, style: TextStyle(
              fontSize: 12, color: ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
          ]),
        ),
        Text('未开始', style: TextStyle(
          fontSize: 12, color: ShunShiColors.textTertiary,
          fontFamily: ShunShiTypography.sansFamily,
        )),
      ]),
    );
  }
}

class _Milestone {
  final String icon;
  final String title;
  final String desc;
  final bool unlocked;
  final int xp;
  final Color? color;
  const _Milestone(this.icon, this.title, this.desc, this.unlocked, this.xp, this.color);
}
