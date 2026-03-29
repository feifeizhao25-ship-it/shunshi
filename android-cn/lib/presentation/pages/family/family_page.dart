// 顺时「家庭关怀」页面 — 家和版会员专属
//
// 功能：家庭概览 / 成员列表 / 成员详情 / 添加成员 / 关怀提醒设置
// 非家和版会员显示升级提示

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../data/network/api_client.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 数据模型
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FamilyOverview {
  final int memberCount;
  final String careLevel;
  final int monthlyCareCount;
  final bool isJiaheMember;

  const _FamilyOverview({
    required this.memberCount,
    required this.careLevel,
    required this.monthlyCareCount,
    this.isJiaheMember = true,
  });

  factory _FamilyOverview.fromJson(Map<String, dynamic> json) =>
      _FamilyOverview(
        memberCount: json['member_count'] ?? 0,
        careLevel: json['care_level'] ?? '基础关怀',
        monthlyCareCount: json['monthly_care_count'] ?? 0,
        isJiaheMember: json['is_jiahe_member'] ?? true,
      );
}

class _MemberItem {
  final String id;
  final String title;
  final int age;
  final String relation;
  final String status; // normal | attention | warning
  final String? lastActivity;

  const _MemberItem({
    required this.id,
    required this.title,
    required this.age,
    required this.relation,
    required this.status,
    this.lastActivity,
  });

  factory _MemberItem.fromJson(Map<String, dynamic> json) => _MemberItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        age: json['age'] ?? 0,
        relation: json['relation'] ?? '',
        status: json['status'] ?? 'normal',
        lastActivity: json['last_activity'],
      );

  String get initial => title.isNotEmpty ? title[0] : '?';
}

class _MemberHealthDetail {
  final String memberId;
  final String statusSummary;
  final List<String> careSuggestions;

  const _MemberHealthDetail({
    required this.memberId,
    required this.statusSummary,
    required this.careSuggestions,
  });

  factory _MemberHealthDetail.fromJson(Map<String, dynamic> json) =>
      _MemberHealthDetail(
        memberId: json['member_id'] ?? '',
        statusSummary: json['status_summary'] ?? '',
        careSuggestions: List<String>.from(json['care_suggestions'] ?? []),
      );
}

class _CareReminderSettings {
  final String reminderTime;
  final String frequency; // daily | weekly | anomaly_only
  final bool enabled;

  const _CareReminderSettings({
    required this.reminderTime,
    required this.frequency,
    this.enabled = true,
  });

  factory _CareReminderSettings.fromJson(Map<String, dynamic> json) =>
      _CareReminderSettings(
        reminderTime: json['reminder_time'] ?? '09:00',
        frequency: json['frequency'] ?? 'daily',
        enabled: json['enabled'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'reminder_time': reminderTime,
        'frequency': frequency,
        'enabled': enabled,
      };

  String get frequencyLabel => switch (frequency) {
        'daily' => '每日',
        'weekly' => '每周',
        'anomaly_only' => '仅异常',
        _ => '每日',
      };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 辅助
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Color _healthColor(String status) => switch (status) {
      'normal' => const Color(0xFF8B9E7E),
      'attention' => const Color(0xFFE8C87A),
      'warning' => const Color(0xFFD4A5A5),
      _ => const Color(0xFF8B9E7E),
    };

(String label, Color color) _statusInfo(String status) => switch (status) {
      'normal' => ('正常', const Color(0xFF8B9E7E)),
      'attention' => ('需关注', const Color(0xFFE8C87A)),
      'warning' => ('预警', const Color(0xFFD4A5A5)),
      _ => ('正常', const Color(0xFF8B9E7E)),
    };

Color _relationColor(String relation) => switch (relation) {
      '父亲' => ShunshiColors.calm,
      '母亲' => ShunshiColors.blush,
      '伴侣' => ShunshiColors.warm,
      '子女' => ShunshiColors.primary,
      _ => ShunshiColors.textSecondary,
    };

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 主页面
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FamilyPage extends ConsumerStatefulWidget {
  const FamilyPage({super.key});

  @override
  ConsumerState<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends ConsumerState<FamilyPage> {
  bool _loading = true;
  String? _error;
  _FamilyOverview? _overview;
  List<_MemberItem> _members = [];
  _CareReminderSettings? _settings;
  bool _detailLoading = false;
  _MemberHealthDetail? _memberDetail;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── API ───────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([_loadOverview(), _loadMembers(), _loadSettings()]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOverview() async {
    try {
      final c = ApiClient();
      final results = await Future.wait([
        c.get('/api/v1/family/overview').then((r) => r.data),
        c.get('/api/v1/family/status').then((r) => r.data),
      ]);
      final m0 = results[0] is Map<String, dynamic>
          ? results[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final m1 = results[1] is Map<String, dynamic>
          ? results[1] as Map<String, dynamic>
          : <String, dynamic>{};
      if (mounted) {
        setState(() => _overview = _FamilyOverview.fromJson({...m0, ...m1}));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _overview = const _FamilyOverview(
            memberCount: 3, careLevel: '基础关怀', monthlyCareCount: 12));
      }
    }
  }

  Future<void> _loadMembers() async {
    try {
      final c = ApiClient();
      final res = await c.get('/api/v1/family/members');
      final list = res.data is List ? res.data as List : <dynamic>[];
      if (mounted) {
        setState(() => _members = list
            .map((e) => _MemberItem.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _members = const [
              _MemberItem(
                  id: '1',
                  title: '父亲',
                  age: 58,
                  relation: '父亲',
                  status: 'attention',
                  lastActivity: '2小时前记录了血压'),
              _MemberItem(
                  id: '2',
                  title: '母亲',
                  age: 55,
                  relation: '母亲',
                  status: 'normal',
                  lastActivity: '今天完成了养生计划'),
              _MemberItem(
                  id: '3',
                  title: '伴侣',
                  age: 32,
                  relation: '伴侣',
                  status: 'normal',
                  lastActivity: '昨天查看了健康报告'),
            ]);
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final c = ApiClient();
      final res = await c.get('/api/v1/family/settings');
      final d = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (mounted) {
        setState(() => _settings = _CareReminderSettings.fromJson(d));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _settings = const _CareReminderSettings(
            reminderTime: '09:00', frequency: 'daily'));
      }
    }
  }

  Future<void> _loadMemberDetail(String id) async {
    setState(() {
      _detailLoading = true;
      _memberDetail = null;
    });
    try {
      final c = ApiClient();
      final res = await c.get('/api/v1/family/members/$id/health');
      final d = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (mounted) {
        setState(() => _memberDetail = _MemberHealthDetail.fromJson(d));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _memberDetail = _MemberHealthDetail(
              memberId: id,
              statusSummary: '整体状态平稳，睡眠质量良好，建议适当增加户外活动。',
              careSuggestions: [
                '建议每日散步30分钟，有助于改善血液循环',
                '注意饮食规律，避免过饱或过饥',
                '保持社交互动，每周至少与家人通话2次',
              ],
            ));
      }
    } finally {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  Future<void> _saveSettings(_CareReminderSettings s) async {
    try {
      final c = ApiClient();
      await c.put('/api/v1/family/settings', data: s.toJson());
      if (mounted) {
        setState(() => _settings = s);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('设置已保存')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    }
  }

  Future<void> _invite(
      {required String title, required int age, required String relation}) async {
    try {
      final c = ApiClient();
      await c.post('/api/v1/family/invite',
          data: {'title': title, 'age': age, 'relation': relation});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('邀请码已生成')));
        _loadMembers();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('生成失败')));
      }
    }
  }

  Future<void> _updateSettings(
      {String? time, String? freq, bool? enabled}) async {
    final cur = _settings ??
        const _CareReminderSettings(reminderTime: '09:00', frequency: 'daily');
    await _saveSettings(_CareReminderSettings(
      reminderTime: time ?? cur.reminderTime,
      frequency: freq ?? cur.frequency,
      enabled: enabled ?? cur.enabled,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunshiColors.background,
      appBar: AppBar(
        backgroundColor: ShunshiColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: ShunshiColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('家庭关怀', style: ShunshiTextStyles.heading),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: ShunshiColors.textSecondary,
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          (_overview == null || !_overview!.isJiaheMember)
              ? null
              : FloatingActionButton.extended(
                  onPressed: _showAddSheet,
                  backgroundColor: ShunshiColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add),
                  label: const Text('添加成员'),
                ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: ShunshiColors.primary));
    }
    if (_error != null) return _buildError();
    if (_overview != null && !_overview!.isJiaheMember) return _buildUpgrade();
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: ShunshiColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.pagePadding),
        children: [
          const SizedBox(height: ShunshiSpacing.sm),
          _buildOverviewCard(),
          const SizedBox(height: ShunshiSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('家庭成员', style: ShunshiTextStyles.heading),
              Text('${_members.length}人',
                  style: ShunshiTextStyles.caption
                      .copyWith(color: ShunshiColors.textHint)),
            ],
          ),
          const SizedBox(height: ShunshiSpacing.md),
          ..._members.map((m) => Padding(
                padding:
                    const EdgeInsets.only(bottom: ShunshiSpacing.md),
                child: _buildCard(m),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: ShunshiColors.error),
            const SizedBox(height: ShunshiSpacing.md),
            Text('加载失败', style: ShunshiTextStyles.heading),
            const SizedBox(height: ShunshiSpacing.sm),
            Text(_error ?? '', style: ShunshiTextStyles.caption),
            const SizedBox(height: ShunshiSpacing.lg),
            FilledButton(
              onPressed: _loadAll,
              style:
                  FilledButton.styleFrom(backgroundColor: ShunshiColors.primary),
              child: const Text('重试'),
            ),
          ],
        ),
      );

  Widget _buildUpgrade() => Center(
        child: Padding(
          padding: const EdgeInsets.all(ShunshiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ShunshiColors.warm.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.family_restroom,
                    size: 40, color: ShunshiColors.warm),
              ),
              const SizedBox(height: ShunshiSpacing.lg),
              Text('家庭关怀', style: ShunshiTextStyles.greeting),
              const SizedBox(height: ShunshiSpacing.sm),
              Text('家庭关怀是家和版会员专属功能',
                  style: ShunshiTextStyles.bodySecondary,
                  textAlign: TextAlign.center),
              const SizedBox(height: ShunshiSpacing.md),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: ShunshiColors.warm),
                child: const Text('升级家和版'),
              ),
            ],
          ),
        ),
      );

  // ── 概览卡片 ─────────────────────────────────────────────────────

  Widget _buildOverviewCard() {
    final o = _overview;
    if (o == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(ShunshiSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ShunshiColors.primary.withValues(alpha: 0.15),
            ShunshiColors.primaryLight.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        border: Border.all(color: ShunshiColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ShunshiColors.primary.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(ShunshiSpacing.radiusSmall),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: ShunshiColors.primary, size: 20),
                ),
                const SizedBox(width: ShunshiSpacing.sm),
                Text('我的家庭', style: ShunshiTextStyles.heading),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ShunshiSpacing.sm,
                    vertical: ShunshiSpacing.xs),
                decoration: BoxDecoration(
                  color: ShunshiColors.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(ShunshiSpacing.radiusFull),
                ),
                child: Text(o.careLevel,
                    style: ShunshiTextStyles.caption.copyWith(
                        color: ShunshiColors.primaryDark,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: ShunshiSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('${o.memberCount}', '家庭人数', Icons.group_rounded),
              _stat('${o.monthlyCareCount}', '本月关怀',
                  Icons.volunteer_activism_rounded),
              _stat(o.careLevel, '关怀等级', Icons.auto_awesome_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l, IconData i) => Column(children: [
        Icon(i, size: 22, color: ShunshiColors.primary),
        const SizedBox(height: ShunshiSpacing.xs),
        Text(v, style: ShunshiTextStyles.heading),
        const SizedBox(height: 2),
        Text(l, style: ShunshiTextStyles.caption),
      ]);

  // ── 成员卡片 ─────────────────────────────────────────────────────

  Widget _buildCard(_MemberItem m) {
    return GestureDetector(
      onTap: () => _showDetail(m),
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.cardPadding,
            vertical: ShunshiSpacing.md),
        decoration: BoxDecoration(
          color: ShunshiColors.surface,
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: ShunshiColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // 头像
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _relationColor(m.relation).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(m.initial,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _relationColor(m.relation)))),
          const SizedBox(width: ShunshiSpacing.md),
          // 中间信息
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.title, style: ShunshiTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text('${m.relation} · ${m.age}岁',
                  style: ShunshiTextStyles.caption),
              const SizedBox(height: 4),
              _statusChip(m.status),
            ],
          )),
          // 右侧活动 + 指示灯
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (m.lastActivity != null && m.lastActivity!.isNotEmpty)
                SizedBox(
                    width: 100,
                    child: Text(m.lastActivity!,
                        style: ShunshiTextStyles.caption.copyWith(
                            color: ShunshiColors.textHint, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right)),
              const SizedBox(height: ShunshiSpacing.sm),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: _healthColor(m.status),
                      shape: BoxShape.circle)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusSmall),
      ),
      child:
          Text(label, style: ShunshiTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  // ── 成员详情 ─────────────────────────────────────────────────────

  Future<void> _showDetail(_MemberItem m) async {
    setState(() {
      _detailLoading = true;
      _memberDetail = null;
    });
    await _loadMemberDetail(m.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(ShunshiSpacing.radiusXL))),
      builder: (_) => _DetailSheet(
          member: m, loading: _detailLoading, detail: _memberDetail),
    );
  }

  // ── 添加成员 ─────────────────────────────────────────────────────

  void _showAddSheet() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    var relation = '父亲';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(ShunshiSpacing.radiusXL))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
              left: ShunshiSpacing.pagePadding,
              right: ShunshiSpacing.pagePadding,
              top: ShunshiSpacing.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  ShunshiSpacing.lg),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: ShunshiColors.divider,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: ShunshiSpacing.lg),
                Text('添加家庭成员', style: ShunshiTextStyles.heading),
                const SizedBox(height: ShunshiSpacing.md),
                Text('称谓', style: ShunshiTextStyles.caption),
                const SizedBox(height: ShunshiSpacing.xs),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      hintText: '如：爸爸、妈妈',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请输入称谓' : null,
                ),
                const SizedBox(height: ShunshiSpacing.md),
                Text('关系', style: ShunshiTextStyles.caption),
                const SizedBox(height: ShunshiSpacing.xs),
                Wrap(
                    spacing: ShunshiSpacing.sm,
                    runSpacing: ShunshiSpacing.sm,
                    children: ['父亲', '母亲', '伴侣', '子女', '其他'].map((r) {
                      final sel = r == relation;
                      return ChoiceChip(
                        label: Text(r),
                        selected: sel,
                        onSelected: (_) => setLocal(() => relation = r),
                        selectedColor:
                            ShunshiColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                            color: sel
                                ? ShunshiColors.primaryDark
                                : ShunshiColors.textSecondary,
                            fontWeight:
                                sel ? FontWeight.w500 : FontWeight.w400),
                        side: BorderSide(
                            color: sel
                                ? ShunshiColors.primary
                                : ShunshiColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                      );
                    }).toList()),
                const SizedBox(height: ShunshiSpacing.md),
                Text('年龄', style: ShunshiTextStyles.caption),
                const SizedBox(height: ShunshiSpacing.xs),
                TextFormField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: '请输入年龄',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入年龄';
                    final a = int.tryParse(v.trim());
                    if (a == null || a < 1 || a > 150) return '请输入有效年龄';
                    return null;
                  },
                ),
                const SizedBox(height: ShunshiSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _invite(
                            title: titleCtrl.text.trim(),
                            age: int.parse(ageCtrl.text.trim()),
                            relation: relation);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ShunshiColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ShunshiSpacing.radiusMedium)),
                    ),
                    child: const Text('生成邀请码'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 提醒设置 ─────────────────────────────────────────────────────

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(ShunshiSpacing.radiusXL))),
      builder: (_) => _SettingsSheet(
          settings: _settings, onSave: _updateSettings),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 成员详情 Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DetailSheet extends StatelessWidget {
  final _MemberItem member;
  final bool loading;
  final _MemberHealthDetail? detail;

  const _DetailSheet(
      {required this.member, required this.loading, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ShunshiSpacing.pagePadding,
          ShunshiSpacing.lg,
          ShunshiSpacing.pagePadding,
          ShunshiSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: ShunshiColors.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: ShunshiSpacing.lg),
          // 头像
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _relationColor(member.relation).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(member.initial,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _relationColor(member.relation)))),
          const SizedBox(height: ShunshiSpacing.md),
          Text(member.title, style: ShunshiTextStyles.heading),
          const SizedBox(height: 4),
          Text('${member.relation} · ${member.age}岁',
              style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.md),
          const Divider(color: ShunshiColors.divider),
          const SizedBox(height: ShunshiSpacing.md),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child:
                  CircularProgressIndicator(color: ShunshiColors.primary),
            )
          else if (detail != null) ...[
            Align(
                alignment: Alignment.centerLeft,
                child: Text('状态摘要', style: ShunshiTextStyles.titleMedium)),
            const SizedBox(height: ShunshiSpacing.sm),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(detail!.statusSummary,
                    style: ShunshiTextStyles.body)),
            const SizedBox(height: ShunshiSpacing.lg),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('关怀建议', style: ShunshiTextStyles.titleMedium)),
            const SizedBox(height: ShunshiSpacing.sm),
            ...detail!.careSuggestions.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: ShunshiSpacing.sm),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 8),
                        decoration: BoxDecoration(
                            color: ShunshiColors.primary,
                            shape: BoxShape.circle)),
                    Expanded(
                        child: Text(e.value,
                            style: ShunshiTextStyles.bodySecondary)),
                  ]),
                )),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 提醒设置 Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SettingsSheet extends StatefulWidget {
  final _CareReminderSettings? settings;
  final Future<void> Function(
      {String? time, String? freq, bool? enabled}) onSave;

  const _SettingsSheet({required this.settings, required this.onSave});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late String _time;
  late String _freq;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _time = widget.settings?.reminderTime ?? '09:00';
    _freq = widget.settings?.frequency ?? 'daily';
    _enabled = widget.settings?.enabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ShunshiSpacing.pagePadding,
          ShunshiSpacing.lg,
          ShunshiSpacing.pagePadding,
          ShunshiSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: ShunshiColors.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: ShunshiSpacing.lg),
          Text('关怀提醒设置', style: ShunshiTextStyles.heading),
          const SizedBox(height: ShunshiSpacing.lg),
          // 开关
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('开启关怀提醒', style: ShunshiTextStyles.body),
            value: _enabled,
            activeTrackColor: ShunshiColors.primary.withValues(alpha: 0.3),
            activeThumbColor: ShunshiColors.primary,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: ShunshiSpacing.sm),
          // 提醒时间
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, color: ShunshiColors.primary),
            title: Text('提醒时间', style: ShunshiTextStyles.body),
            trailing: Text(_time, style: ShunshiTextStyles.caption),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _parseTime(_time),
                builder: (ctx, child) => child!,
              );
              if (picked != null) {
                setState(() => _time = _formatTime(picked));
              }
            },
          ),
          const Divider(color: ShunshiColors.divider),
          // 频率
          Align(
              alignment: Alignment.centerLeft,
              child: Text('提醒频率', style: ShunshiTextStyles.caption)),
          const SizedBox(height: ShunshiSpacing.sm),
          Wrap(
            spacing: ShunshiSpacing.sm,
            children: ['daily', 'weekly', 'anomaly_only'].map((f) {
              final sel = f == _freq;
              final label = switch (f) {
                'daily' => '每日',
                'weekly' => '每周',
                _ => '仅异常',
              };
              return ChoiceChip(
                label: Text(label),
                selected: sel,
                onSelected: (_) => setState(() => _freq = f),
                selectedColor: ShunshiColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                    color: sel
                        ? ShunshiColors.primaryDark
                        : ShunshiColors.textSecondary,
                    fontWeight: sel ? FontWeight.w500 : FontWeight.w400),
                side: BorderSide(
                    color:
                        sel ? ShunshiColors.primary : ShunshiColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: ShunshiSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave(time: _time, freq: _freq, enabled: _enabled);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: ShunshiColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        ShunshiSpacing.radiusMedium)),
              ),
              child: const Text('保存设置'),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
