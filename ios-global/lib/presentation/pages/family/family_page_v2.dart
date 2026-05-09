/// FamilyWellness页 V3 — 接 API
/// GET /api/v1/family/, POST /members, GET /status, POST /invite
library;

import 'package:dio/dio.dart';
import '../../../data/storage/storage_manager.dart';
import '../../widgets/state_view.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class FamilyPageV2 extends StatefulWidget {
  const FamilyPageV2({super.key});

  @override
  State<FamilyPageV2> createState() => _FamilyPageV2State();
}

class _FamilyPageV2State extends State<FamilyPageV2> {
  static const _baseUrl = 'http://116.62.32.43:4000';
  final _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 8)));
  
  String _familyName = 'ProfileFamily';
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getToken();
    await _fetchFamily();
  }

  Future<void> _getToken() async {
    _token = StorageManager.user.getToken();
    if (_token != null) return;
    try {
      final res = await _dio.post('/api/v1/auth/guest-login', data: {});
      final data = res.data;
      _token = data is Map ? (data['data'] ?? data)['token'] : null;
    } catch (_) {}
  }

  Map<String, dynamic> get _authHeaders => {'Authorization': 'Bearer $_token'};

  Future<void> _fetchFamily() async {
    if (_token == null) { setState(() => _loading = false); return; }
    try {
      final res = await _dio.get('/api/v1/family/', options: Options(headers: _authHeaders));
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final d = data['data'] as Map<String, dynamic>;
        _familyName = d['family_name']?.toString() ?? 'ProfileFamily';
        _members = (d['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _addMember(String name, String relation) async {
    if (_token == null) return;
    try {
      await _dio.post('/api/v1/family/members',
        data: {'name': name, 'relationship': relation, 'age_group': 'adult'},
        options: Options(headers: _authHeaders));
      _fetchFamily();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add')));
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (_token == null) return;
    try {
      await _dio.delete('/api/v1/family/members/$memberId', options: Options(headers: _authHeaders));
      _fetchFamily();
    } catch (_) {}
  }

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    String relation = 'Parents';
    final relations = ['Parents', 'Spouse', 'ZiFemale', 'Grandparents', 'Other'];
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: relation,
          items: relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => relation = v ?? 'Parents',
          decoration: InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); _addMember(nameCtrl.text.trim(), relation); },
          style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary),
          child: Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: ShunShiColors.background, body: const LoadingSkeleton());

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: RefreshIndicator(
        color: ShunShiColors.primary,
        onRefresh: _fetchFamily,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(child: SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Text('FamilyWellness', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 22, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
                const Spacer(),
                IconButton(icon: Icon(Icons.person_add, color: ShunShiColors.primary), onPressed: _showAddMemberDialog),
              ]),
            ))),

            // Family name card
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.home, color: Color(0xFFE4C285), size: 20),
                    const SizedBox(width: 8),
                    Text(_familyName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                  const SizedBox(height: 8),
                  Text('${_members.length} family members', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Get differentiated wellness plans based on each person\'s body type', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ]),
              ),
            )),

            // Members list
            if (_members.isEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Column(children: [
                  Icon(Icons.family_restroom, size: 48, color: ShunShiColors.textTertiary),
                  const SizedBox(height: 12),
                  Text('No family members yet', style: TextStyle(fontSize: 16, color: ShunShiColors.textTertiary)),
                  const SizedBox(height: 8),
                  Text('Add family members to get personalized wellness plans', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Add Family Member'),
                    style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ]),
              )),
            ] else ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Family Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              )),
              SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                final m = _members[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      CircleAvatar(radius: 20, backgroundColor: ShunShiColors.primary.withOpacity(0.1),
                        child: Text(m['name']?.toString().substring(0, 1) ?? '?', style: TextStyle(color: ShunShiColors.primary, fontWeight: FontWeight.w600))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m['name']?.toString() ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
                        Text(m['relationship']?.toString() ?? '', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                      ])),
                      IconButton(icon: Icon(Icons.delete_outline, size: 18, color: ShunShiColors.textTertiary),
                        onPressed: () => _removeMember(m['id']?.toString() ?? '')),
                    ]),
                  ),
                );
              }, childCount: _members.length)),
            ],

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}
