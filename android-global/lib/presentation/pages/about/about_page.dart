/// About SEASONS页面
library;

import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../core/network/api_singleton.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : AppColors.background(context),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).get('profile_about'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
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
            Text(AppLocalizations.of(context).get('about_app_name'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).get('about_version'), style: TextStyle(fontSize: 14, color: AppColors.textTertiary(context))),
          ])),
          const SizedBox(height: 32),

          // Description
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).get('profile_slogan'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary(context))),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).get('about_description'), style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.8)),
            ]),
          ),
          const SizedBox(height: 16),

          // Features
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _featureRow(Icons.eco, 'Solar Term Wellness', 'Follow the 24 Solar Terms for Wellness'),
              const Divider(height: 20),
              _featureRow(Icons.schedule, 'Daily rhythm reminders', 'Gentle reminders through the day'),
              const Divider(height: 20),
              _featureRow(Icons.health_and_safety, 'Body Type Identification', '9 Body Types with Smart Scoring'),
              const Divider(height: 20),
              _featureRow(Icons.smart_toy, 'AI Advisor', '7x24 Wellness Consultation'),
            ]),
          ),
          const SizedBox(height: 16),

          // Links
          Container(decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _linkTile(context, 'Terms of Service', Icons.description_outlined),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile(context, 'Privacy Policy', Icons.privacy_tip_outlined),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _linkTile(context, 'Open Source Licenses', Icons.code),
            ]),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(child: Text("© 2026 SEASONS\n\"The finest doctor treats before illness\" — Huangdi Neijing (Yellow Emperor's Inner Classic)",
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context), height: 1.8))),
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

  Widget _linkTile(BuildContext context, String title, IconData icon, {String? route}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary(context), size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context))),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 18),
      onTap: () {
        if (route != null) context.push(route);
      },
    );
  }
}
