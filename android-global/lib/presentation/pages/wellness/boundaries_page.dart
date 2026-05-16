import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

/// 顺时边界公示页 — 清楚告知用户产品边界
class BoundariesPage extends StatelessWidget {
  const BoundariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
      appBar: AppBar(
        foregroundColor: ShunshiColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(AppLocalizations.of(context).t('wellness_product_boundaries')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShunshiColors.primary.withValues(alpha: 0.1),
                    ShunshiColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '🌿',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What SEASONS Is Not',
                    style: ShunshiTextStyles.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our product boundaries to keep you safe',
                    style: ShunshiTextStyles.body.copyWith(
                      color: ShunshiColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 顺时不提供
            _SectionTitle(
              emoji: '❌',
              title: AppLocalizations.of(context).t('wellness_seasons_does_not_provide'),
              subtitle: AppLocalizations.of(context).t('boundaries_the_following_are_outside_our'),
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🏥',
              title: AppLocalizations.of(context).t('wellness_medical_diagnosis'),
              description:
                  'We do not diagnose diseases. If you feel unwell, consult a doctor. AI cannot replace medical exams.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '💊',
              title: AppLocalizations.of(context).t('wellness_drug_recommendations'),
              description:
                  'We do not recommend any medications. Always use medication under medical supervision.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🩺',
              title: AppLocalizations.of(context).t('wellness_symptom_analysis'),
              description:
                  'We do not interpret abnormal lab results or speculate about possible diseases.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '📊',
              title: AppLocalizations.of(context).t('wellness_health_scores'),
              description:
                  'We do not score your health. Health is multi-dimensional and cannot be reduced to a number.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '😰',
              title: AppLocalizations.of(context).t('wellness_mood_scoring'),
              description:
                  'We do not judge your emotions. Every feeling deserves respect.',
              color: const Color(0xFFE57373),
            ),

            const SizedBox(height: 32),

            // 顺时提供
            _SectionTitle(
              emoji: '✅',
              title: AppLocalizations.of(context).t('wellness_what_seasons_provides'),
              subtitle: AppLocalizations.of(context).t('wellness_we_focus_on_areas_that_help_you_live_better'),
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🍃',
              title: AppLocalizations.of(context).t('wellness_lifestyle_advice'),
              description:
                  'Diet, exercise, and daily routine suggestions based on solar terms and your constitution.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🌱',
              title: AppLocalizations.of(context).t('wellness_solar_term_wellness'),
              description:
                  'Diet, tea, exercise, acupoint care, and sleep tips for each of the 24 solar terms.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '💬',
              title: AppLocalizations.of(context).t('wellness_emotional_companionship'),
              description:
                  'Here to listen when you need it, responding with warmth, without judgment or diagnosis.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '😴',
              title: AppLocalizations.of(context).t('wellness_sleep_improvement'),
              description:
                  'Gentle sleep methods based on TCM: foot soaks, acupressure, and relaxation techniques.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🍵',
              title: AppLocalizations.of(context).t('wellness_food_therapy_teas'),
              description:
                  'Seasonal ingredients and food therapy recipes tailored to your constitution.',
              color: const Color(0xFF81C784),
            ),

            const SizedBox(height: 32),

            // 重要提示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'If you are experiencing',
                          style: ShunshiTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Persistent low mood, insomnia, loss of appetite, or self-harm thoughts. Seek help now:\n'
                          '• Crisis Hotline: 988\n'
                          '• Or visit the nearest hospital psychiatric dept.\n'
                          '• You are not alone. Seeking help takes courage',
                          style: ShunshiTextStyles.body.copyWith(
                            fontSize: 13,
                            color: const Color(0xFFBF360C),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 底部
            Center(
              child: Text(
                'SEASONS - May you live in harmony with nature',
                style: ShunshiTextStyles.caption.copyWith(
                  color: ShunshiColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              title,
              style: ShunshiTextStyles.heading.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: ShunshiTextStyles.caption.copyWith(
              color: ShunshiColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _BoundaryCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ShunshiTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ShunshiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: ShunshiTextStyles.body.copyWith(
                    fontSize: 13,
                    color: ShunshiColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
