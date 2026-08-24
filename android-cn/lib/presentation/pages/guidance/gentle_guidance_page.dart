/// Gentle Guidance Page — Reference: gentle_guidance
/// Daily whispers tailored to season & constitution
///
/// Structure:
/// 1. Header
/// 2. Timeline cards (Morning Ritual / Seasonal Tip / Body Type Insight)
/// 3. Personalized for cycle note
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class GentleGuidancePage extends StatelessWidget {
  const GentleGuidancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('温柔指引', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('每日轻语', style: TextStyle(
              fontSize: 13, color: ShunShiColors.textSecondary,
              fontFamily: ShunShiTypography.sansFamily, letterSpacing: 0.5,
            )),
            const SizedBox(height: 8),
            Text(
              'A rhythm of reminders tailored to your current season and constitution.',
              style: TextStyle(
                fontSize: 15, color: ShunShiColors.textSecondary,
                height: 1.6, fontFamily: ShunShiTypography.sansFamily,
              ),
            ),
            const SizedBox(height: 24),

            // ── Morning Ritual ──
            _guidanceCard(
              context: context,
              icon: Icons.light_mode,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              title: '晨间仪式',
              time: 'Just now',
              description: 'A 5-minute sun-gazing practice to align your circadian rhythm with the early spring light.',
              cta: 'Begin Practice',
            ),
            const SizedBox(height: 16),

            // ── Seasonal Tip ──
            _guidanceCard(
              context: context,
              icon: Icons.restaurant_menu,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
              title: '节气小贴士',
              time: '2h ago',
              description: 'Time for bitter greens. Dandelion and arugula will support your liver\'s natural detoxification this afternoon.',
              cta: null,
            ),
            const SizedBox(height: 16),

            // ── Body Type Insight ──
            _guidanceCard(
              context: context,
              icon: Icons.monitor_heart_outlined,
              iconColor: ShunShiColors.primary,
              iconBg: ShunShiColors.primary.withValues(alpha: 0.1),
              title: '风火型体质平衡',
              time: 'Body Type Insight',
              description: 'Your energy might dip this afternoon around 3:00 PM. Consider a warm, spiced tea instead of caffeine to stay grounded.',
              cta: 'Deepen Insight',
            ),
            const SizedBox(height: 16),

            // ── Personalized note ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.auto_awesome, size: 18, color: ShunShiColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('为你当前的周期定制', style: TextStyle(
                    fontSize: 13, fontStyle: FontStyle.italic,
                    color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
                  )),
                ),
              ]),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _guidanceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String time,
    required String description,
    String? cta,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                )),
                Text(time, style: TextStyle(
                  fontSize: 12, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
                )),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(
            fontSize: 14, color: ShunShiColors.textSecondary,
            height: 1.7, fontFamily: ShunShiTypography.sansFamily,
          )),
          if (cta != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () { Navigator.of(context).pop(); },
              child: Text(cta, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
              )),
            ),
          ],
        ],
      ),
    );
  }
}
