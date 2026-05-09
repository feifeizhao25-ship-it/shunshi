import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

/// Family成员Details页 — 仅显示状态级别信息（Privacy优先）
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
      final res = await dio.get('http://116.62.32.43:4000/api/v1/family/members/${widget.memberId}');
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
        'name': 'Mom',
        'avatar': '👩',
        'relation': 'Mother',
        'status': 'stable',
        'lastActive': 'Today 08:30',
        'lastCheckin': '3 hours ago',
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
      case 'stable': return 'Stable';
      case 'tired': return 'A bit tired';
      case 'attention': return 'Suggestion: Reach out';
      default: return 'Stable';
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
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: Text(_member?['name'] ?? 'FamilyDetails',
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
                    Text(AppLocalizations.of(context).t('family_status_info'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        fontFamily: ShunShiTypography.serifFamily)),
                    const SizedBox(height: 16),
                    _infoRow('Current Status',
                        '${_statusEmoji(_member?['status'] ?? 'stable')} ${_statusText(_member?['status'] ?? 'stable')}',
                        _statusColor(_member?['status'] ?? 'stable')),
                    const SizedBox(height: 12),
                    _infoRow('Recently Active', _member?['lastActive'] ?? 'Unknown', ShunShiColors.textSecondary),
                    const SizedBox(height: 12),
                    _infoRow('Last Check-in', _member?['lastCheckin'] ?? 'Unknown', ShunShiColors.textSecondary),
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
                    Expanded(child: Text('Privacy Protection: You can only see status-level information',
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
                          SnackBar(content: Text(AppLocalizations.of(context).t('family_care_reminder_sent')), duration: Duration(seconds: 1)));
                    },
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: Text(AppLocalizations.of(context).t('family_send_care_reminder')),
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
                          SnackBar(content: Text(AppLocalizations.of(context).t('family_they_will_see_the_same_status_card')), duration: Duration(seconds: 2)));
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(AppLocalizations.of(context).t('family_view_profile_status_their_view')),
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
