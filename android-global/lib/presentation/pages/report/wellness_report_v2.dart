/// Wellness Report — 参考 wellness_report
/// 4维度健康报告 + 季节焦点
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

class WellnessReportV2 extends StatelessWidget {
  const WellnessReportV2({super.key});

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
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                const Spacer(),
                Text('SEASONS', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
            ),
          )),

          // Title
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).t('wellness_report'), style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).t('report_spring_equinox_week_3'), style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            ]),
          )),

          // 4 Dimensions
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2,
              children: [
                _buildDimCard(Icons.bedtime, 'Sleep', '82%', Color(0xFF533afd), 'Deep rest improving'),
                _buildDimCard(Icons.restaurant, 'Nourish', '75%', Color(0xFF4CAF50), 'Good seasonal alignment'),
                _buildDimCard(Icons.self_improvement, 'Movement', '60%', Color(0xFFFF9800), 'Room for growth'),
                _buildDimCard(Icons.auto_awesome, 'Mind', '88%', Color(0xFF9C27B0), 'Strong clarity this week'),
              ],
            ),
          )),

          // Season Focus
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.eco, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).t('report_season_focus'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
                const SizedBox(height: 8),
                Text('Spring is asking you to lighten. Your report shows strong mental clarity paired with room to expand physical movement. Consider adding 10 minutes of morning stretching.',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
              ]),
            ),
          )),

          // Recommendation
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).t('report_personalized_recommendation'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 10),
              _buildRecCard(Icons.self_improvement, 'Morning Hip Flow', '10 min · Beginner', Color(0xFF533afd)),
              _buildRecCard(Icons.emoji_food_beverage, 'Dandelion Root Tea', 'Liver support · Spring', Color(0xFF4CAF50)),
              _buildRecCard(Icons.bedtime, 'Wind-down Journal', 'Evening reflection', Color(0xFF9C27B0)),
            ]),
          )),

          const SliverToBoxAlternate(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildDimCard(IconData icon, String title, String value, Color color, String note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ShunShiColors.textSecondary)),
        Text(note, style: TextStyle(fontSize: 10, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildRecCard(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          ])),
          Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
        ]),
      ),
    );
  }
}

class SliverToBoxAlternate extends SliverToBoxAdapter {
  const SliverToBoxAlternate({super.key, required Widget child}) : super(child: child);
}
