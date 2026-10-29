/// Body Type Essence Page — Reference: body_type_essence
/// "Your Essence: Balanced"
///
/// Structure:
/// 1. Header with essence name
/// 2. 平时可以留意 radar (6 metrics)
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
    _Metric('日常作息', 0, Icons.favorite),
    _Metric('手足冷暖', 0, Icons.water_drop),
    _Metric('饮食规律', 0, Icons.restaurant),
    _Metric('换季适应', 0, Icons.shield),
    _Metric('白天精神', 0, Icons.local_fire_department),
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
            actions: const [],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ShunShiColors.primaryDark ?? ShunShiColors.primary,
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
                          '体质说明',
                          style: TextStyle(
                            fontSize: 13, color: Colors.white70,
                            fontFamily: ShunShiTypography.sansFamily,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '平和质 · 一般说明',
                          style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700,
                            color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ''
                          '下面是平和质的一般特点，不是个人检测结果。完成体质问卷后，才会显示你自己的情况。',
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
                  // ── 平时可以留意 Metrics ──
                  _sectionTitle('filter_vintage', '平时可以留意'),
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
                    '早晨是比较适合活动的时候，可以安排散步或拉伸。',
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
                    '累了就停下来休息，饮食以温软为主。',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      height: 1.6, fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Natural Rhythm ──
                  _sectionTitle('auto_awesome', '你的自然节律'),
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
                          '平和质的人平时起伏不大，换季时仍要注意作息。',
                          style: TextStyle(
                            fontSize: 14, color: ShunShiColors.textSecondary,
                            height: 1.7, fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _checkItem('傍晚宜安静，不必再安排剧烈活动。'),
                        const SizedBox(height: 8),
                        _checkItem('午饭前后把正餐吃好。'),
                        const SizedBox(height: 8),
                        _checkItem('起床后先活动一下再开始忙碌。'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Seasonal Adjustments ──
                  _sectionTitle('eco', 'Seasonal Adjustments'),
                  const SizedBox(height: 12),
                  _seasonCard('Active Season', 'Spring · Wood Element',
                    '春季适合早起走动，别一下安排太满。',
                    ShunShiColors.primary),
                  const SizedBox(height: 12),
                  _seasonCard('Rest Season', 'Late Summer · Earth Element',
                    '长夏注意少吃生冷，把觉睡够。',
                    const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  _seasonCard('Challenge Season', 'Winter · Water Element',
                    '冬季多休息，喝温热的水，应酬可以少一些。',
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
      Expanded(child: Text(m.name, style: TextStyle(
        fontSize: 14, color: ShunShiColors.textSecondary,
        fontFamily: ShunShiTypography.sansFamily,
      ))),
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
