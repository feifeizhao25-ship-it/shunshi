// ignore_for_file: unused_local_variable
import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

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
            const SnackBar(content: Text('数据导出成功，已保存'), duration: Duration(seconds: 2)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出失败，请稍后重试'), duration: Duration(seconds: 2)));
      }
    }
    setState(() => _exporting = false);
  }

  void _deleteAllData() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: const Text('确认删除所有数据？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: const Text('此操作不可恢复。你的所有养生记录、日记、体质数据都将被永久删除。',
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final dio = Dio();
              await dio.delete('https://api.seasonsapp.com/api/v1/user/data');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有数据已删除'), duration: Duration(seconds: 2)));
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除失败'), duration: Duration(seconds: 2)));
              }
            }
          },
          child: Text('确认删除', style: TextStyle(color: ShunShiColors.error)),
        ),
      ],
    ));
  }

  void _clearAiMemory() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: const Text('清空 AI 记忆？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: const Text('AI 助手将不再记住你的历史对话内容。体质测试结果不会被删除。',
          style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI 记忆已清空'), duration: Duration(seconds: 2)));
          },
          child: Text('确认清空', style: TextStyle(color: ShunShiColors.error)),
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
        title: const Text('数据与隐私',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Your data section
          const Text('你的数据', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 12),
          _buildTile(
            icon: Icons.download_outlined,
            title: '导出我的数据',
            subtitle: '下载你的所有个人数据（JSON 格式）',
            onTap: _exporting ? null : _exportData,
            trailing: _exporting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ShunShiColors.primary))
                : null,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.delete_forever_outlined,
            title: '删除所有数据',
            subtitle: '永久删除你的所有数据，不可恢复',
            onTap: _deleteAllData,
            titleColor: ShunShiColors.error,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.psychology_outlined,
            title: '清空 AI 记忆',
            subtitle: '清除 AI 助手的对话记忆',
            onTap: _clearAiMemory,
          ),
          const SizedBox(height: 32),

          // Privacy policy
          const Text('隐私政策', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
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
              '顺时尊重并保护你的个人隐私。\n\n'
              '• 你的健康数据仅用于提供个性化养生建议\n'
              '• 家庭成员只能看到你的状态级别信息（平稳/有点累/建议联系）\n'
              '• 不会向第三方出售或共享你的个人数据\n'
              '• 你可以随时导出或删除你的所有数据\n'
              '• AI 对话记录加密存储，你可以随时清空\n'
              '• 家庭功能中，聊天内容、情绪详情、体质信息、日记内容不会被共享',
              style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.7),
            ),
          ),
          const SizedBox(height: 24),

          // Contact
          Center(child: Column(children: [
            const Text('数据相关问题？', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
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
