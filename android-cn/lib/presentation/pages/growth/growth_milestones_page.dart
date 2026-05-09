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
    _Milestone('🌅', 'Early Riser', 'Wake before 6 AM for 7 days', true, 120, Color(0xFFF59E0B)),
    _Milestone('🌿', 'Seasonal Seeker', 'Complete your first seasonal ritual', true, 200, Color(0xFF22C55E)),
    _Milestone('🧘', 'Still Mind', 'Meditate for 30 consecutive days', true, 350, Color(0xFF8B5CF6)),
    _Milestone('🍵', 'Tea Ceremony', 'Brew 10 different seasonal teas', true, 180, Color(0xFF06B6D4)),
    _Milestone('📖', '100 Day Journey', 'Practice wellness for 100 days', false, 500, null),
    _Milestone('🌍', 'Earth Guardian', 'Complete all seasonal challenges', false, 800, null),
    _Milestone('🔥', 'Inner Fire', 'Master all 8 movements of Ba Duan Jin', false, 600, null),
    _Milestone('✨', 'Sovereign', 'Unlock all other milestones', false, 1000, null),
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
        title: Text('Growth Milestones', style: TextStyle(
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
              'Your journey of mindful growth',
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
                    'Experience Points',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Level: Mindful Seeker',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Next: Inner Sage — 570 XP remaining',
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
            Text('Unlocked', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 4),
            Text('${unlocked.length} / ${_milestones.length} milestones', style: TextStyle(
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
            Text('Journey Ahead', style: TextStyle(
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
        Text('${m.xp} XP', style: TextStyle(
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
