import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/config/app_config.dart';

/// 隐私数据页 — 导出/删除/清空
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, this.request});

  final Future<Response<dynamic>> Function(String, String)? request;

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _exporting = false;
  bool _deleting = false;

  Future<Response<dynamic>> _request(String method, String path) async {
    if (widget.request != null) return widget.request!(method, path);
    final token = StorageManager.user.getToken();
    if (token == null || token.isEmpty) throw StateError('请先登录');
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    try {
      return await dio.request<dynamic>(path, options: Options(method: method));
    } finally {
      dio.close();
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final response = await _request('POST', '/api/v1/auth/data/export');
      if (response.data is! Map || response.data['user'] == null) {
        throw StateError('导出数据无效');
      }
      final json = const JsonEncoder.withIndent('  ').convert(response.data);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('我的账户数据'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(json, style: const TextStyle(fontSize: 12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: json));
                  _message('数据已复制，请粘贴到你选择的安全位置保存');
                } catch (_) {
                  _message('复制失败，请重试');
                }
              },
              child: const Text('复制 JSON'),
            ),
          ],
        ),
      );
    } catch (_) {
      _message('导出失败，请确认已登录后重试');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认注销账号？'),
        content: const Text(
          '注销将删除登录账号及核心账户资料，无法恢复。支付与退款申请记录仍保留，注销不会自动退款。建议先查看并保存账户数据。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    var deleted = false;
    try {
      final response = await _request('DELETE', '/api/v1/auth/account');
      if (response.data is! Map || response.data['deleted'] != true) {
        throw StateError('注销尚未确认');
      }
      deleted = true;
      await StorageManager.clearAll();
      await tokenStorage.clearTokens();
      if (mounted) context.go('/login');
    } catch (_) {
      _message(deleted ? '账号已注销，本机清理未完成，请退出并清理本机数据' : '注销未确认，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _clearAiMemory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空对话记忆？'),
        content: const Text('将清除服务端对话与个性化记忆，请确认不再需要这些记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final response = await _request('DELETE', '/api/v1/memory/all');
      if (response.data is! Map || response.data['deleted'] != true) {
        throw StateError('清空尚未确认');
      }
      _message('服务端对话记忆已清空');
    } catch (_) {
      _message('清空未确认，请检查登录状态和网络后重试');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          '数据与隐私',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Your data section
          const Text(
            '你的数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTile(
            icon: Icons.download_outlined,
            title: '导出我的数据',
            subtitle: '查看账户数据及国内付款、退款申请记录，可复制 JSON',
            onTap: (_exporting || _deleting) ? null : _exportData,
            trailing: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ShunShiColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.delete_forever_outlined,
            title: '注销账号',
            subtitle: '删除核心账号资料；支付记录保留，退款不自动执行',
            onTap: (_deleting || _exporting) ? null : _deleteAllData,
            titleColor: ShunShiColors.error,
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.psychology_outlined,
            title: '清空 AI 记忆',
            subtitle: '清除 AI 助手的对话记忆',
            onTap: (_deleting || _exporting) ? null : _clearAiMemory,
          ),
          const SizedBox(height: 32),

          // Privacy policy
          const Text(
            '数据操作说明',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ShunShiColors.borderGhost),
            ),
            child: const Text(
              '顺时尊重并保护你的个人隐私。\n\n'
              '• 导出提供核心账户数据及国内支付、退款申请记录\n'
              '• 注销不会自动完成退款，支付与退款申请记录仍保留\n'
              '• 清空记忆需要服务端确认，操作失败可重试',
              style: TextStyle(
                fontSize: 13,
                color: ShunShiColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact
          Center(
            child: Column(
              children: [
                const Text(
                  '数据相关问题？',
                  style: TextStyle(
                    fontSize: 13,
                    color: ShunShiColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'privacy@shunshi.app',
                  style: TextStyle(
                    fontSize: 13,
                    color: ShunShiColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? titleColor,
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: titleColor ?? ShunShiColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? ShunShiColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: ShunShiColors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}
