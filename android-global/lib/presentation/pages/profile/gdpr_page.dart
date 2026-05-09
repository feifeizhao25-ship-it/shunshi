import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

class GdprPage extends StatelessWidget {
  const GdprPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'GDPR Privacy Policy',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ShunShiColors.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShunShiColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Effective Date', 'January 1, 2025'),
          const SizedBox(height: 16),
          _section('Data We Collect', null),
          _bullet('Device info (OS, model, app version)'),
          _bullet('Usage statistics (pages visited, features used)'),
          _bullet('Wellness preferences (selected body type, concerns)'),
          _bullet('Chat history (stored locally only)'),
          _noCollection(),
          const SizedBox(height: 16),
          _section('Your Rights', null),
          _bullet('Right to access your data'),
          _bullet('Right to delete your data'),
          _bullet('Right to data portability (coming soon)'),
          _bullet('Right to withdraw consent'),
          const SizedBox(height: 12),
          _deleteButton(context),
          const SizedBox(height: 16),
          _section('Data Retention', null),
          _bullet('Data stored: locally on device only'),
          _bullet('Retention period: until you delete the app'),
          _bullet('No cloud backup'),
          const SizedBox(height: 16),
          _section('Contact', null),
          _bullet('Data Protection Officer: privacy@seasons-app.com'),
          _bullet('Response time: 30 days'),
          const SizedBox(height: 16),
          _section('Legal Basis', null),
          _bullet('GDPR Art. 6(1)(a) — Consent'),
          _bullet('GDPR Art. 6(1)(b) — Contract performance'),
          _bullet('GDPR Art. 7 — Conditions for consent'),
          _bullet('GDPR Art. 17 — Right to erasure'),
          _bullet('GDPR Art. 20 — Right to data portability'),
          _bullet('GDPR Art. 21 — Right to object'),
          const SizedBox(height: 32),
          Text(
            'SEASONS — Live in harmony with nature',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 13,
              color: ShunShiColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ShunShiColors.primary,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 14,
                color: ShunShiColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 14,
                color: ShunShiColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noCollection() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We do NOT collect:',
            style: TextStyle(
              fontFamily: ShunShiTypography.sansFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ShunShiColors.textTertiary,
            ),
          ),
          _bullet('Location data'),
          _bullet('Third-party analytics'),
          _bullet('Advertising identifiers'),
        ],
      ),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_forever, size: 18),
        label: Text(AppLocalizations.of(context).t('profile_delete_all_my_data')),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _confirmDelete(context),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('profile_delete_all_data')),
        content: const Text(
          'This will clear all your preferences, wellness data, and chat history from this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).t('cancel'))),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).t('profile_all_data_has_been_deleted'))),
                );
              }
            },
            child: Text(AppLocalizations.of(context).t('delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
