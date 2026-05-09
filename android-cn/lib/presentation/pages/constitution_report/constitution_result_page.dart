/// 体质测试结果页 — 对齐UI参考 _9
/// TopBar(头像+ShunShi AI+通知) → 标题+标签 → 体质强弱分布(进度条) → AI调养总评(毛玻璃) → 专属调养方案 → 底部CTA
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ConstitutionResultPage extends StatelessWidget {
  final String constitutionType;
  final Map<String, double>? scores;

  const ConstitutionResultPage({
    super.key,
    this.constitutionType = '气虚质（兼有痰湿）',
    this.scores,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    final now = DateTime.now();
    final seasonLabel = _getSeasonLabel(now.month);

    return Scaffold(
      backgroundColor: bg,
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
                      child: const Icon(Icons.person, size: 20, color: ShunShiColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Text('ShunShi AI', style: TextStyle(
                      fontSize: 20, fontStyle: FontStyle.italic,
                      fontFamily: ShunShiTypography.serifFamily,
                      color: ShunShiColors.primary,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.notifications_outlined, size: 22, color: ShunShiColors.primary),
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
                  Text('体质测试报告 · ${now.year}年$seasonLabel', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: ShunShiColors.secondary, letterSpacing: 2,
                  )),
                  const SizedBox(height: 12),
                  const Text('您的体质：', style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    fontFamily: ShunShiTypography.serifFamily,
                    color: ShunShiColors.primary, height: 1.3,
                  )),
                  Text(constitutionType, style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    fontFamily: ShunShiTypography.serifFamily,
                    color: ShunShiColors.primary, height: 1.3,
                  )),
                  const SizedBox(height: 20),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      _tagChip('补气', ShunShiColors.apricotLight),
                      _tagChip('祛湿', ShunShiColors.apricotLight),
                      _tagChip('忌寒凉', ShunShiColors.primaryContainer),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // ── 体质强弱分布 ──
                  _buildDistributionSection(),
                  const SizedBox(height: 48),

                  // ── AI 调养总评 ──
                  _buildAiReview(),
                  const SizedBox(height: 48),

                  // ── 专属调养方案 ──
                  _buildSolutions(),
                  const SizedBox(height: 40),

                  // ── 底部 CTA ──
                  Center(
                    child: Column(
                      children: [
                        const Text('"静养其身，动养其气。"', style: TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic,
                          color: ShunShiColors.secondary,
                        )),
                        const SizedBox(height: 16),
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
                            child: Text('生成详细调养日历', style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              letterSpacing: 3, color: Colors.white,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSeasonLabel(int month) {
    if (month >= 3 && month <= 5) return '春分';
    if (month >= 6 && month <= 8) return '夏至';
    if (month >= 9 && month <= 11) return '秋分';
    return '冬至';
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

  Widget _buildDistributionSection() {
    final bars = [
      _BarData('气虚质', 0.85, ShunShiColors.primary),
      _BarData('痰湿质', 0.62, ShunShiColors.primaryContainer),
      _BarData('阳虚质', 0.45, ShunShiColors.surfaceVariant),
      _BarData('平和质（基准）', 0.30, ShunShiColors.textTertiary.withValues(alpha: 0.3)),
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
          const Text('体质强弱分布', style: TextStyle(
            fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.primary,
          )),
          const SizedBox(height: 24),
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
                const SizedBox(height: 6),
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
          const SizedBox(height: 16),
          Container(height: 1, color: ShunShiColors.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: ShunShiColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '测试结果基于您的近期身心状态。体质受环境与季节影响，建议每24节气重新评估。',
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

  Widget _buildAiReview() {
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
              const SizedBox(width: 8),
              const Text('AI 调养总评', style: TextStyle(
                fontSize: 20, fontFamily: ShunShiTypography.serifFamily,
                color: ShunShiColors.primary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '春季生发，您的"气虚"特征表现为易倦乏力，如细雨下的嫩芽需温言呵护。结合"痰湿"兼挟，体内水饮运化稍显迟滞。当下应以"温补脾气"为主，辅以"化痰祛湿"。切记，温和的早睡与清淡的饮食，是为您这卷生命画卷注入生气的最佳笔触。',
            style: TextStyle(
              fontSize: 15, height: 2.0,
              color: ShunShiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('专属调养方案', style: TextStyle(
              fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.primary,
            )),
            Text('查看全部', style: TextStyle(
              fontSize: 12, color: ShunShiColors.secondary,
              decoration: TextDecoration.underline,
              decorationColor: ShunShiColors.secondary.withValues(alpha: 0.3),
            )),
          ],
        ),
        const SizedBox(height: 20),
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
                      Text('推荐食谱', style: TextStyle(
                        fontSize: 10, letterSpacing: 2,
                        color: ShunShiColors.secondary,
                      )),
                      const SizedBox(height: 6),
                      const Text('黄芪炖鸡汤', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        fontFamily: ShunShiTypography.serifFamily,
                        color: ShunShiColors.primary,
                      )),
                      const SizedBox(height: 8),
                      Text('益气固表，温中补虚，适合气虚质人群。', style: TextStyle(
                        fontSize: 12, color: ShunShiColors.textSecondary,
                      )),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: const [
                            Text('开始烹饪', style: TextStyle(
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
        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        const Text('推荐穴位', style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        const SizedBox(height: 6),
                        Text('足三里 · 补中益气', style: TextStyle(
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
                        child: const Icon(Icons.play_arrow, size: 18, color: ShunShiColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                        const SizedBox(height: 12),
                        const Text('推荐功法', style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        const SizedBox(height: 6),
                        Text('八段锦 · 调理脾胃', style: TextStyle(
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
                        child: const Icon(Icons.play_arrow, size: 18, color: ShunShiColors.primary),
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
