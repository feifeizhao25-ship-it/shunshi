import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: ShunShiColors.textPrimary), onPressed: () => safePop(context)),
        title: Text(AppLocalizations.of(context).t('profile_family_management'), style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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
                        Text(AppLocalizations.of(context).t('profile_invite_family_to_wellness_together'), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Share invite code so family can get personalized health suggestions: ', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(_inviteCode, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
                            const SizedBox(width: 12),
                            IconButton(icon: const Icon(Icons.copy, color: Colors.white), onPressed: _copyCode),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _copyCode,
                          icon: const Icon(Icons.share, size: 18),
                          label: Text(AppLocalizations.of(context).t('profile_copy_invite_code_to_share_with_family')),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ShunShiColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Family members list
                  Text(AppLocalizations.of(context).t('profile_added_family_members'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 16),
                  if (_members.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ShunShiColors.border)),
                      child: Column(children: [
                        Icon(Icons.people_outline, size: 48, color: ShunShiColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context).t('profile_no_family_members_added_yet'), style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).t('profile_share_invite_code_to_add_family_members'), style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 13)),
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
                      Expanded(child: Text('Family can only see your health status overview (Stable/Tired/Needs Attention). They cannot see specific journal entries, protecting your privacy.', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5))),
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
      SnackBar(content: Text(AppLocalizations.of(context).t('profile_invite_code_copied')), duration: Duration(seconds: 2)),
    );
  }
}
