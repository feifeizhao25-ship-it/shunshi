import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../../core/network/api_singleton.dart';

class MedicalDisclaimerPage extends StatelessWidget {
  const MedicalDisclaimerPage({super.key});

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
        title: const Text('Medical Disclaimer',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _sectionTitle('Medical Disclaimer'),
          _body('Last updated: May 2025', textColor),
          const SizedBox(height: 16),
          _warningCard(),
          const SizedBox(height: 16),
          _sectionTitle('1. Nature of the Service'),
          _body(
            '1.1 SEASONS is a health and wellness companion based on Traditional Chinese Medicine (TCM) and artificial intelligence technology.\n\n'
            '1.2 All content provided by this app, including but not limited to:\n'
            '• Solar term wellness suggestions\n'
            '• Constitution (body type) analysis\n'
            '• Diet, exercise, and acupoint recommendations\n'
            '• AI conversation responses\n\n'
            'is for informational reference based on traditional wellness knowledge and does not constitute medical diagnosis, treatment, or prescription advice.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('2. Not Medical Advice'),
          _body(
            '2.1 The wellness suggestions provided by this app cannot replace the following professional medical services:\n'
            '• A doctor\'s diagnosis or treatment plan\n'
            '• Examinations or tests from professional medical institutions\n'
            '• Drug prescriptions or medication guidance\n'
            '• Psychotherapy or psychological counseling\n'
            '• Any form of medical procedure\n\n'
            '2.2 AI-generated content may be inaccurate or not applicable to your personal situation. Please consult a qualified medical professional before making any health-related decisions.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('3. Special Population Notices'),
          _body(
            '3.1 Pregnant and Breastfeeding Women\n'
            '• Some wellness suggestions (such as acupoint pressure, herbal diet therapy) may not be suitable during pregnancy\n'
            '• Please consult an obstetrician before using this app\n'
            '• If you experience any discomfort, stop using the app immediately and seek medical attention\n\n'
            '3.2 Chronic Disease Patients\n'
            '• Users with chronic conditions such as hypertension, diabetes, or heart disease should use this app under medical guidance\n'
            '• The app\'s wellness suggestions cannot replace or modify treatment plans established by your doctor\n'
            '• Do not adjust medication dosages on your own based on the app\'s suggestions\n\n'
            '3.3 Post-Surgery Recovery\n'
            '• Post-surgery users should strictly follow their doctor\'s orders\n'
            '• Exercise and diet recommendations should be confirmed with your treating physician before execution\n\n'
            '3.4 Children\n'
            '• This app is not intended for children under 14 years of age\n'
            '• Adolescents should use the app under the supervision and guidance of a guardian',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('4. Emergency Situations'),
          _body(
            'If you experience any of the following, please call emergency services (911 or your local emergency number) or go to the nearest medical facility immediately:\n\n'
            '• Chest pain, difficulty breathing\n'
            '• Severe bleeding or trauma\n'
            '• Sudden severe headache, confusion\n'
            '• Severe allergic reactions (difficulty breathing, swelling)\n'
            '• Persistent high fever (above 39°C / 102°F)\n'
            '• Any other life-threatening symptoms\n\n'
            'This app does not provide emergency medical services and cannot be used to handle emergency health conditions.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('5. Limitation of Liability'),
          _body(
            '5.1 You understand and agree that the developer is not responsible for any direct or indirect losses resulting from the use of the app\'s content.\n\n'
            '5.2 You are responsible for using the app reasonably based on your own health condition and seeking professional medical help when necessary.\n\n'
            '5.3 If you have health concerns arising from the app\'s wellness suggestions, please consult a doctor immediately.',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('6. Contact'),
          _body(
            'For questions about this medical disclaimer:\n'
            '• Email: legal@shunshi.app\n'
            '• Support: support@shunshi.app',
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

  Widget _warningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: ShunShiColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Important: This app provides traditional wellness suggestions, not medical diagnoses. If you have health concerns, please consult a qualified healthcare professional.',
              style: TextStyle(
                fontSize: 14,
                color: ShunShiColors.warning,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
