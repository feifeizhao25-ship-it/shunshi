import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class FamilyInvitePage extends StatefulWidget {
  const FamilyInvitePage({super.key});

  @override
  State<FamilyInvitePage> createState() => _FamilyInvitePageState();
}

class _FamilyInvitePageState extends State<FamilyInvitePage> {
  String _inviteCode = '';
  List<Map<String, String>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Generate or load invite code
    var code = prefs.getString('family_invite_code');
    if (code == null || code.isEmpty) {
      code = 'SS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await prefs.setString('family_invite_code', code);
    }
    // Load existing members
    final membersRaw = prefs.getString('family_members');
    List<Map<String, String>> members = [];
    if (membersRaw != null) {
      // Simple format: "name1:relation1,name2:relation2"
      for (final entry in membersRaw.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          members.add({'name': parts[0], 'relation': parts[1]});
        }
      }
    }
    if (mounted) {
      setState(() {
        _inviteCode = code!;
        _members = members;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)), onPressed: () => safePop(context)),
        title: Text('Family', style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary(context)))
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
                      gradient: LinearGradient(colors: [AppColors.primary(context), ShunShiColors.secondary]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.family_restroom, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text('Invite family to practise wellness together', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Share an invite code so your family can get personalised health tips too', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(_inviteCode, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                            const SizedBox(width: 12),
                            IconButton(icon: Icon(Icons.copy, color: Colors.white), onPressed: _copyCode),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _copyCode,
                          icon: Icon(Icons.share, size: 18),
                          label: const Text('Copy the invite code and share it with your family'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Family members list
                  Text('Family members added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                  const SizedBox(height: 16),
                  if (_members.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
                      child: Column(children: [
                        Icon(Icons.people_outline, size: 48, color: AppColors.textTertiary(context)),
                        const SizedBox(height: 12),
                        Text('No family members added yet', style: TextStyle(color: AppColors.textTertiary(context), fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Share the invite code to invite family', style: TextStyle(color: AppColors.textTertiary(context), fontSize: 13)),
                      ]),
                    )
                  else
                    ..._members.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: AppColors.primary(context).withValues(alpha: 0.1), child: Text(m['name']?[0] ?? '?', style: TextStyle(color: AppColors.primary(context), fontWeight: FontWeight.w600))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['name'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary(context))),
                          Text(m['relation'] ?? '', style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context))),
                        ])),
                        Icon(Icons.chevron_right, color: AppColors.textTertiary(context)),
                      ]),
                    )),
                  const SizedBox(height: 24),
                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.primary(context).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, color: AppColors.primary(context), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Family members only see an overview of your health status (steady / a bit tired / needs care) — never your diary entries. Your privacy is protected.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context), height: 1.5))),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied'), duration: Duration(seconds: 2)),
    );
  }
}
