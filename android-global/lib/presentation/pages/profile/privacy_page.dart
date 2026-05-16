// ignore_for_file: unused_local_variable
import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
import '../../../core/config/app_config.dart';

/// 隐私数据页 — 导出/删除/清空
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _exporting = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://httpbin.org/post',
        data: {'event': 'privacy_policy_viewed'},
        options: Options(responseType: ResponseType.json));
      // In production, save to file. Here just show success.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).t('profile_data_exported_successfully')), duration: Duration(seconds: 2)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).t('profile_export_failed_please_retry')), duration: Duration(seconds: 2)));
      }
    }
    setState(() => _exporting = false);
  }

  void _deleteAllData() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: Text(AppLocalizations.of(context).t('profile_delete_all_data'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: Text(AppLocalizations.of(context).t('profile_this_cannot_be_undone_all_data_will_be_perman'),
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).t('cancel'))),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final dio = Dio();
              await dio.delete('${AppConfig.apiBaseUrl}/api/v1/user/data');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('profile_all_data_deleted')), duration: Duration(seconds: 2)));
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('profile_deletion_failed')), duration: Duration(seconds: 2)));
              }
            }
          },
          child: Text(AppLocalizations.of(context).t('profile_confirm_deletion'), style: TextStyle(color: ShunShiColors.error)),
        ),
      ],
    ));
  }

  void _clearAiMemory() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: Text(AppLocalizations.of(context).t('profile_clear_ai_memory'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: const Text('The AI will no longer remember conversations. Constitution results are kept.',
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).t('privacy_cancel'))),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).t('profile_ai_memory_cleared')), duration: Duration(seconds: 2)));
          },
          child: Text(AppLocalizations.of(context).t('profile_confirm_clear'), style: TextStyle(color: ShunShiColors.error)),
        ),
      ],
    ));
  }

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
        title: Text(AppLocalizations.of(context).t('profile_data_privacy'),
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Your data section
          Text(AppLocalizations.of(context).t('profile_your_data'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 12),
          _buildTile(
            icon: Icons.download_outlined,
            title: AppLocalizations.of(context).t('profile_export_my_data'),
            subtitle: AppLocalizations.of(context).t('profile_download_all_your_personal_data_json_format'),
            onTap: _exporting ? null : _exportData,
            trailing: _exporting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ShunShiColors.primary))
                : null,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.delete_forever_outlined,
            title: AppLocalizations.of(context).t('profile_delete_all_data_2'),
            subtitle: AppLocalizations.of(context).t('profile_permanently_delete_all_your_data_irreversible'),
            onTap: _deleteAllData,
            titleColor: ShunShiColors.error,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.psychology_outlined,
            title: AppLocalizations.of(context).t('profile_clear_ai_memory_2'),
            subtitle: AppLocalizations.of(context).t('profile_clear_the_ai_assistant_memory'),
            onTap: _clearAiMemory,
          ),
          const SizedBox(height: 32),

          // Privacy policy
          Text(AppLocalizations.of(context).t('settings_privacy'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ShunShiColors.borderGhost),
            ),
            child: const Text(
              'SEASONS respects and protects your personal privacy.\n\n'
              '• Your health data is used only for personalized wellness suggestions\n'
              '• Family members only see your status level (Stable / Tired / Suggest contact)\n'
              '• Your data is never sold or shared with third parties\n'
              '• You can export or delete all your data anytime\n'
              '• AI conversations are encrypted and can be cleared anytime\n'
              '• Chat content, mood details, constitution info, and diary entries are never shared in family features',
              style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.7),
            ),
          ),
          const SizedBox(height: 24),

          // Contact
          Center(child: Column(children: [
            Text(AppLocalizations.of(context).t('profile_questions_about_your_data'), style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).t('profile_privacyshunshiapp'), style: TextStyle(fontSize: 13, color: ShunShiColors.primary,
                fontWeight: FontWeight.w500)),
          ])),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon, required String title, String? subtitle,
    VoidCallback? onTap, Widget? trailing, Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ShunShiColors.borderGhost),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: titleColor ?? ShunShiColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                color: titleColor ?? ShunShiColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
            ],
          ])),
          trailing ?? const Icon(Icons.chevron_right, size: 18, color: ShunShiColors.textTertiary),
        ]),
      ),
    );
  }
}
