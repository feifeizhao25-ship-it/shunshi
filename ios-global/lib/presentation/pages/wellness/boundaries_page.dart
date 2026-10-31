import 'package:flutter/material.dart';
import '../../widgets/seasons_visual.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';

/// 顺时边界公示页 — 清楚告知用户产品边界
class BoundariesPage extends StatelessWidget {
  const BoundariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunshiColors.background,
      appBar: AppBar(
        backgroundColor: ShunshiColors.background,
        foregroundColor: ShunshiColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Product boundaries'),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/images/sg_hero_bound.webp', height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What SEASONS is not',
                    style: ShunshiTextStyles.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The lines we hold, for the sake of your health',
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
              title: 'SEASONS does not provide',
              subtitle: 'The following is beyond the scope of the product and could put your health at risk',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🏥',
              title: 'Medical diagnosis',
              description:
                  'We do not diagnose any disease. If you feel unwell, please see a doctor. AI cannot replace medical examination and diagnosis.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '💊',
              title: 'Medication advice',
              description:
                  'We do not recommend any medication, Eastern or Western. Medication should be used under a doctor\'s guidance; self-medicating can have serious consequences.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🩺',
              title: 'Symptom analysis',
              description:
                  'We do not interpret abnormal values in check-up reports or guess "what illness you might have".',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '📊',
              title: 'Health scores',
              description:
                  'We do not give you a score. Health is multi-dimensional and cannot be measured by a single number.',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '😰',
              title: 'Mood scores',
              description:
                  'We do not rate your emotional state. Feelings are neither good nor bad, and each deserves respect.',
              color: const Color(0xFFE57373),
            ),

            const SizedBox(height: 32),

            // 顺时提供
            _SectionTitle(
              emoji: '✅',
              title: 'SEASONS provides',
              subtitle: 'We focus on helping you live better',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🍃',
              title: 'Lifestyle suggestions',
              description:
                  'Based on the solar terms, your constitution and context, we suggest diet, exercise, routines and other lifestyle habits so you can live in step with natural rhythms.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🌱',
              title: 'Seasonal wellness guidance',
              description:
                  'Diet, teas, guided exercises, acupoint care and sleep and daily-routine tips for each of the 24 solar terms, so you live in sync with nature.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '💬',
              title: 'Emotional companionship',
              description:
                  'We keep you company when you need to be heard, responding warmly — without judging, rushing or diagnosing.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '😴',
              title: 'Sleep suggestions',
              description:
                  'Gentle sleep-improvement methods based on traditional wellness ideas and daily habits, such as foot soaks, massage and relaxation techniques.',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🍵',
              title: 'Food therapy & teas',
              description:
                  'Seasonal ingredients and food-therapy plans matched to your constitution, plus teas suited to everyday wellness.',
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
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
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
                          'persistent low mood, insomnia, loss of appetite or thoughts of harming yourself, please seek professional help right away:\n'
                          '• Call your local crisis line (US 988, UK 116 123) or emergency number\n'
                          '• Or go to your nearest hospital or mental-health service\n'
                          '• You are not alone — asking for help takes courage',
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
                'SEASONS · live in harmony with nature, body and mind',
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
            SgIconBadge(emoji: emoji, color: color, size: 32),
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
          SgIconBadge(emoji: emoji, color: color),
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
