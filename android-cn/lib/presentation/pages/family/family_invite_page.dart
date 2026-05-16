import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../../core/config/app_config.dart';

class FamilyInvitePage extends StatefulWidget {
  const FamilyInvitePage({super.key});

  @override
  State<FamilyInvitePage> createState() => _FamilyInvitePageState();
}

class _FamilyInvitePageState extends State<FamilyInvitePage> {
  String? _code;
  bool _loading = true;
  List<Map<String, String>> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _generateCode();
    _loadFamilyMembers();
  }

  Future<void> _generateCode() async {
    try {
      final dio = Dio();
      final res = await dio.post('${AppConfig.apiBaseUrl}/api/v1/family/invite');
      if (res.data?['code'] != null) {
        setState(() {
          _code = res.data['code'];
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Fallback: generate random code
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _code = List.generate(6, (i) => chars[(rng + i * 7) % chars.length]).join();
      _loading = false;
    });
  }

  Future<void> _loadFamilyMembers() async {
    // Try backend first, fallback to demo
    try {
      final dio = Dio();
      final res = await dio.get('${AppConfig.apiBaseUrl}/api/v1/family/members');
      if (res.data?['members'] != null) {
        final members = (res.data['members'] as List)
            .map((m) => Map<String, String>.from(m as Map))
            .toList();
        if (mounted) setState(() => _familyMembers = members);
        return;
      }
    } catch (_) {}
    // Demo data
    if (mounted) {
      setState(() {
        _familyMembers = [
          {'name': '我', 'relation': '本人', 'avatar': '👤'},
        ];
      });
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('邀请码已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareCode() {
    // Use clipboard as simple share mechanism (no share_plus dependency)
    final text = '我在使用「顺时」养生App，邀请你一起加入！邀请码：${_code ?? ''}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('邀请内容已复制，粘贴发送给家人即可'),
        duration: Duration(seconds: 2),
      ),
    );
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
          '家人管理',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily),
        ),
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
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ShunShiColors.borderGhost),
                    ),
                    child: Column(
                      children: [
                        const Text('邀请码', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
                        const SizedBox(height: 16),
                        Text(
                          _code ?? '',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            fontFamily: ShunShiTypography.sansFamily,
                            color: ShunShiColors.primary,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '将此邀请码分享给家人\n对方在「我的家人」页面输入即可加入',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Copy + Share buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('复制邀请码'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: ShunShiColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _shareCode,
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('分享给家人'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ShunShiColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Family members list
                  Text(
                    '已加入家人',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary,
                      fontFamily: ShunShiTypography.serifFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._familyMembers.map((member) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: ShunShiColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  member['avatar'] ?? '👤',
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: ShunShiColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    member['relation'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ShunShiColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _generateCode();
                    },
                    child: const Text(
                      '重新生成邀请码',
                      style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
