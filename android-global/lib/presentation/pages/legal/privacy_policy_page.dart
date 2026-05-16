import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: Text(AppLocalizations.of(context).t('settings_privacy'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          SizedBox(height: 16),
          Text(
            'SEASONS Privacy Policy\n\n'
            'Last updated: January 2025\n\n'
            '1. Information Collection\nWe collect the following to provide better service:\n• Basic account info (nickname, avatar)\n• Health data (constitution test results, wellness preferences)\n• Usage data (feature frequency, conversation logs)\n\n'
            '2. Data Usage\nYour data is used only for:\n• Personalized wellness suggestions\n• Improving service quality\n• Family health status sharing (with your consent)\n\n'
            '3. Data Protection\n• All data transfers use SSL encryption\n• AI conversations are encrypted at rest\n• Strict internal access controls\n\n'
            '4. Data Sharing\nWe do not sell or share your personal data with third parties, except:\n• With your explicit consent\n• As required by law\n\n'
            '5. Your Rights\nUnder GDPR and data protection laws, you may:\n• Access your personal data\n• Export your data\n• Delete your data\n• Withdraw consent\n\n'
            '6. Data Retention\nAfter account deletion, we clear all related data within 30 days.\n\n'
            '7. Contact Us\nData protection inquiries: privacy@seasons.app',
            style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8),
          ),
        ],
      ),
    );
  }
}
