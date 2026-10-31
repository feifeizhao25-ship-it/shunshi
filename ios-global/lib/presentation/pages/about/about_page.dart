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
        title: Text('About SEASONS', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
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
            Text('SEASONS', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Version 2.4.0', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
          ])),
          const SizedBox(height: 32),

          // Description
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Live in rhythm with the seasons', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
              const SizedBox(height: 12),
              Text('SEASONS is a smart wellness companion built on traditional East Asian wellness ideas. It combines the 24 solar terms, daily rhythms and nine constitution types to give you personalised wellness suggestions.', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
            ]),
          ),
          const SizedBox(height: 16),

          // Features
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _featureRow(Icons.eco, 'Seasonal wellness', 'Follow the 24 solar terms'),
              const Divider(height: 20),
              _featureRow(Icons.schedule, 'Daily rhythm reminders', 'Reminders matched to the twelve two-hour periods of the day'),
              const Divider(height: 20),
              _featureRow(Icons.health_and_safety, 'Constitution check', 'Smart scoring across nine constitution types'),
              const Divider(height: 20),
              _featureRow(Icons.smart_toy, 'AI companion', 'Wellness chat, any time'),
            ]),
          ),
          const SizedBox(height: 16),

          // Links
          Container(decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _linkTile('Terms of Service', Icons.description_outlined),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile('Privacy Policy', Icons.privacy_tip_outlined),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile('Open-source licences', Icons.code),
            ]),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(child: Text('© 2026 SEASONS\n"The best care is prevention" — Huangdi Neijing',
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
