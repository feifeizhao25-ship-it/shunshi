/// 关于顺时页面
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
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
            Text('Version 2.4.0', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
          ])),
          const SizedBox(height: 32),

          // Description
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('顺应天时，颐养身心', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
              const SizedBox(height: 12),
              Text('顺时是一款基于中医养生理论的智能健康助手。结合二十四节气、十二时辰、九种体质，为用户提供个性化的养生建议。', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
            ]),
          ),
          const SizedBox(height: 16),

          // Features
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _featureRow(Icons.eco, '节气养生', '跟随二十四节气调养'),
              const Divider(height: 20),
              _featureRow(Icons.schedule, '时辰提醒', '十二时辰对应经络提醒'),
              const Divider(height: 20),
              _featureRow(Icons.health_and_safety, '体质辨识', '九种体质智能评分'),
              const Divider(height: 20),
              _featureRow(Icons.smart_toy, 'AI 顾问', '7x24小时养生咨询'),
            ]),
          ),
          const SizedBox(height: 16),

          // Links
          Container(decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _linkTile('用户协议', Icons.description_outlined),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile('隐私政策', Icons.privacy_tip_outlined),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile('开源许可', Icons.code),
            ]),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(child: Text('© 2026 ShunShi Health Tech\n"上医治未病" ——《黄帝内经》',
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

  Widget _linkTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: ShunShiColors.textSecondary, size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
      onTap: () {},
    );
  }
}
