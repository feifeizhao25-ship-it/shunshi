/// Body Type Essence Page — Reference: body_type_essence
/// "Your Essence: Balanced"
///
/// Structure:
/// 1. Header with essence name
/// 2. Vitality radar (6 metrics)
/// 3. Solar Dominance + Terrene Stability cards
/// 4. Natural Rhythm description
/// 5. Seasonal Adjustments
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class BodyTypeEssencePage extends StatelessWidget {
  final String? bodyType;
  const BodyTypeEssencePage({super.key, this.bodyType});

  static const _metrics = [
    _Metric('Vitality', 0.82, Icons.favorite),
    _Metric('Circulation', 0.75, Icons.water_drop),
    _Metric('Digestion', 0.88, Icons.restaurant),
    _Metric('Resilience', 0.70, Icons.shield),
    _Metric('Metabolism', 0.65, Icons.local_fire_department),
    _Metric('Sleep Quality', 0.78, Icons.bedtime),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: ShunShiColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ShunShiColors.primaryDeep ?? ShunShiColors.primary,
                      ShunShiColors.primary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Essence',
                          style: TextStyle(
                            fontSize: 13, color: Colors.white70,
                            fontFamily: ShunShiTypography.sansFamily,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Seasonal Essence: Balanced',
                          style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700,
                            color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your constitution mirrors the transition between Spring and Autumn. '
                          'You possess a resilient core with a fluid adaptability to external shifts.',
                          style: TextStyle(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                            height: 1.5, fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
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
                  // ── Vitality Metrics ──
                  _sectionTitle('filter_vintage', 'Vitality'),
                  const SizedBox(height: 12),
                  ..._metrics.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _metricBar(m),
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.format_quote, size: 20, color: ShunShiColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '"Harmony in Flux"',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: ShunShiColors.primary,
                            fontFamily: ShunShiTypography.serifFamily, fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── Solar Dominance ──
                  Row(children: [
                    const Icon(Icons.wb_sunny, size: 20, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text('Solar Dominance', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Your energy peaks with the rising sun. Morning rituals are your strongest foundation.',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      height: 1.6, fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Terrene Stability ──
                  Row(children: [
                    const Icon(Icons.spa, size: 20, color: ShunShiColors.primary),
                    const SizedBox(width: 8),
                    Text('Terrene Stability', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Grounded and deliberate. Your body recovers best through stillness and earthy textures.',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      height: 1.6, fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Natural Rhythm ──
                  _sectionTitle('auto_awesome', 'Your Natural Rhythm'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The Balanced type is rare, characterized by a symmetry of fire and earth. '
                          'You don\'t experience the drastic highs or lows of more singular constitutions, '
                          'but you are sensitive to seasonal transitions.',
                          style: TextStyle(
                            fontSize: 14, color: ShunShiColors.textSecondary,
                            height: 1.7, fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _checkItem('Optimal resting heart rate during twilight hours.'),
                        const SizedBox(height: 8),
                        _checkItem('Digestive fire is strongest between 11 AM and 2 PM.'),
                        const SizedBox(height: 8),
                        _checkItem('Cognitive peak occurs in the second hour after waking.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Seasonal Adjustments ──
                  _sectionTitle('eco', 'Seasonal Adjustments'),
                  const SizedBox(height: 12),
                  _seasonCard('Active Season', 'Spring · Wood Element',
                    'Your most vital period. Channel energy into creative projects and morning movement practices.',
                    ShunShiColors.primary),
                  const SizedBox(height: 12),
                  _seasonCard('Rest Season', 'Late Summer · Earth Element',
                    'Focus on grounding. Nourish with warm, cooked foods and prioritize sleep.',
                    const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  _seasonCard('Challenge Season', 'Winter · Water Element',
                    'Your resilience is tested. Extra rest, warm teas, and minimal social obligation.',
                    const Color(0xFF3B82F6)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String icon, String title) {
    return Row(children: [
      Icon(Icons.format_quote, size: 0), // spacer trick
      Text(title, style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
      )),
    ]);
  }

  Widget _metricBar(_Metric m) {
    return Row(children: [
      Icon(m.icon, size: 18, color: ShunShiColors.primary),
      const SizedBox(width: 10),
      SizedBox(
        width: 90,
        child: Text(m.name, style: TextStyle(
          fontSize: 13, color: ShunShiColors.textSecondary,
          fontFamily: ShunShiTypography.sansFamily,
        )),
      ),
      Expanded(
        child: Stack(children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: m.value,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: ShunShiColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 36,
        child: Text('${(m.value * 100).round()}%', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: ShunShiColors.primary,
          fontFamily: ShunShiTypography.sansFamily,
        ), textAlign: TextAlign.right),
      ),
    ]);
  }

  Widget _checkItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 18, color: ShunShiColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(
          fontSize: 13, color: ShunShiColors.textSecondary,
          height: 1.5, fontFamily: ShunShiTypography.sansFamily,
        ))),
      ],
    );
  }

  Widget _seasonCard(String title, String subtitle, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4, height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(
                  fontSize: 12, color: color, fontFamily: ShunShiTypography.sansFamily,
                )),
                const SizedBox(height: 6),
                Text(desc, style: TextStyle(
                  fontSize: 13, color: ShunShiColors.textSecondary,
                  height: 1.5, fontFamily: ShunShiTypography.sansFamily,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String name;
  final double value;
  final IconData icon;
  const _Metric(this.name, this.value, this.icon);
}
