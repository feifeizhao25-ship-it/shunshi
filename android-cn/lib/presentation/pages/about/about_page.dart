/// 关于顺时页面
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/compliance/operator.dart';
import '../../../design_system/theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('关于顺时', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Logo + Name
          Center(child: Column(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
              borderRadius: BorderRadius.circular(20),
            ), child: const Center(child: Text('🌿', style: TextStyle(fontSize: 36)))),
            const SizedBox(height: 16),
            Text('顺时 · ShunShi', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 4),
            Text('版本 1.0.0', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
          ])),
          const SizedBox(height: 32),

          // Description
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('按节气安排一天', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
              const SizedBox(height: 12),
              Text('顺时陪你按二十四节气安排作息。对话由人工智能生成，不是真人，不提供医疗、诊断或治疗。', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
            ]),
          ),
          const SizedBox(height: 16),

          // Features
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _featureRow(Icons.eco, '节气安排', '按二十四节气看一天的节奏'),
              const Divider(height: 20),
              _featureRow(Icons.schedule, '时辰作息', '十二时辰只作息提醒'),
              const Divider(height: 20),
              _featureRow(Icons.smart_toy, 'AI 对话', '内容由 AI 生成，不是真人'),
            ]),
          ),
          const SizedBox(height: 16),

          // Links
          Container(decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _linkTile(context, '用户协议', Icons.description_outlined, '/terms-and-conditions'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile(context, '隐私政策', Icons.privacy_tip_outlined, '/privacy-policy'),
            ]),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(child: Text(
            '${DomesticOperator.name}\n'
            '${DomesticOperator.line('ICP 备案号', DomesticOperator.icpNumber)}\n'
            '${DomesticOperator.line('App 备案号', DomesticOperator.appFilingNumber)}\n'
            '${DomesticOperator.line('生成式人工智能登记编号', DomesticOperator.aiFilingNumber)}',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.8))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(children: [
      Icon(icon, color: ShunShiColors.primary, size: 22),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
      ]),
    ]);
  }

  Widget _linkTile(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: ShunShiColors.textSecondary, size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
      onTap: () => context.push(route),
    );
  }
}
