/// Body Type Report页 V3 — 动态数据驱动
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

  // 9种Body Type信息
  static const _typeInfo = {
    'pinghe': {'name': 'Balanced', 'tags': ['Neutral', 'Healthy'], 'color': Color(0xFF4CAF50)},
    'qixu': {'name': 'Qi Deficient Type', 'tags': ['Tonify Qi', 'Eliminate Dampness', 'Avoid Cold & Cool'], 'color': Color(0xFFFFB74D)},
    'yangxu': {'name': 'Yang Deficient Type', 'tags': ['Warm Yang', 'Avoid Cold', 'Warm the Stomach'], 'color': Color(0xFF42A5F5)},
    'yinxu': {'name': 'Yin Deficient Type', 'tags': ['Nourish Yin', 'Moisten Dryness', 'Avoid Pungent & Spicy'], 'color': Color(0xFFAB47BC)},
    'tanshi': {'name': 'Phlegm-Damp Type', 'tags': ['Transform Phlegm', 'Eliminate Dampness', 'Reduce Sweet'], 'color': Color(0xFF8D6E63)},
    'shire': {'name': 'Damp-Heat Type', 'tags': ['Clear Heat', 'Drain Dampness', 'Avoid Oily Foods'], 'color': Color(0xFFEF5350)},
    'xueyu': {'name': 'Blood Stasis Type', 'tags': ['Invigorate Blood', 'Remove Blood Stasis', 'Exercise'], 'color': Color(0xFF7E57C2)},
    'qiyu': {'name': 'Qi Stagnant Type', 'tags': ['Soothe Liver', 'Relieve Depression', 'Regulate Emotions'], 'color': Color(0xFF66BB6A)},
    'tebing': {'name': 'Special Type', 'tags': ['Prevent Allergies', 'Light Diet', 'Avoid Irritants'], 'color': Color(0xFF78909C)},
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
    final typeCode = widget.constitutionType ?? 'qixu';
    final info = _typeInfo[typeCode] ?? _typeInfo['qixu']!;
    final name = info['name'] as String;
    final tags = info['tags'] as List<String>;
    final typeColor = info['color'] as Color;

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Body Type Report',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const LoadingSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Body Type Report · ${_getCurrentSeason()}',
                    style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
                  const SizedBox(height: 16),

                  // Body Type结果卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [ShunShiColors.primary, ShunShiColors.primary.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your Body Type: $name',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: tags.map((t) => _buildTag(t, const Color(0xFFE4C285))).toList()),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Body Type评分柱状图
                  if (widget.scores != null && widget.scores!.isNotEmpty) ...[
                    Text('Body Type Score Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    const SizedBox(height: 12),
                    ..._sortedScoreBars(),
                    const SizedBox(height: 8),
                  ],

                  // AIWellness Advice
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
                          Text('AI Wellness Summary',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                        ]),
                        const SizedBox(height: 12),
                        _buildAdviceSection(Icons.restaurant, 'Dietsuggestion: ', _advice?['advice']?['diet'] ?? ''),
                        const SizedBox(height: 8),
                        _buildAdviceSection(Icons.self_improvement, 'Exercisesuggestion: ', _advice?['advice']?['exercise'] ?? ''),
                        const SizedBox(height: 8),
                        _buildAdviceSection(Icons.wb_sunny, 'Seasonal Reminder', _advice?['advice']?['seasonal'] ?? ''),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // recommended 内容卡片（从API获取相关内容）
                  Text('Personalized Wellness Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildPlanCard(Icons.restaurant, 'recommended Recipes', _advice?['advice']?['diet'] ?? 'Qi & Blood Tonifying Recipes', 'View'),
                  const SizedBox(height: 10),
                  _buildPlanCard(Icons.spa, 'recommended Meridian', '$name Meridian Wellness', 'View'),
                  const SizedBox(height: 10),
                  _buildPlanCard(Icons.self_improvement, 'recommended Qigong', 'Baduanjin · ConditioningSpleenStomach', 'View'),
                  const SizedBox(height: 20),

                  // 引用
                  Center(child: Text('"Rest the body, move to nourish Qi."',
                    style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 14,
                      fontStyle: FontStyle.italic, color: ShunShiColors.textTertiary))),
                  const SizedBox(height: 16),

                  // Generate Wellness Calendar CTA
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generating wellness calendar...'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.calendar_month, size: 20),
                      label: const Text('Generate Wellness Calendar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
    if (m >= 3 && m <= 5) return 'Spring';
    if (m >= 6 && m <= 8) return 'Summer';
    if (m >= 9 && m <= 11) return 'Autumn';
    return 'Winter';
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
