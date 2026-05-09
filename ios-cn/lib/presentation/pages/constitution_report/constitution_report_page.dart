/// 体质测试报告页 — 参考UI _9
/// 气虚质（兼有痰湿）· 2024年春分
///
/// 结构:
/// 1. 体质标签
/// 2. 体质强弱分布（雷达图风格 → 列表条）
/// 3. AI调养总评
/// 4. 专属调养方案（推荐食谱/茶饮/功法）
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ConstitutionReportPage extends StatelessWidget {
  const ConstitutionReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: ShunShiColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D5A3D), ShunShiColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '体质测试报告 · 2024年春分',
                          style: TextStyle(
                            fontSize: 13, color: Colors.white70,
                            fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '您的体质：气虚质（兼有痰湿）',
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          _tagChip('补气', ShunShiColors.primary),
                          const SizedBox(width: 8),
                          _tagChip('祛湿', ShunShiColors.gold),
                          const SizedBox(width: 8),
                          _tagChip('忌寒凉', ShunShiColors.error),
                        ]),
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
                  // ── 体质强弱分布 ──
                  _sectionTitle('体质强弱分布'),
                  const SizedBox(height: 16),
                  _scoreBar('气虚质', 0.85, ShunShiColors.error, '85%'),
                  const SizedBox(height: 10),
                  _scoreBar('痰湿质', 0.62, ShunShiColors.gold, '62%'),
                  const SizedBox(height: 10),
                  _scoreBar('阳虚质', 0.45, const Color(0xFF3B82F6), '45%'),
                  const SizedBox(height: 10),
                  _scoreBar('平和质（基准）', 0.30, ShunShiColors.primary, '30%'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 16, color: ShunShiColors.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '测试结果基于您的近期身心状态。体质受环境与季节影响，建议每 24 节气重新评估。',
                          style: TextStyle(
                            fontSize: 12, color: ShunShiColors.textTertiary,
                            height: 1.5, fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── AI调养总评 ──
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 18, color: ShunShiColors.gold),
                    const SizedBox(width: 8),
                    Text('AI 调养总评', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ShunShiColors.goldLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '春季生发，您的"气虚"特征表现为易倦乏力，如细雨下的嫩芽需温言呵护。'
                      '结合"痰湿"兼挟，体内水饮运化稍显迟滞。当下应以"温补脾气"为主，'
                      '辅以"化痰祛湿"。切记，温和的早睡与清淡的饮食，是为您这卷生命画卷注入生气的最佳笔触。',
                      style: TextStyle(
                        fontSize: 14, color: ShunShiColors.textSecondary,
                        height: 1.8, fontFamily: ShunShiTypography.sansFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 专属调养方案 ──
                  _sectionTitle('专属调养方案'),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('查看全部 →', style: TextStyle(
                        fontSize: 13, color: ShunShiColors.primary,
                        fontFamily: ShunShiTypography.sansFamily,
                      )),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 推荐食谱
                  _recommendCard(
                    Icons.restaurant,
                    '推荐食谱',
                    '黄芪炖鸡汤',
                    '益气固表 · 温中补虚',
                  ),
                  const SizedBox(height: 12),

                  // 推荐茶饮
                  _recommendCard(
                    Icons.local_cafe,
                    '推荐茶饮',
                    '陈皮普洱茶',
                    '理气化痰 · 健脾祛湿',
                  ),
                  const SizedBox(height: 12),

                  // 推荐功法
                  _recommendCard(
                    Icons.self_improvement,
                    '推荐功法',
                    '八段锦 · 调理脾胃须单举',
                    '调理气机 · 促进运化',
                  ),
                  const SizedBox(height: 12),

                  // 推荐穴位
                  _recommendCard(
                    Icons.healing,
                    '推荐穴位',
                    '足三里 · 三阴交',
                    '补气健脾 · 化痰祛湿',
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

  Widget _tagChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: color,
      fontFamily: ShunShiTypography.sansFamily,
    )),
  );

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary,
  ));

  Widget _scoreBar(String label, double percent, Color color, String score) {
    return Row(children: [
      SizedBox(
        width: 90,
        child: Text(label, style: TextStyle(
          fontSize: 13, color: ShunShiColors.textSecondary,
          fontFamily: ShunShiTypography.sansFamily,
        )),
      ),
      Expanded(
        child: Stack(children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: percent,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 36,
        child: Text(score, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: color,
          fontFamily: ShunShiTypography.sansFamily,
        ), textAlign: TextAlign.right),
      ),
    ]);
  }

  Widget _recommendCard(IconData icon, String category, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: ShunShiColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: ShunShiColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(category, style: TextStyle(
              fontSize: 11, color: ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              fontSize: 12, color: ShunShiColors.textSecondary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
          ]),
        ),
        const Icon(Icons.chevron_right, size: 20, color: ShunShiColors.textTertiary),
      ]),
    );
  }
}
