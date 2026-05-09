import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../widgets/paywall_banner.dart';
import '../../../core/theme/app_localizations.dart';

/// Body Type Quiz结果页
class ConstitutionTestPage extends StatelessWidget {
  final String? constitutionType;
  const ConstitutionTestPage({super.key, this.constitutionType});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('solar_constitution_test_result'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => safePop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Body Type类型卡片 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ShunShiColors.primary, Color(0xFF2D5A3D)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.spa, size: 48, color: Colors.white70),
                  const SizedBox(height: 12),
                  Text(constitutionType ?? 'Qi Deficient', style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                  )),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).t('constitution_your_constitution_type'), style: TextStyle(fontSize: 13, color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Body Type Traits ──
            _sectionTitle('Constitution Traits'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
              child: const Text(
                'Qi Deficient types often experience fatigue, weakness, shortness of breath, reluctance to speak, easy sweating, and pale complexion. '
                'They have weaker resistance, catch colds easily, and recover slowly. The tongue is pale with a white coating, and the pulse is weak.',
                style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.7),
              ),
            ),
            const SizedBox(height: 24),

            // ── Upgrade提示 Banner ──
            const PaywallBanner(
              message: 'Unlock Detailed Analysis',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 20),

            // ── Wellness Advice ──
            _sectionTitle('Wellness Recommendations'),
            const SizedBox(height: 12),
            _adviceCard('Diet', 'Eat Qi-boosting foods: yam, astragalus, jujube, millet porridge. Avoid raw and cold items.', Icons.restaurant, ShunShiColors.primary),
            const SizedBox(height: 12),
            _adviceCard('Exercise', 'Gentle exercises recommended: walking, Tai Chi, Baduanjin. Avoid intense exercise that depletes Qi.', Icons.self_improvement, ShunShiColors.secondary),
            const SizedBox(height: 12),
            _adviceCard('Daily Care', 'Ensure adequate sleep and avoid overexertion. A midday nap helps replenish Qi.', Icons.bedtime, ShunShiColors.blue),
            const SizedBox(height: 32),

            // ── 按钮 ──
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('solar_share_link_copied')), duration: Duration(seconds: 1))); },
                icon: const Icon(Icons.share, size: 18),
                label: Text(AppLocalizations.of(context).t('solar_share_result')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ShunShiColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(AppLocalizations.of(context).t('constitution_retake'))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
  );

  Widget _adviceCard(String title, String desc, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color, fontFamily: ShunShiTypography.serifFamily)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
