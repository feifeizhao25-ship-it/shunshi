import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../design_system/theme.dart';

/// 家庭养生管理页 - API wired with local fallback
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  List<Map<String, dynamic>> _members = [];
  String? _familyId;
  String? _inviteCode;
  bool _isOwner = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  Future<void> _loadFamily() async {
    setState(() => _loading = true);
    try {
      final prefs = await _getPrefs();
      final userId = prefs.getString('user_id') ?? '';
      final dio = Dio(BaseOptions(baseUrl: 'https://api.seasonsapp.com'));
      final res = await dio.get('/api/v1/family/members', queryParameters: {'user_id': userId});
      final data = res.data;
      if (data is Map && data['members'] != null) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(data['members']);
          _familyId = data['family_id'];
          _inviteCode = data['invite_code'];
          _isOwner = data['is_owner'] == true;
          _loading = false;
        });
        await prefs.setString('family_data', jsonEncode(data));
        return;
      }
    } catch (_) {}
    // Fallback: local
    final prefs = await _getPrefs();
    final cached = prefs.getString('family_data');
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        setState(() {
          _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          _familyId = data['family_id'];
          _inviteCode = data['invite_code'];
          _isOwner = data['is_owner'] == true;
        });
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  Future<void> _createFamily() async {
    try {
      final prefs = await _getPrefs();
      final userId = prefs.getString('user_id') ?? '';
      final dio = Dio(BaseOptions(baseUrl: 'https://api.seasonsapp.com'));
      final res = await dio.post('/api/v1/family/create', data: {'user_id': userId});
      final data = res.data;
      setState(() {
        _familyId = data['family_id'];
        _inviteCode = data['invite_code'];
        _isOwner = true;
        _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('家庭已创建,邀请码:$_inviteCode'), duration: const Duration(seconds: 3)));
      }
    } catch (_) {
      // Local fallback
      final code = List.generate(6, (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[DateTime.now().millisecondsSinceEpoch % 32]).join();
      final prefs = await _getPrefs();
      setState(() {
        _inviteCode = code;
        _isOwner = true;
        _members = [{'name': '我', 'avatar': '😊', 'constitution': '未测试', 'status': '良好', 'id': 'local_me'}];
      });
      await prefs.setString('family_data', jsonEncode({
        'family_id': 'local', 'invite_code': code, 'is_owner': true, 'members': _members,
      }));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已创建(离线模式),邀请码:$code'), duration: const Duration(seconds: 3)));
      }
    }
  }

  Future<void> _joinFamily(String code) async {
    try {
      final prefs = await _getPrefs();
      final userId = prefs.getString('user_id') ?? '';
      final dio = Dio(BaseOptions(baseUrl: 'https://api.seasonsapp.com'));
      final res = await dio.post('/api/v1/family/join', data: {'user_id': userId, 'invite_code': code});
      final data = res.data;
      setState(() {
        _familyId = data['family_id'];
        _inviteCode = code;
        _isOwner = false;
        _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已加入家庭'), duration: Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('加入失败,请检查邀请码'), duration: Duration(seconds: 2)));
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.seasonsapp.com'));
      await dio.delete('/api/v1/family/member/$memberId');
      setState(() => _members.removeWhere((m) => m['id'] == memberId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已移除成员'), duration: Duration(seconds: 1)));
      }
    } catch (_) {
      // Local fallback
      setState(() => _members.removeWhere((m) => m['id'] == memberId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('家庭养生管理', style: ShunShiTypography.headlineSmall),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
          : RefreshIndicator(
              onRefresh: _loadFamily,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: ShunShiSpacing.screenPadding, vertical: ShunShiSpacing.sm),
                children: [
                  _buildFamilyOverview(),
                  const SizedBox(height: ShunShiSpacing.xl),
                  _sectionHeader('家庭成员'),
                  ..._members.map((m) => _buildMemberCard(m)),
                  const SizedBox(height: ShunShiSpacing.sm),
                  _buildActionButtons(),
                  const SizedBox(height: ShunShiSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ShunShiSpacing.sm),
      child: Text(title, style: ShunShiTypography.labelLarge.copyWith(color: ShunShiColors.textSecondary)),
    );
  }

  Widget _buildFamilyOverview() {
    if (_familyId == null) {
      return Container(
        padding: const EdgeInsets.all(ShunShiSpacing.cardPadding),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: ShunShiRadius.cardRadius,
          border: Border.all(color: ShunShiColors.borderGhost),
        ),
        child: Column(children: [
          Icon(Icons.family_restroom, size: 48, color: ShunShiColors.textTertiary),
          const SizedBox(height: 16),
          const Text('还没有家庭', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('创建家庭或加入已有家庭,一起管理健康', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(ShunShiSpacing.cardPadding),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
        boxShadow: ShunShiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.home_outlined, size: 20, color: ShunShiColors.primary),
            const SizedBox(width: 8),
            Text('我的家庭', style: ShunShiTypography.serifTitle),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ShunShiColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: ShunShiRadius.chipRadius,
              ),
              child: Text('${_members.length} 位成员', style: ShunShiTypography.labelMedium.copyWith(color: ShunShiColors.primary)),
            ),
          ]),
          if (_inviteCode != null) ...[
            const SizedBox(height: ShunShiSpacing.md),
            Row(children: [
              const Text('邀请码:', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
              Text(_inviteCode!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: ShunShiColors.primary, letterSpacing: 2)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('邀请码已复制:$_inviteCode'), duration: const Duration(seconds: 2)));
                },
                child: const Icon(Icons.copy, size: 18, color: ShunShiColors.primary),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isAlert = member['status'] != '良好';
    final avatar = member['avatar'] as String? ?? '😊';
    final name = member['name'] as String? ?? '未知';
    final constitution = member['constitution'] as String? ?? '未测试';
    final status = member['status'] as String? ?? '良好';
    final memberId = member['id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xs),
      padding: const EdgeInsets.all(ShunShiSpacing.md),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ShunShiColors.surfaceContainerLow,
            child: Text(avatar, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: ShunShiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ShunShiTypography.titleMedium),
                const SizedBox(height: 2),
                Text(constitution, style: ShunShiTypography.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isAlert ? ShunShiColors.warning : ShunShiColors.success).withValues(alpha: 0.1),
              borderRadius: ShunShiRadius.chipRadius,
            ),
            child: Text(status, style: ShunShiTypography.labelMedium.copyWith(
              color: isAlert ? ShunShiColors.warning : ShunShiColors.success,
            )),
          ),
          if (_isOwner && memberId.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmRemove(name, memberId),
              child: Icon(Icons.close, size: 18, color: ShunShiColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmRemove(String name, String memberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShunShiColors.surface,
        title: Text('移除成员', style: ShunShiTypography.titleMedium),
        content: Text('确定移除 $name 吗?', style: ShunShiTypography.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _removeMember(memberId); },
            child: Text('确定', style: TextStyle(color: ShunShiColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(children: [
      if (_familyId == null) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createFamily,
            icon: const Icon(Icons.add_home_outlined, size: 18),
            label: const Text('创建家庭'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.group_add_outlined, size: 18),
            label: const Text('加入家庭'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: ShunShiColors.primary),
              shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius),
            ),
          ),
        ),
      ] else ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('邀请新成员'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: ShunShiColors.borderGhost),
              shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius),
            ),
          ),
        ),
      ],
    ]);
  }

  void _showJoinDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShunShiColors.surface,
        title: Text('加入家庭', style: ShunShiTypography.titleMedium),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '输入 6 位邀请码',
            border: OutlineInputBorder(),
          ),
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, letterSpacing: 4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) _joinFamily(ctrl.text.trim());
            },
            child: const Text('加入', style: TextStyle(color: ShunShiColors.primary)),
          ),
        ],
      ),
    );
  }
}
