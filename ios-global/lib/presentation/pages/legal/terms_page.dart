import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final textColor = isDark ? ShunShiColors.textPrimary : ShunShiColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('Terms of Service',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _sectionTitle('SEASONS Terms of Service'),
          _body('Last updated: May 2025\nEffective: May 2025', textColor),
          const SizedBox(height: 12),
          _sectionTitle('1. Service description'),
          _body(
            '1.1 SEASONS is an AI wellness-management assistant based on traditional East Asian wellness ideas. The app provides:\n'
            '• Personalised wellness suggestions based on the 24 solar terms\n'
            '• A constitution check and analysis report\n'
            '• AI wellness chat and guidance\n'
            '• Diet, exercise, acupoint and other wellness suggestions\n'
            '• Health check-ins and data logging\n'
            '• A family wellness space (shared between members)\n\n'
            '1.2 The app offers add-on services by subscription (SEASONS Premium); details are as described in the app.\n\n'
            '1.3 We reserve the right to modify, suspend or end any feature at any time, and will give users advance notice.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('2. Acceptable use'),
          _body(
            '2.1 You agree not to use the app to:\n'
            '• Post unlawful, false, infringing or inappropriate content\n'
            '• Impersonate others or misrepresent your identity\n'
            '• Upload content containing malicious code\n'
            '• Attempt unauthorised access to systems or other people\'s data\n'
            '• Use automated tools for bulk operations\n'
            '• Use the service for any unlawful or infringing purpose\n\n'
            '2.2 Enforcement\n'
            'If we find a violation, we may:\n'
            '• Issue a warning\n'
            '• Restrict or suspend account features\n'
            '• Terminate the service and delete the account\n'
            '• Pursue legal remedies',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('3. Intellectual property'),
          _body(
            '3.1 Ownership\n'
            'All content in the app, including but not limited to text, images, icons, interface design, algorithms, AI model output and audio/video, is protected by copyright law and applicable international intellectual-property treaties.\n\n'
            '3.2 User content\n'
            'Content you enter in the app (conversations, check-in records, etc.) belongs to you. You grant us a non-exclusive, worldwide licence to process and store it to provide the service.\n\n'
            '3.3 Restrictions\n'
            'Without written permission you may not:\n'
            '• Copy, modify or distribute any part of the app\n'
            '• Reverse engineer or decompile the app\n'
            '• Use the app\'s content for commercial purposes',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('4. Disclaimer'),
          _body(
            '4.1 All content provided by the app (including wellness suggestions, seasonal guidance, constitution analysis and AI chat answers) is generated from traditional wellness ideas and AI algorithms. It is for general wellness reference only and is not medical diagnosis, treatment or prescription advice.\n\n'
            '4.2 The app is not a medical institution and does not provide medical services. The developer accepts no direct or indirect liability for any health problem or loss arising from use of the app\'s content.\n\n'
            '4.3 The app is provided "as is", without any express or implied warranty, including but not limited to merchantability, fitness for a particular purpose and non-infringement.\n\n'
            '4.4 We are not liable for service interruptions caused by force majeure, network failures, system maintenance and the like.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('5. Changes and termination'),
          _body(
            '5.1 We may adjust the service, features or pricing as business needs require, and will tell users by in-app notice, push notification or similar.\n\n'
            '5.2 You may close your account at any time to stop using the service. After closure:\n'
            '• Subscriptions are cancelled automatically\n'
            '• Personal data is deleted within 30 days (see the Privacy Policy)\n\n'
            '5.3 We may end the service to you if:\n'
            '• You breach these terms\n'
            '• The account is unused for a long time (12 consecutive months)\n'
            '• Required by law',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('6. Dispute resolution'),
          _body(
            '6.1 These terms are governed by the laws of the jurisdiction where the developer is established, without regard to conflict-of-law rules, and without affecting any mandatory consumer-protection rights you have in your country of residence.\n\n'
            '6.2 The parties shall first try to resolve any dispute in good faith. If that fails, either party may bring the dispute before the competent courts of that jurisdiction, subject to any mandatory consumer rights above.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('7. General'),
          _body(
            '7.1 These terms are the entire agreement between you and the developer regarding use of the app.\n\n'
            '7.2 If any provision is held invalid or unenforceable, the remaining provisions are unaffected.\n\n'
            '7.3 Our failure to exercise a right is not a waiver of that right.\n\n'
            'Questions? Contact: legal@shunshi.app',
            textColor,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.textPrimary,
        ),
      ),
    );
  }

  Widget _body(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: color, height: 1.8),
    );
  }
}
