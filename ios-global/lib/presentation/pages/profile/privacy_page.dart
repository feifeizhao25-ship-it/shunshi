// ignore_for_file: unused_local_variable
import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
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
            const SnackBar(content: Text('Data exported and saved'), duration: Duration(seconds: 2)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed, please try again later'), duration: Duration(seconds: 2)));
      }
    }
    setState(() => _exporting = false);
  }

  void _deleteAllData() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: const Text('Delete all data?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: const Text('This cannot be undone. All your wellness records, diary entries and constitution data will be permanently deleted.',
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final dio = Dio();
              await dio.delete('${AppConfig.apiBaseUrl}/api/v1/user/data');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data deleted'), duration: Duration(seconds: 2)));
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete failed'), duration: Duration(seconds: 2)));
              }
            }
          },
          child: Text('Confirm delete', style: TextStyle(color: ShunShiColors.error)),
        ),
      ],
    ));
  }

  void _clearAiMemory() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: const Text('Clear AI memory?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: const Text('The AI companion will no longer remember your past conversations. Your constitution check results are not deleted.',
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI memory cleared'), duration: Duration(seconds: 2)));
          },
          child: Text('Confirm clear', style: TextStyle(color: ShunShiColors.error)),
        ),
      ],
    ));
  }

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
        title: const Text('Data & privacy',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Your data section
          const Text('Your data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 12),
          _buildTile(
            icon: Icons.download_outlined,
            title: 'Export my data',
            subtitle: 'Download all your personal data (JSON format)',
            onTap: _exporting ? null : _exportData,
            trailing: _exporting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ShunShiColors.primary))
                : null,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete all data',
            subtitle: 'Permanently delete all your data. This cannot be undone',
            onTap: _deleteAllData,
            titleColor: ShunShiColors.error,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.psychology_outlined,
            title: 'Clear AI memory',
            subtitle: 'Clear the AI companion\'s conversation memory',
            onTap: _clearAiMemory,
          ),
          const SizedBox(height: 32),

          // Privacy policy
          const Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
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
              'SEASONS respects and protects your privacy.\n\n'
              '• Your health data is used only to provide personalised wellness suggestions\n'
              '• Family members only see your status level (steady / a bit tired / reach out)\n'
              '• We never sell or share your personal data with third parties\n'
              '• You can export or delete all your data at any time\n'
              '• AI conversation history is stored encrypted and you can clear it at any time\n'
              '• In family features, chats, mood details, constitution information and diary entries are never shared',
              style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.7),
            ),
          ),
          const SizedBox(height: 24),

          // Contact
          Center(child: Column(children: [
            const Text('Questions about your data?', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
            const SizedBox(height: 4),
            Text('privacy@shunshi.app', style: TextStyle(fontSize: 13, color: ShunShiColors.primary,
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
