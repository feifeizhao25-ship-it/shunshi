import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/network/api_client.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';

/// 家庭主页 — 隐私优先，仅显示状态级别信息
class FamilyHomePage extends StatefulWidget {
  const FamilyHomePage({super.key});

  @override
  State<FamilyHomePage> createState() => _FamilyHomePageState();
}

class _FamilyHomePageState extends State<FamilyHomePage> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final api = ApiClient();
      final res = await api.get('/api/v1/family/members');
      if (res.data is List) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(res.data);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Demo
    setState(() {
      _members = [
        {'id': '1', 'name': '妈妈', 'avatar': '👩', 'relation': '母亲', 'status': 'stable', 'lastActive': '今天 08:30', 'lastCheckin': '3小时前'},
        {'id': '2', 'name': '爸爸', 'avatar': '👨', 'relation': '父亲', 'status': 'tired', 'lastActive': '今天 07:15', 'lastCheckin': '5小时前'},
        {'id': '3', 'name': '奶奶', 'avatar': '👵', 'relation': '其他', 'status': 'attention', 'lastActive': '昨天 22:00', 'lastCheckin': '1天前'},
      ];
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
      case 'attention': return AppColors.error(context);
      default: return ShunShiColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('我的家人',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, size: 22),
            onPressed: () => context.push('/family-invite'),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary(context)))
          : RefreshIndicator(
              color: AppColors.primary(context),
              onRefresh: _loadMembers,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Add member button
                  GestureDetector(
                    onTap: () => context.push('/family-invite'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary(context).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary(context).withValues(alpha: 0.15)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.person_add_rounded, size: 20, color: AppColors.primary(context)),
                        SizedBox(width: 8),
                        Text('邀请家人加入', style: TextStyle(fontSize: 15,
                            color: AppColors.primary(context), fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),

                  // Privacy notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.textTertiary(context)),
                      SizedBox(width: 8),
                      Expanded(child: Text('隐私保护：仅共享状态级别信息，不会暴露详细数据',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context), height: 1.4))),
                    ]),
                  ),

                  // Member list
                  if (_members.isEmpty)
                    Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text('还没有家人加入', style: TextStyle(color: AppColors.textTertiary(context), fontSize: 15)),
                    ))
                  else
                    ..._members.map((m) => _buildMemberCard(m)),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> m) {
    final status = m['status'] ?? 'stable';
    return GestureDetector(
      onTap: () => context.push('/family-member/${m['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textTertiary(context).withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(m['avatar'] ?? '👤', style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['name'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context))),
            const SizedBox(height: 2),
            Text('${m['relation'] ?? ''} · ${_statusText(status)}',
                style: TextStyle(fontSize: 13, color: _statusColor(status))),
          ])),
          Text(_statusEmoji(status), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary(context)),
        ]),
      ),
    );
  }
}
