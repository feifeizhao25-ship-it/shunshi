/// Body Type Essence — 参考 body_type_essence
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class BodyTypeEssenceV2 extends StatelessWidget {
  const BodyTypeEssenceV2({super.key});

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
                Text('SEASONS', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                const Spacer(),
                Icon(Icons.settings, color: ShunShiColors.textTertiary),
              ]),
            ),
          )),

          // Title
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).t('bodytype_your_essence'), style: TextStyle(fontSize: 12, color: Color(0xFF533afd), fontWeight: FontWeight.w500, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).t('bodytype_your_seasonal_essence_balanced'), style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 8),
              Text('Your constitution mirrors the transition between Spring and Autumn. You possess a resilient core with a fluid adaptability to external shifts.',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
            ]),
          )),

          // 6 Metrics
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: GridView.count(
              crossAxisCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0,
              children: [
                _buildMetric(Icons.filter_vintage, 'Vitality', 0.78, Color(0xFF533afd)),
                _buildMetric(Icons.favorite, 'Circulation', 0.65, Colors.red),
                _buildMetric(Icons.restaurant, 'Digestion', 0.82, Color(0xFF4CAF50)),
                _buildMetric(Icons.shield, 'Resilience', 0.90, Color(0xFFFF9800)),
                _buildMetric(Icons.speed, 'Metabolism', 0.55, Color(0xFF2196F3)),
                _buildMetric(Icons.bedtime, 'Sleep Quality', 0.70, Color(0xFF9C27B0)),
              ],
            ),
          )),

          // "Harmony in Flux"
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).t('bodytype_harmony_in_flux'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                _buildElementRow(Icons.wb_sunny, 'Solar Dominance', 'Your energy peaks with the rising sun. Morning rituals are your strongest foundation.'),
                const SizedBox(height: 12),
                _buildElementRow(Icons.spa, 'Terrene Stability', 'Grounded and deliberate. Your body recovers best through stillness and earthy textures.'),
              ]),
            ),
          )),

          // Natural Rhythm
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Text(AppLocalizations.of(context).t('bodytype_your_natural_rhythm'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          )),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          const SizedBox(height: 4),
          Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildElementRow(IconData icon, String title, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(desc, style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.4)),
      ])),
    ]);
  }
}

class SliverToBoxAlternate extends SliverToBoxAdapter {
  const SliverToBoxAlternate({super.key, required Widget child}) : super(child: child);
}
