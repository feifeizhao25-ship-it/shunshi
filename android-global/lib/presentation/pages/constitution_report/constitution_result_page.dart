/// Body Type Quiz结果页 — 对齐UI参考 _9
/// TopBar(头像+ShunShi AI+通知) → 标题+标签 → Constitution Strength(进度条) → AI调养总评(毛玻璃) → Personalized Care Plan → 底部CTA
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_singleton.dart';

class ConstitutionResultPage extends StatelessWidget {
  final String constitutionType;
  final Map<String, double>? scores;

  const ConstitutionResultPage({
    super.key,
    this.constitutionType = 'Qi Deficiency (with Phlegm-Dampness)',
    this.scores,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final seasonLabel = _getSeasonLabel(now.month);

    return Scaffold(


      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── TopAppBar ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ShunShiColors.surfaceVariant,
                      ),
                      child: Icon(Icons.person, size: 20, color: ShunShiColors.textSecondary),
                    ),
                    SizedBox(width: 12),
                    Text(AppLocalizations.of(context).t('profile_brand'), style: TextStyle(
                      fontSize: 20, fontStyle: FontStyle.italic,
                      fontFamily: ShunShiTypography.serifFamily,
                      color: ShunShiColors.primary,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Icon(Icons.notifications_outlined, size: 22, color: ShunShiColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: ShunShiColors.surfaceContainerLow, margin: const EdgeInsets.symmetric(horizontal: 20)),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Text('Constitution Report · ${now.year} $seasonLabel', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: ShunShiColors.secondary, letterSpacing: 2,
                  )),
                  SizedBox(height: 12),
                  Text(AppLocalizations.of(context).t('constitutionrep_your_constitution'), style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    fontFamily: ShunShiTypography.serifFamily,
                    color: ShunShiColors.primary, height: 1.3,
                  )),
                  Text(constitutionType, style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    fontFamily: ShunShiTypography.serifFamily,
                    color: ShunShiColors.primary, height: 1.3,
                  )),
                  SizedBox(height: 20),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      _tagChip('Tonify Qi', ShunShiColors.apricotLight),
                      _tagChip('Resolve Dampness', ShunShiColors.apricotLight),
                      _tagChip('Avoid Cold', ShunShiColors.primaryContainer),
                    ],
                  ),
                  SizedBox(height: 48),

                  // ── Constitution Strength ──
                  _buildDistributionSection(context),
                  SizedBox(height: 48),

                  // ── AI Wellness Summary ──
                  _buildAiReview(context),
                  SizedBox(height: 48),

                  // ── Personalized Care Plan ──
                  _buildSolutions(context),
                  SizedBox(height: 40),

                  // ── 底部 CTA ──
                  Center(
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context).t('constitutionrep_stillness_nourishes_the_body_movement_nourish'), style: TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic,
                          color: ShunShiColors.secondary,
                        )),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ShunShiColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(AppLocalizations.of(context).t('constitutionrep_generate_care_calendar'), style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              letterSpacing: 3, color: Colors.white,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSeasonLabel(int month) {
    if (month >= 3 && month <= 5) return 'Spring Equinox';
    if (month >= 6 && month <= 8) return 'Summer Solstice';
    if (month >= 9 && month <= 11) return 'Autumn Equinox';
    return 'Winter Solstice';
  }

  Widget _tagChip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: bgColor == ShunShiColors.primaryContainer
            ? ShunShiColors.primary
            : ShunShiColors.textPrimary,
      )),
    );
  }

  Widget _buildDistributionSection(BuildContext context) {
    final bars = [
      _BarData('Qi Deficiency', 0.85, ShunShiColors.primary),
      _BarData('Phlegm-Dampness', 0.62, ShunShiColors.primaryContainer),
      _BarData('Yang Deficiency', 0.45, ShunShiColors.surfaceVariant),
      _BarData('Balanced (baseline)', 0.30, ShunShiColors.textTertiary.withValues(alpha: 0.3)),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).t('constitutionrep_constitution_strength'), style: TextStyle(
            fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.primary,
          )),
          SizedBox(height: 24),
          ...bars.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.label, style: TextStyle(
                      fontSize: 12, color: ShunShiColors.secondary,
                    )),
                    Text('${(b.fraction * 100).toInt()}%', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: ShunShiColors.secondary,
                    )),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: b.fraction,
                    minHeight: 6,
                    backgroundColor: ShunShiColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(b.color),
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: 16),
          Container(height: 1, color: ShunShiColors.textTertiary.withValues(alpha: 0.2)),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: ShunShiColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Results reflect your recent state. Reassess each solar term.',
                  style: TextStyle(
                    fontSize: 11, height: 1.6,
                    color: ShunShiColors.secondary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiReview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: ShunShiColors.secondary),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).t('constitutionrep_ai_wellness_summary'), style: TextStyle(
                fontSize: 20, fontFamily: ShunShiTypography.serifFamily,
                color: ShunShiColors.primary,
              )),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'In spring, your Qi Deficiency shows as easy fatigue. Combined with Phlegm-Dampness, fluid metabolism is sluggish. Focus on warming Spleen Qi and resolving phlegm.',
            style: TextStyle(
              fontSize: 15, height: 2.0,
              color: ShunShiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context).t('constitutionrep_personalized_care_plan'), style: TextStyle(
              fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.primary,
            )),
            Text(AppLocalizations.of(context).t('view_all'), style: TextStyle(
              fontSize: 12, color: ShunShiColors.secondary,
              decoration: TextDecoration.underline,
              decorationColor: ShunShiColors.secondary.withValues(alpha: 0.3),
            )),
          ],
        ),
        SizedBox(height: 20),
        // Recipe card (full width)
        Container(
          decoration: BoxDecoration(
            color: ShunShiColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ShunShiShadows.sm,
          ),
          child: Row(
            children: [
              // Left image placeholder
              Container(
                width: 120, height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [ShunShiColors.apricotLight, ShunShiColors.apricot],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.soup_kitchen, size: 36, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              // Right content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).t('constitutionrep_recommended_recipe'), style: TextStyle(
                        fontSize: 10, letterSpacing: 2,
                        color: ShunShiColors.secondary,
                      )),
                      SizedBox(height: 6),
                      Text(AppLocalizations.of(context).t('constitutionrep_astragalus_chicken_soup'), style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        fontFamily: ShunShiTypography.serifFamily,
                        color: ShunShiColors.primary,
                      )),
                      SizedBox(height: 8),
                      Text(AppLocalizations.of(context).t('constitutionrep_tonifies_qi_and_warms_the_middleideal_for_qi_'), style: TextStyle(
                        fontSize: 12, color: ShunShiColors.textSecondary,
                      )),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/wellness-category/diet'),
                        child: Row(
                          children: [
                            Text(AppLocalizations.of(context).t('constitutionrep_start_cooking'), style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: ShunShiColors.primary,
                            )),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14, color: ShunShiColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        // Two column: acupoints + qigong
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 160,
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.spa, size: 28, color: ShunShiColors.primary),
                        SizedBox(height: 12),
                        Text(AppLocalizations.of(context).t('constitutionrep_recommended_acupoint'), style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        SizedBox(height: 6),
                        Text(AppLocalizations.of(context).t('constitutionrep_zusanli_st36_tonify_middle_jiao_qi'), style: TextStyle(
                          fontSize: 12, color: ShunShiColors.textSecondary,
                        )),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: ShunShiColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: ShunShiShadows.sm,
                        ),
                        child: Icon(Icons.play_arrow, size: 18, color: ShunShiColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 160,
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.self_improvement, size: 28, color: ShunShiColors.primary),
                        SizedBox(height: 12),
                        Text(AppLocalizations.of(context).t('constitutionrep_recommended_exercise'), style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        SizedBox(height: 6),
                        Text(AppLocalizations.of(context).t('constitutionrep_baduanjin_regulate_spleen_stomach'), style: TextStyle(
                          fontSize: 12, color: ShunShiColors.textSecondary,
                        )),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: ShunShiColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: ShunShiShadows.sm,
                        ),
                        child: Icon(Icons.play_arrow, size: 18, color: ShunShiColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BarData {
  final String label;
  final double fraction;
  final Color color;
  const _BarData(this.label, this.fraction, this.color);
}
