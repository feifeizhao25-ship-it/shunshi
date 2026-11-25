import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/family_api.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../widgets/cn_back_button.dart';

class FamilyInvitePage extends StatefulWidget {
  const FamilyInvitePage({super.key, this.api});

  final FamilyApi? api;

  @override
  State<FamilyInvitePage> createState() => _FamilyInvitePageState();
}

class _FamilyInvitePageState extends State<FamilyInvitePage> {
  String _inviteCode = '';
  List<Map<String, String>> _members = [];
  bool _loading = true;
  bool _failed = false;
  late final FamilyApi _api = widget.api ?? FamilyApi();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final body = await _api.load();
      final members = <Map<String, String>>[];
      for (final raw in body['members'] as List) {
        if (raw is! Map) continue;
        members.add({'name': '${raw['name'] ?? ''}', 'relation': '${raw['relation'] ?? ''}'});
      }
      if (!mounted) return;
      setState(() {
        _inviteCode = (body['invite_code'] as String?)?.trim() ?? '';
        _members = members;
        _failed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inviteCode = '';
        _members = [];
        _failed = true;
        _loading = false;
      });
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
        leading: CnBackButton(icon: const Icon(Icons.arrow_back, color: ShunShiColors.textPrimary), onPressed: () => safePop(context)),
        title: const Text('家人管理', style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invite code card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [ShunShiColors.primary, ShunShiColors.secondary]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.family_restroom, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        const Text('邀请家人一起养生', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('分享邀请码，让家人也能获得个性化健康建议', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(_inviteCode.isEmpty ? '还没有邀请码' : _inviteCode, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                            const SizedBox(width: 12),
                            IconButton(tooltip: '复制邀请码', icon: const Icon(Icons.copy, color: Colors.white), onPressed: _copyCode),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _copyCode,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('复制邀请码分享给家人'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ShunShiColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Family members list
                  const Text('已添加的家人', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 16),
                        if (_failed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      child: const Text('家人列表暂时读不到，请确认已登录后重试', textAlign: TextAlign.center),
                    )
                  else if (_members.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ShunShiColors.border)),
                      child: Column(children: [
                        Icon(Icons.people_outline, size: 48, color: ShunShiColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('还没有添加家人', style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('分享邀请码邀请家人加入', style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 13)),
                      ]),
                    )
                  else
                    ..._members.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.border)),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: ShunShiColors.primary.withValues(alpha: 0.1), child: Text(m['name']?[0] ?? '?', style: const TextStyle(color: ShunShiColors.primary, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
                          Text(m['relation'] ?? '', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                        ])),
                        Icon(Icons.chevron_right, color: ShunShiColors.textTertiary),
                      ]),
                    )),
                  const SizedBox(height: 24),
                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, color: ShunShiColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text('家人只能看到您的健康状态概览（平稳/有点累/需要关心），不会看到具体日记内容，保护您的隐私。', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5))),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }

  void _copyCode() {
    if (_inviteCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('邀请码已复制'), duration: Duration(seconds: 2)),
    );
  }
}
