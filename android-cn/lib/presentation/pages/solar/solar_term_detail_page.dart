import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shunshi/core/theme/shunshi_colors.dart';
import 'package:shunshi/core/theme/shunshi_text_styles.dart';
import '../../../data/network/api_client.dart';

/// 24节气详情页 - 增强版
/// 从后端 /api/v1/solar-terms/enhanced/{termName} 获取数据
class SolarTermDetailPage extends StatefulWidget {
  final String termName;
  final String? termNameEn;
  final String? emoji;
  final String? season;

  const SolarTermDetailPage({
    super.key,
    required this.termName,
    this.termNameEn,
    this.emoji,
    this.season,
  });

  @override
  State<SolarTermDetailPage> createState() => _SolarTermDetailPageState();
}

class _SolarTermDetailPageState extends State<SolarTermDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _errorMsg;
  Map<String, dynamic>? _termDetail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await _api.get('/api/v1/solar-terms/enhanced/${Uri.encodeComponent(widget.termName)}?locale=zh-CN');
      if (res.statusCode == 200) {
        final body = res.data;
        if (body is Map && body['success'] == true) {
          setState(() {
            _termDetail = body['data'] as Map<String, dynamic>;
            _loading = false;
          });
          return;
        }
      }
      setState(() { _errorMsg = '加载失败 (${res.statusCode})'; _loading = false; });
    } on DioException catch (e) {
      setState(() { _errorMsg = '网络异常: ${e.message}'; _loading = false; });
    } catch (e) {
      setState(() { _errorMsg = '加载失败: $e'; _loading = false; });
    }
  }

  // ── 数据取值 ──

  Map<String, dynamic>? get _wellnessPlan {
    final wp = _termDetail?['wellness_plan'];
    if (wp == null) return null;
    return Map<String, dynamic>.from(wp as Map);
  }
  List<dynamic> get _dietItems => _wellnessPlan?['diet'] as List? ?? [];
  List<dynamic> get _teaItems => _wellnessPlan?['tea'] as List? ?? [];
  List<dynamic> get _exerciseItems => _wellnessPlan?['exercise'] as List? ?? [];
  List<dynamic> get _acupointItems => _wellnessPlan?['acupoints'] as List? ?? [];
  List<dynamic> get _sleepItems => _wellnessPlan?['sleep'] as List? ?? [];
  Map<String, dynamic> get _routine {
    final r = _wellnessPlan?['routine'];
    if (r == null) return {};
    return Map<String, dynamic>.from(r as Map);
  }
  Map<String, dynamic>? get _termInfo {
    final t = _termDetail?['term'];
    if (t == null) return null;
    return Map<String, dynamic>.from(t as Map);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          title: Text('${_termInfo?['emoji'] ?? widget.emoji ?? ''} ${_termInfo?['name'] ?? widget.termName}'),
        elevation: 0,
        backgroundColor: ShunshiColors.surface,
        foregroundColor: ShunshiColors.textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunshiColors.primary))
          : _errorMsg != null
              ? _buildError()
              : Column(
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    Expanded(child: _buildTabContent()),
                  ],
                ),
      ),
    );
  }

  // ── 错误页 ──

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: ShunshiColors.textHint),
            const SizedBox(height: 16),
            Text(_errorMsg ?? '加载失败', style: ShunshiTextStyles.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () { setState(() { _loading = true; _errorMsg = null; }); _loadData(); },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(backgroundColor: ShunshiColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }

  // ── 头部 ──

  Widget _buildHeader() {
    final season = _termInfo?['season'] ?? widget.season ?? 'spring';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _getSeasonGradient(season)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${_termInfo?['emoji'] ?? ''} ', style: const TextStyle(fontSize: 32)),
          Text(_termInfo?['name'] ?? widget.termName, style: ShunshiTextStyles.greeting.copyWith(color: Colors.white)),
          if (_termInfo?['name_en'] != null) ...[
            const SizedBox(width: 8),
            Text(_termInfo!['name_en'], style: ShunshiTextStyles.caption.copyWith(color: Colors.white70)),
          ],
        ]),
        const SizedBox(height: 6),
        Text(_termInfo?['date'] ?? '', style: ShunshiTextStyles.caption.copyWith(color: Colors.white70)),
      ]),
    );
  }

  // ── TabBar ──

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: ShunshiColors.background, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 0,
        dividerColor: Colors.transparent,
        labelColor: ShunshiColors.primaryDark,
        unselectedLabelColor: ShunshiColors.textSecondary,
        labelStyle: ShunshiTextStyles.labelSmall,
        unselectedLabelStyle: ShunshiTextStyles.labelSmall,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: const [
          Tab(text: '饮食'), Tab(text: '茶饮'), Tab(text: '运动'),
          Tab(text: '穴位'), Tab(text: '睡眠'), Tab(text: '作息'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDietTab(),
        _buildTeaTab(),
        _buildExerciseTab(),
        _buildAcupointTab(),
        _buildSleepTab(),
        _buildRoutineTab(),
      ],
    );
  }

  // ── 饮食 Tab ──

  Widget _buildDietTab() {
    if (_dietItems.isEmpty) return _buildEmptyTab('暂无食疗推荐', '🍽️');
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), itemCount: _dietItems.length,
      itemBuilder: (context, index) => _buildContentCard(_dietItems[index], icons: const ['🥗', '🍳', '🌿'], showDifficulty: true));
  }

  // ── 茶饮 Tab ──

  Widget _buildTeaTab() {
    if (_teaItems.isEmpty) return _buildEmptyTab('暂无茶饮推荐', '🍵');
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), itemCount: _teaItems.length,
      itemBuilder: (context, index) => _buildContentCard(_teaItems[index], icons: const ['🍵', '🫖', '🌿']));
  }

  // ── 运动 Tab ──

  Widget _buildExerciseTab() {
    if (_exerciseItems.isEmpty) return _buildEmptyTab('暂无运动推荐', '🏃');
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), itemCount: _exerciseItems.length,
      itemBuilder: (context, index) => _buildContentCard(_exerciseItems[index], icons: const ['🏃', '🧘', '💪'], showBenefits: true));
  }

  // ── 穴位 Tab ──

  Widget _buildAcupointTab() {
    if (_acupointItems.isEmpty) return _buildEmptyTab('暂无穴位推荐', '🫳');
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), itemCount: _acupointItems.length,
      itemBuilder: (context, index) {
        final item = _acupointItems[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunshiColors.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('🫳', style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 12),
              Expanded(child: Text(item['title'] ?? '', style: ShunshiTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
            ]),
            if (item['location'] != null && item['location'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow('📍 位置', item['location']),
            ],
            if (item['method'] != null && item['method'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow('👆 方法', item['method']),
            ],
            if (item['effect'] != null && item['effect'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow('✨ 功效', item['effect']),
            ],
            if (item['duration'] != null && item['duration'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow('⏱ 时长', item['duration']),
            ],
          ]),
        );
      },
    );
  }

  // ── 睡眠 Tab ──

  Widget _buildSleepTab() {
    if (_sleepItems.isEmpty) return _buildEmptyTab('暂无睡眠建议', '😴');
    return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), itemCount: _sleepItems.length,
      itemBuilder: (context, index) {
        final item = _sleepItems[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFFBF5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('😴', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(item['title'] ?? '', style: ShunshiTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
            ]),
            if (item['description'] != null) ...[
              const SizedBox(height: 8),
              Text(item['description'], style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textSecondary, height: 1.6)),
            ],
            if (item['method'] != null && item['method'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('💡 方法', item['method']),
            ],
            if (item['best_time'] != null && item['best_time'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow('🕐 最佳时间', item['best_time']),
            ],
          ]),
        );
      },
    );
  }

  // ── 作息 Tab ──

  Widget _buildRoutineTab() {
    if (_routine.isEmpty) return _buildEmptyTab('暂无作息建议', '🕐');
    final season = _termInfo?['season'] ?? widget.season ?? 'spring';
    final seasonName = {'spring': '春季', 'summer': '夏季', 'autumn': '秋季', 'winter': '冬季'}[season] ?? '';

    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Text('${seasonName}作息指南', style: ShunshiTextStyles.labelSmall.copyWith(color: ShunshiColors.primaryDark, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      _buildRoutineCard('😴', '睡眠', _routine['sleep'] ?? '暂无建议'),
      const SizedBox(height: 10),
      _buildRoutineCard('🍽️', '饮食', _routine['diet'] ?? '暂无建议'),
      const SizedBox(height: 10),
      _buildRoutineCard('🏃', '运动', _routine['exercise'] ?? '暂无建议'),
      const SizedBox(height: 10),
      _buildRoutineCard('❤️', '情志', _routine['emotion'] ?? '暂无建议'),
    ]);
  }

  // ── 通用组件 ──

  Widget _buildContentCard(dynamic item, {List<String> icons = const ['📋'], bool showDifficulty = false, bool showBenefits = false}) {
    final map = item as Map<String, dynamic>;
    final icon = icons.isNotEmpty ? icons[item.hashCode % icons.length] : '📋';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunshiColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18)))),
          const SizedBox(width: 12),
          Expanded(child: Text(map['title'] ?? '', style: ShunshiTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
          if (showDifficulty && map['difficulty'] != null && map['difficulty'].toString().isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: ShunshiColors.background, borderRadius: BorderRadius.circular(8)),
              child: Text(map['difficulty'], style: ShunshiTextStyles.labelSmall.copyWith(color: ShunshiColors.textSecondary))),
        ]),
        if (map['description'] != null && map['description'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(map['description'], style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textSecondary, height: 1.6)),
        ],
        // 食材/配料
        ..._buildIngredientChips(map['ingredients']),
        // 步骤
        ..._buildStepList(map['steps']),
        // 功效 (运动)
        if (showBenefits) ..._buildBenefitChips(map['benefits']),
        // 时长
        if (map['duration'] != null && map['duration'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              const Icon(Icons.schedule, size: 14, color: ShunshiColors.textHint),
              const SizedBox(width: 4),
              Text('建议时长: ${map['duration']}', style: ShunshiTextStyles.labelSmall.copyWith(color: ShunshiColors.textHint)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildRoutineCard(String emoji, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunshiColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 10), Text(title, style: ShunshiTextStyles.body.copyWith(fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text(content, style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textSecondary, height: 1.7)),
      ]),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 64, child: Text(label, style: ShunshiTextStyles.labelSmall.copyWith(color: ShunshiColors.textSecondary))),
      Expanded(child: Text(value.toString(), style: ShunshiTextStyles.labelSmall.copyWith(color: ShunshiColors.textPrimary, height: 1.5))),
    ]);
  }

  Widget _buildEmptyTab(String text, String emoji) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(text, style: ShunshiTextStyles.bodySecondary),
    ]));
  }

  List<Widget> _buildIngredientChips(dynamic val) {
    if (val == null) return [];
    final list = val is List ? val : [];
    if (list.isEmpty) return [];
    return [
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: list.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
        child: Text(e.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF15803D))),
      )).toList()),
    ];
  }

  List<Widget> _buildStepList(dynamic val) {
    if (val == null) return [];
    final list = val is List ? val : [];
    if (list.isEmpty) return [];
    return [
      const SizedBox(height: 10),
      ...list.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 18, height: 18, margin: const EdgeInsets.only(top: 1), decoration: BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle),
            child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 8),
          Expanded(child: Text(e.value.toString(), style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textSecondary, height: 1.5))),
        ]),
      )),
    ];
  }

  List<Widget> _buildBenefitChips(dynamic val) {
    if (val == null) return [];
    final list = val is List ? val : [];
    if (list.isEmpty) return [];
    return [
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: list.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)),
        child: Text(e.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
      )).toList()),
    ];
  }

  List<Color> _getSeasonGradient(String season) {
    switch (season) {
      case 'spring': return [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)];
      case 'summer': return [const Color(0xFFFFCC02), const Color(0xFFFF9800)];
      case 'autumn': return [const Color(0xFFFFAB91), const Color(0xFFFF7043)];
      case 'winter': return [const Color(0xFF90CAF9), const Color(0xFF42A5F5)];
      default: return [const Color(0xFF90CAF9), const Color(0xFF42A5F5)];
    }
  }
}
