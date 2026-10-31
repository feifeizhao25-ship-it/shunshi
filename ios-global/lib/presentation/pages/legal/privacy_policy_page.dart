import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('Privacy Policy', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          SizedBox(height: 16),
          Text(
            'SEASONS Privacy Policy\n\n'
            'Last updated: January 2025\n\n'
            '1. Information we collect\nWe collect the following to provide a better service:\n• Basic account information (nickname, avatar)\n• Health-related data (constitution check results, wellness preferences)\n• Usage data (feature usage, conversation history)\n\n'
            '2. How we use it\nYour data is used only to:\n• Provide personalised wellness suggestions\n• Improve service quality\n• Share family members\' status (with your authorisation)\n\n'
            '3. How we protect it\n• All data in transit is protected with SSL/TLS encryption\n• AI conversation history is stored encrypted\n• Strict internal access controls\n\n'
            '4. Sharing\nWe do not sell or share your personal data with third parties, except:\n• With your explicit consent\n• Where required by law\n\n'
            '5. Your rights\nUnder data-protection laws such as the GDPR, you have the right to:\n• Access your personal data\n• Export your data\n• Delete your data\n• Withdraw consent\n\n'
            '6. Retention\nAfter an account is deleted, we remove all related data within 30 days.\n\n'
            '7. Minimum age\nYou must be at least 16 to use SEASONS. We do not knowingly collect personal data from anyone under 16. If we learn that we have, we delete it promptly.\n\n'
            '8. Contact us\nData protection questions: privacy@shunshi.app',
            style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8),
          ),
        ],
      ),
    );
  }
}
