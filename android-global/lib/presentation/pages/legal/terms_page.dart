import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../../core/network/api_singleton.dart';

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
          _sectionTitle('SEASONS — Terms of Service'),
          _body('Last updated: May 2025\nEffective: May 2025', textColor),
          const SizedBox(height: 12),
          _sectionTitle('1. Service Description'),
          _body(
            '1.1 SEASONS is an AI-powered wellness companion based on Traditional Chinese Medicine (TCM) and the 24 Solar Terms. The app provides:\n'
            '• Personalized seasonal wellness suggestions based on the 24 Solar Terms\n'
            '• TCM constitution (body type) assessment and analysis reports\n'
            '• AI wellness conversation and consultation\n'
            '• Diet, exercise, and acupoint wellness plan recommendations\n'
            '• Health check-in and data tracking\n'
            '• Family wellness space (shared among members)\n\n'
            '1.2 The app offers premium services (SEASONS Pro) via subscription. Specific benefits are described within the app.\n\n'
            '1.3 We reserve the right to modify, suspend, or terminate any service features at any time, with prior notice to users.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('2. User Conduct'),
          _body(
            '2.1 You agree not to use the app for:\n'
            '• Posting illegal, false, infringing, or inappropriate content\n'
            '• Impersonating others or misrepresenting your identity\n'
            '• Uploading content with malicious code\n'
            '• Attempting unauthorized access to systems or others\' data\n'
            '• Using automated tools for bulk operations\n'
            '• Using the service for any illegal or infringing purposes\n\n'
            '2.2 Violations\n'
            'If violations are found, we may take the following actions:\n'
            '• Warning\n'
            '• Restricting or suspending account features\n'
            '• Terminating service and deleting the account\n'
            '• Pursuing legal liability',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('3. Intellectual Property'),
          _body(
            '3.1 Ownership\n'
            'All content in this app, including but not limited to text, images, icons, interface design, algorithms, AI model outputs, and audio-visual content, is protected by copyright laws and applicable international intellectual property treaties.\n\n'
            '3.2 User Content\n'
            'Content you enter in the app (conversations, check-in records, etc.) belongs to you. You grant us a non-exclusive, worldwide license to process and store this content to provide the service.\n\n'
            '3.3 Restrictions\n'
            'Without written authorization, you must not:\n'
            '• Copy, modify, or distribute any part of the app\n'
            '• Reverse engineer or decompile the app\n'
            '• Use app content for commercial purposes',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('4. Disclaimer'),
          _body(
            '4.1 All content provided by this app (including but not limited to wellness suggestions, seasonal adjustment plans, constitution analysis, and AI conversation responses) is generated based on traditional TCM theory and AI algorithms. It is for health and wellness reference only and does not constitute medical diagnosis, treatment, or prescription advice.\n\n'
            '4.2 This app is not a medical institution and does not provide medical services. The developer is not liable, directly or indirectly, for any health issues or losses arising from the use of the app\'s content.\n\n'
            '4.3 The service is provided "as is" without any express or implied warranties, including but not limited to merchantability, fitness for a particular purpose, and non-infringement.\n\n'
            '4.4 We are not responsible for service interruptions caused by force majeure, network failures, system maintenance, or other reasons.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('5. Service Changes and Termination'),
          _body(
            '5.1 We may adjust service content, features, or pricing based on business needs, and will notify users via in-app announcements, push notifications, etc.\n\n'
            '5.2 You may cancel your account at any time to terminate the service. After cancellation:\n'
            '• Subscriptions will be automatically canceled\n'
            '• Personal data will be deleted within 30 days (see Privacy Policy)\n\n'
            '5.3 We may terminate the service if:\n'
            '• You violate this agreement\n'
            '• The account has been inactive for 12 consecutive months\n'
            '• Required by law or regulation',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('6. Dispute Resolution'),
          _body(
            '6.1 This agreement is governed by applicable law.\n\n'
            '6.2 Disputes arising from this agreement shall first be resolved through friendly negotiation. If negotiation fails, either party may initiate legal proceedings in a court of competent jurisdiction.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('7. Miscellaneous'),
          _body(
            '7.1 This agreement constitutes the entire agreement between you and the developer regarding the use of this app.\n\n'
            '7.2 If any provision of this agreement is found to be invalid or unenforceable, the validity of the remaining provisions shall not be affected.\n\n'
            '7.3 Our failure to exercise any right does not constitute a waiver of that right.\n\n'
            'For questions, contact: legal@shunshi.app',
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
