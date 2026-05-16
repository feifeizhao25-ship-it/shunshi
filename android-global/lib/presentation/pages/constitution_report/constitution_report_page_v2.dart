/// Body Type Quiz报告页 — 参考UI _9
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class ConstitutionReportPageV2 extends StatelessWidget {
  const ConstitutionReportPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).t('constitution_report'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report title
            Text(AppLocalizations.of(context).t('constitutionrep_constitution_report_spring_equinox_2024'), style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            const SizedBox(height: 16),

            // Body Type结果
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).t('constitutionrep_your_constitution_qi_deficient_with_phlegmdam'), style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    _buildTag('Boost Qi', Color(0xFFE4C285)),
                    _buildTag('Eliminate Dampness', Color(0xFFE4C285)),
                    _buildTag('Avoid Cold', Color(0xFFE4C285)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Constitution strength distribution
            Text(AppLocalizations.of(context).t('constitutionrep_constitution_scores'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            _buildBar('Qi Deficient', 0.85, ShunShiColors.primary),
            _buildBar('Phlegm-Damp', 0.62, Color(0xFF74593C)),
            _buildBar('Yang Deficient', 0.45, Color(0xFF9BB8C9)),
            _buildBar('Balanced (Reference)', 0.30, ShunShiColors.textTertiary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info, size: 16, color: ShunShiColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(child: Text('Results based on recent physical and mental state. Constitution is influenced by environment and season; reassessment every 24 solar terms is recommended.',
                  style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 20),

            // AIWellness总评
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ShunShiColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ShunShiColors.primary.withOpacity(0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.auto_awesome, color: ShunShiColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).t('constitutionrep_ai_wellness_rating'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                ]),
                const SizedBox(height: 12),
                Text(
                  'In spring, your Qi Deficient traits manifest as fatigue and weakness—like seedlings needing gentle care in spring rain. Combined with Phlegm-Damp, fluid metabolism is sluggish. Focus on warming and strengthening the spleen, with phlegm-damp resolution. Remember, early sleep and light diet are the best brushstrokes for your life\'s canvas.',
                  style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Personalized wellness plan
            Text(AppLocalizations.of(context).t('constitutionrep_personalized_wellness_plan'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),

            // recommended Recipes
            _buildPlanCard(Icons.restaurant, 'Recommended Recipe', 'Astragalus Chicken Soup', 'Boosts Qi, strengthens exterior, warms the middle and supplements deficiency. Suitable for Qi Deficient types.', 'Start Cooking'),
            const SizedBox(height: 10),
            // recommended Acupressure
            _buildPlanCard(Icons.spa, 'Recommended Acupoint', 'Zusanli · Tonifies Spleen & Stomach', '', 'View'),
            const SizedBox(height: 10),
            // recommended Qigong
            _buildPlanCard(Icons.self_improvement, 'Recommended Practice', 'Baduanjin · Regulates Spleen & Stomach', '', 'View'),
            const SizedBox(height: 16),

            // Quote
            Center(child: Text(AppLocalizations.of(context).t('constitutionrep_rest_the_body_move_the_qi'), style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 14, fontStyle: FontStyle.italic, color: ShunShiColors.textTertiary,
            ))),
            const SizedBox(height: 16),

            // 生成th历按钮
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ShunShiColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(AppLocalizations.of(context).t('constitutionrep_generate_detailed_calendar'), style: TextStyle(color: ShunShiColors.primary, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, backgroundColor: ShunShiColors.surfaceContainerLow, color: color, minHeight: 8),
        )),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildPlanCard(IconData icon, String category, String title, String desc, String action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: ShunShiColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.4)),
        ])),
        Text(action, style: TextStyle(fontSize: 12, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
        Icon(Icons.arrow_forward, size: 14, color: ShunShiColors.primary),
      ]),
    );
  }
}
