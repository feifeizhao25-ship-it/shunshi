/// Wellness Report Page — Reference: wellness_report
/// SEASONS Global personal assessment
///
/// Structure:
/// 1. Assessment header
/// 2. 4 metric bars (Energy/Sleep/Digestion/Balance)
/// 3. Seasonal Focus card
/// 4. Recommendation card
/// 5. CTA
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_singleton.dart';

class WellnessReportPage extends StatelessWidget {
  const WellnessReportPage({super.key});

  static const _metrics = [
    _WellnessMetric('Energy', 0.85, Color(0xFFF59E0B)),
    _WellnessMetric('Sleep', 0.72, Color(0xFF8B5CF6)),
    _WellnessMetric('Digestion', 0.94, Color(0xFF22C55E)),
    _WellnessMetric('Balance', 0.88, Color(0xFF3B82F6)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: ShunShiColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ShunShiColors.primary, ShunShiColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).t('wellness_report'), style: TextStyle(
                          fontSize: 13, color: Colors.white70,
                          fontFamily: ShunShiTypography.sansFamily, letterSpacing: 1.5,
                        )),
                        const SizedBox(height: 10),
                        Text(AppLocalizations.of(context).t('report_personal_assessment'), style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700,
                          color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary ──
                  Text(
                    'Your Rhythm: Balanced & Vibrant.',
                    style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are naturally centered with good energy. In Late Spring, your focus is on maintaining this vitality through seasonal liver support.',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      height: 1.7, fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Metrics ──
                  ..._metrics.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _metricRow(m),
                  )),
                  const SizedBox(height: 8),

                  // ── Seasonal Focus ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ShunShiColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ShunShiColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.eco, size: 22, color: ShunShiColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).t('report_late_spring_focus'), style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600,
                                color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                              )),
                              const SizedBox(height: 6),
                              Text(
                                'Liver meridian activation is crucial as the yang energy peaks. Focus on bitter greens and gentle stretching.',
                                style: TextStyle(
                                  fontSize: 13, color: ShunShiColors.textSecondary,
                                  height: 1.6, fontFamily: ShunShiTypography.sansFamily,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => context.push('/wellness-category/diet'),
                                child: Row(children: [
                                  Text(AppLocalizations.of(context).t('learn_more'), style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
                                  )),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 16, color: ShunShiColors.primary),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Recommendation ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.light_mode, size: 22, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).t('report_recommended'), style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600,
                                color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                              )),
                              Text(AppLocalizations.of(context).t('report_morning_sunlight'), style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500,
                                color: const Color(0xFFF59E0B), fontFamily: ShunShiTypography.sansFamily,
                              )),
                              const SizedBox(height: 6),
                              Text(
                                'Exposure to morning light for 15 minutes will further stabilize your emotional balance scores.',
                                style: TextStyle(
                                  fontSize: 13, color: ShunShiColors.textSecondary,
                                  height: 1.6, fontFamily: ShunShiTypography.sansFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShunShiColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context).t('report_explore_your_late_spring_plan'), style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                      )),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(AppLocalizations.of(context).t('report_revised_may_12_2024'), style: TextStyle(
                      fontSize: 12, color: ShunShiColors.textTertiary,
                      fontFamily: ShunShiTypography.sansFamily,
                    )),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(_WellnessMetric m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(m.name, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily,
          )),
          const Spacer(),
          Text('${(m.value * 100).round()}%', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: m.color, fontFamily: ShunShiTypography.sansFamily,
          )),
        ]),
        const SizedBox(height: 6),
        Stack(children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: m.value,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: m.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _WellnessMetric {
  final String name;
  final double value;
  final Color color;
  const _WellnessMetric(this.name, this.value, this.color);
}
