/// 体质测试报告页 V3 — 动态数据驱动
library;

import 'package:flutter/material.dart';
import '../../widgets/state_view.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';

class ConstitutionReportPageV3 extends StatefulWidget {
  final String? constitutionType;
  final Map<String, double>? scores;

  const ConstitutionReportPageV3({super.key, this.constitutionType, this.scores});

  @override
  State<ConstitutionReportPageV3> createState() => _ConstitutionReportPageV3State();
}

class _ConstitutionReportPageV3State extends State<ConstitutionReportPageV3> {
  Map<String, dynamic>? _advice;
  bool _loading = true;

  // 9种体质信息
  static const _typeInfo = {
    'pinghe': {'name': '平和质', 'tags': ['平衡', '健康'], 'color': Color(0xFF4CAF50)},
    'qixu': {'name': '气虚质', 'tags': ['补气', '祛湿', '忌寒凉'], 'color': Color(0xFFFFB74D)},
    'yangxu': {'name': '阳虚质', 'tags': ['温阳', '避寒', '暖胃'], 'color': Color(0xFF42A5F5)},
    'yinxu': {'name': '阴虚质', 'tags': ['滋阴', '润燥', '忌辛辣'], 'color': Color(0xFFAB47BC)},
    'tanshi': {'name': '痰湿质', 'tags': ['化痰', '祛湿', '少甜'], 'color': Color(0xFF8D6E63)},
    'shire': {'name': '湿热质', 'tags': ['清热', '利湿', '忌油腻'], 'color': Color(0xFFEF5350)},
    'xueyu': {'name': '血瘀质', 'tags': ['活血', '化瘀', '运动'], 'color': Color(0xFF7E57C2)},
    'qiyu': {'name': '气郁质', 'tags': ['疏肝', '解郁', '调情志'], 'color': Color(0xFF66BB6A)},
    'tebing': {'name': '特禀质', 'tags': ['防敏', '清淡', '避刺激'], 'color': Color(0xFF78909C)},
  };

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    if (widget.constitutionType == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final resp = await ApiClient().get('/api/v1/constitution/advice/${widget.constitutionType}');
      final data = resp.data;
      if (data != null && data['success'] == true) {
        setState(() {
          _advice = data['data'];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    final typeCode = widget.constitutionType ?? 'qixu';
    final info = _typeInfo[typeCode] ?? _typeInfo['qixu']!;
    final name = info['name'] as String;
    final tags = info['tags'] as List<String>;


    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('体质测试报告',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const LoadingSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('体质测试报告 · ${_getCurrentSeason()}',
                    style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
                  const SizedBox(height: 16),

                  // 体质结果卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [ShunShiColors.primary, ShunShiColors.primary.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('您的体质：$name',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: tags.map((t) => _buildTag(t, const Color(0xFFE4C285))).toList()),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // 体质评分柱状图
                  if (widget.scores != null && widget.scores!.isNotEmpty) ...[
                    Text('体质评分分布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    const SizedBox(height: 12),
                    ..._sortedScoreBars(),
                    const SizedBox(height: 8),
                  ],

                  // AI调养建议
                  if (_advice != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ShunShiColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ShunShiColors.primary.withOpacity(0.15)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.auto_awesome, color: ShunShiColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('AI 调养总评',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                        ]),
                        const SizedBox(height: 12),
                        _buildAdviceSection(Icons.restaurant, '饮食建议', _advice?['advice']?['diet'] ?? ''),
                        const SizedBox(height: 8),
                        _buildAdviceSection(Icons.self_improvement, '运动建议', _advice?['advice']?['exercise'] ?? ''),
                        const SizedBox(height: 8),
                        _buildAdviceSection(Icons.wb_sunny, '季节提醒', _advice?['advice']?['seasonal'] ?? ''),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 推荐内容卡片（从API获取相关内容）
                  Text('专属调养方案', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildPlanCard(Icons.restaurant, '推荐食谱', _advice?['advice']?['diet'] ?? '补气养血食谱', '查看'),
                  const SizedBox(height: 10),
                  _buildPlanCard(Icons.spa, '推荐经络', '$name经络调养', '查看'),
                  const SizedBox(height: 10),
                  _buildPlanCard(Icons.self_improvement, '推荐功法', '八段锦 · 调理脾胃', '查看'),
                  const SizedBox(height: 20),

                  // 引用
                  Center(child: Text('"静养其身，动养其气。"',
                    style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 14,
                      fontStyle: FontStyle.italic, color: ShunShiColors.textTertiary))),
                  const SizedBox(height: 16),

                  // 生成调养日历 CTA
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('调养日历生成中...'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.calendar_month, size: 20),
                      label: const Text('生成详细调养日历', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShunShiColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  List<Widget> _sortedScoreBars() {
    if (widget.scores == null || widget.scores!.isEmpty) return [];
    final sorted = widget.scores!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => _buildBar(
      _typeInfo[e.key]?['name'] as String? ?? e.key,
      e.value,
      _typeInfo[e.key]?['color'] as Color? ?? ShunShiColors.textTertiary,
    )).toList();
  }

  String _getCurrentSeason() {
    final m = DateTime.now().month;
    if (m >= 3 && m <= 5) return '春季';
    if (m >= 6 && m <= 8) return '夏季';
    if (m >= 9 && m <= 11) return '秋季';
    return '冬季';
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label,
          style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value, backgroundColor: ShunShiColors.surfaceContainerLow,
            color: color, minHeight: 8),
        )),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%',
          style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildAdviceSection(IconData icon, String title, String content) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: ShunShiColors.textTertiary),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 2),
        Text(content, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.6)),
      ])),
    ]);
  }

  Widget _buildPlanCard(IconData icon, String category, String title, String action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: ShunShiColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: ShunShiColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        ])),
        Text(action, style: TextStyle(fontSize: 12, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
        Icon(Icons.arrow_forward, size: 14, color: ShunShiColors.primary),
      ]),
    );
  }
}
