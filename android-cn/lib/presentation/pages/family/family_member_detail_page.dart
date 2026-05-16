import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/config/app_config.dart';

/// 家庭成员详情页 — 仅显示状态级别信息（隐私优先）
class FamilyMemberDetailPage extends StatefulWidget {
  final String memberId;
  const FamilyMemberDetailPage({super.key, required this.memberId});

  @override
  State<FamilyMemberDetailPage> createState() => _FamilyMemberDetailPageState();
}

class _FamilyMemberDetailPageState extends State<FamilyMemberDetailPage> {
  Map<String, dynamic>? _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    try {
      final dio = Dio();
      final res = await dio.get('${AppConfig.apiBaseUrl}/api/v1/family/members/${widget.memberId}');
      if (res.data != null) {
        setState(() {
          _member = Map<String, dynamic>.from(res.data);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Demo
    setState(() {
      _member = {
        'id': widget.memberId,
        'name': '妈妈',
        'avatar': '👩',
        'relation': '母亲',
        'status': 'stable',
        'lastActive': '今天 08:30',
        'lastCheckin': '3小时前',
      };
      _loading = false;
    });
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'stable': return '🟢';
      case 'tired': return '🟡';
      case 'attention': return '🔴';
      default: return '🟢';
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'stable': return '平稳';
      case 'tired': return '有点累';
      case 'attention': return '建议联系';
      default: return '平稳';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'stable': return ShunShiColors.success;
      case 'tired': return ShunShiColors.warning;
      case 'attention': return ShunShiColors.error;
      default: return ShunShiColors.success;
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
        title: Text(_member?['name'] ?? '家人详情',
            style: const TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Avatar & name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ShunShiColors.borderGhost),
                  ),
                  child: Column(children: [
                    Text(_member?['avatar'] ?? '👤', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(_member?['name'] ?? '', style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.serifFamily)),
                    const SizedBox(height: 4),
                    Text(_member?['relation'] ?? '', style: const TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
                  ]),
                ),
                const SizedBox(height: 20),

                // Status card — only status-level info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ShunShiColors.borderGhost),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('状态信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        fontFamily: ShunShiTypography.serifFamily)),
                    const SizedBox(height: 16),
                    _infoRow('当前状态',
                        '${_statusEmoji(_member?['status'] ?? 'stable')} ${_statusText(_member?['status'] ?? 'stable')}',
                        _statusColor(_member?['status'] ?? 'stable')),
                    const SizedBox(height: 12),
                    _infoRow('最近活跃', _member?['lastActive'] ?? '未知', ShunShiColors.textSecondary),
                    const SizedBox(height: 12),
                    _infoRow('上次打卡', _member?['lastCheckin'] ?? '未知', ShunShiColors.textSecondary),
                  ]),
                ),
                const SizedBox(height: 20),

                // Privacy notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.lock_outline, size: 16, color: ShunShiColors.textTertiary),
                    SizedBox(width: 8),
                    Expanded(child: Text('隐私保护：你只能看到状态级别信息',
                        style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary))),
                  ]),
                ),
                const SizedBox(height: 24),

                // Send care reminder
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已发送关怀提醒'), duration: Duration(seconds: 1)));
                    },
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: const Text('发送关怀提醒'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShunShiColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // View what they see about you
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('对方看到的是同样的状态卡片'), duration: Duration(seconds: 2)));
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('查看我的状态（对方视角）'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ShunShiColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
      Text(value, style: TextStyle(fontSize: 14, color: valueColor, fontWeight: FontWeight.w500)),
    ]);
  }
}
