/// Growth Milestones — 参考 growth_milestones
/// XP + badges + streak
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class GrowthMilestonesV2 extends StatelessWidget {
  const GrowthMilestonesV2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                const Icon(Icons.menu, color: Color(0xFF533afd)),
                const Spacer(),
                Text(AppLocalizations.of(context).t('checkin_sanctuary'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
            ),
          )),

          // Title
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).t('growth_your_growth_journey'), style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 8),
              Text('Reflect on the quiet moments of consistency. Each ritual is a seed planted in the garden of your well-being.',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
            ]),
          )),

          // Current Season Card
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).t('growth_current_season'), style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).t('growth_spring_equinox_alignment'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text("You've greeted the sunrise for 12 consecutive days. Your inner landscape is beginning to bloom with clarity.",
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: 0.85, backgroundColor: Colors.white24, color: Color(0xFFE4C285), minHeight: 6),
                ),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).t('growth_85_towards_harvest'), style: TextStyle(fontSize: 11, color: Color(0xFFE4C285))),
              ]),
            ),
          )),

          // Stats
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              _buildStatBox(Icons.wb_sunny, '07', 'Days of Morning Light'),
            ]),
          )),

          // Milestones
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).t('growth_reflective_milestones'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              Text(AppLocalizations.of(context).t('growth_gently_nurtured_achievements'), style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
              const SizedBox(height: 12),
              _buildMilestone(Icons.local_florist, 'First Sprout', 'Ritual streak: 3 days', true, Color(0xFF4CAF50)),
              _buildMilestone(Icons.forest, 'Deep Roots', 'Complete a seasonal cycle', false, null),
              _buildMilestone(Icons.wb_sunny, 'Solar Devotee', '30 morning rituals', false, null),
              _buildMilestone(Icons.water_drop, 'Rain Dancer', 'Practice in every weather', false, null),
              _buildMilestone(Icons.auto_awesome, 'Equinox Aligned', 'Balance all 4 pillars', false, null),
            ]),
          )),

          const SliverToBoxAlternate(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: Color(0xFF533afd), size: 24),
        const SizedBox(width: 12),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildMilestone(IconData icon, String title, String desc, bool unlocked, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: unlocked && color != null ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: unlocked ? (color ?? Color(0xFF533afd)).withOpacity(0.1) : ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: unlocked
              ? Icon(Icons.check, color: color ?? Color(0xFF533afd), size: 20)
              : Icon(Icons.lock_outline, color: ShunShiColors.textTertiary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: unlocked ? ShunShiColors.textPrimary : ShunShiColors.textTertiary)),
            Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          ])),
        ]),
      ),
    );
  }
}

class SliverToBoxAlternate extends SliverToBoxAdapter {
  const SliverToBoxAlternate({super.key, required Widget child}) : super(child: child);
}
