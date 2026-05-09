/// 体质测试报告页 — 参考UI _9
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class ConstitutionReportPageV2 extends StatelessWidget {
  const ConstitutionReportPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('体质测试报告', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 报告标题
            Text('体质测试报告 · 2024年春分', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            const SizedBox(height: 16),

            // 体质结果
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('您的体质：气虚质（兼有痰湿）', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    _buildTag('补气', Color(0xFFE4C285)),
                    _buildTag('祛湿', Color(0xFFE4C285)),
                    _buildTag('忌寒凉', Color(0xFFE4C285)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 体质强弱分布
            Text('体质强弱分布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            _buildBar('气虚质', 0.85, ShunShiColors.primary),
            _buildBar('痰湿质', 0.62, Color(0xFF74593C)),
            _buildBar('阳虚质', 0.45, Color(0xFF9BB8C9)),
            _buildBar('平和质（基准）', 0.30, ShunShiColors.textTertiary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info, size: 16, color: ShunShiColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(child: Text('测试结果基于近期身心状态。体质受环境与季节影响，建议每24节气重新评估。',
                  style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 20),

            // AI调养总评
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ShunShiColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ShunShiColors.primary.withOpacity(0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.auto_awesome, color: ShunShiColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('AI 调养总评', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                ]),
                const SizedBox(height: 12),
                Text(
                  '春季生发，您的"气虚"特征表现为易倦乏力，如细雨下的嫩芽需温言呵护。结合"痰湿"兼挟，体内水饮运化稍显迟滞。当下应以"温补脾气"为主，辅以"化痰祛湿"。切记，温和的早睡与清淡的饮食，是为您这卷生命画卷注入生气的最佳笔触。',
                  style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // 专属调养方案
            Text('专属调养方案', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),

            // 推荐食谱
            _buildPlanCard(Icons.restaurant, '推荐食谱', '黄芪炖鸡汤', '益气固表，温中补虚，适合气虚质人群。', '开始烹饪'),
            const SizedBox(height: 10),
            // 推荐穴位
            _buildPlanCard(Icons.spa, '推荐穴位', '足三里 · 补中益气', '', '查看'),
            const SizedBox(height: 10),
            // 推荐功法
            _buildPlanCard(Icons.self_improvement, '推荐功法', '八段锦 · 调理脾胃', '', '查看'),
            const SizedBox(height: 16),

            // Quote
            Center(child: Text('"静养其身，动养其气。"', style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 14, fontStyle: FontStyle.italic, color: ShunShiColors.textTertiary,
            ))),
            const SizedBox(height: 16),

            // 生成日历按钮
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ShunShiColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('生成详细调养日历', style: TextStyle(color: ShunShiColors.primary, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, backgroundColor: ShunShiColors.surfaceContainerLow, color: color, minHeight: 8),
        )),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildPlanCard(IconData icon, String category, String title, String desc, String action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: ShunShiColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.4)),
        ])),
        Text(action, style: TextStyle(fontSize: 12, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
        Icon(Icons.arrow_forward, size: 14, color: ShunShiColors.primary),
      ]),
    );
  }
}
