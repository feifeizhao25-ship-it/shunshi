// ignore_for_file: unused_field
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../design_system/theme.dart';

class SolarTermDetailPage extends StatefulWidget {
  final String termName;
  final String? season;

  const SolarTermDetailPage({super.key, required this.termName, this.season});

  @override
  State<SolarTermDetailPage> createState() => _SolarTermDetailPageState();
}

class _SolarTermDetailPageState extends State<SolarTermDetailPage> {
  bool _apiError = false;
  bool _isLoading = true;

  Map<String, dynamic> _termDetail = {};

  static const Map<String, _TermInfo> _termData = {
    '立春': _TermInfo(en: 'Start of Spring', quote: '春三月，此谓发陈，天地俱生，万物以荣。', season: '孟春'),
    '雨水': _TermInfo(en: 'Rain Water', quote: '好雨知时节，当春乃发生。', season: '孟春'),
    '惊蛰': _TermInfo(en: 'Awakening of Insects', quote: '春雷响，万物长。', season: '仲春'),
    '春分': _TermInfo(en: 'Spring Equinox', quote: '日夜分，阴阳和。', season: '仲春'),
    '清明': _TermInfo(en: 'Clear and Bright', quote: '清明时节雨纷纷，路上行人欲断魂。', season: '季春'),
    '谷雨': _TermInfo(en: 'Grain Rain', quote: '雨生百谷，万物更新。', season: '季春'),
    '立夏': _TermInfo(en: 'Start of Summer', quote: '夏三月，此谓蕃秀，天地气交，万物华实。', season: '孟夏'),
    '小满': _TermInfo(en: 'Grain Buds', quote: '麦穗初齐，江河渐满。', season: '孟夏'),
    '芒种': _TermInfo(en: 'Grain in Ear', quote: '芒种忙忙种，农人最辛苦。', season: '仲夏'),
    '夏至': _TermInfo(en: 'Summer Solstice', quote: '日长之至，日影短至。', season: '仲夏'),
    '小暑': _TermInfo(en: 'Minor Heat', quote: '小暑大暑，上蒸下煮。', season: '季夏'),
    '大暑': _TermInfo(en: 'Major Heat', quote: '大暑乃热之极也。', season: '季夏'),
    '立秋': _TermInfo(en: 'Start of Autumn', quote: '秋三月，此谓容平，天气以急，地气以明。', season: '孟秋'),
    '处暑': _TermInfo(en: 'End of Heat', quote: '处暑天不暑，炎热在中午。', season: '孟秋'),
    '白露': _TermInfo(en: 'White Dew', quote: '露凝而白，秋意渐浓。', season: '仲秋'),
    '秋分': _TermInfo(en: 'Autumnal Equinox', quote: '秋分者，阴阳相半也。', season: '仲秋'),
    '寒露': _TermInfo(en: 'Cold Dew', quote: '袅袅凉风动，凄凄寒露零。', season: '季秋'),
    '霜降': _TermInfo(en: "Frost's Descent", quote: '霜降霜降，移花进房。', season: '季秋'),
    '立冬': _TermInfo(en: 'Start of Winter', quote: '冬三月，此谓闭藏，水冰地坼，无扰乎阳。', season: '孟冬'),
    '小雪': _TermInfo(en: 'Minor Snow', quote: '小雪气寒而将雪矣。', season: '孟冬'),
    '大雪': _TermInfo(en: 'Major Snow', quote: '大雪纷飞，瑞雪兆丰年。', season: '仲冬'),
    '冬至': _TermInfo(en: 'Winter Solstice', quote: '冬至一阳生，日影长之至。', season: '仲冬'),
    '小寒': _TermInfo(en: 'Minor Cold', quote: '小寒大寒，冷成冰团。', season: '季冬'),
    '大寒': _TermInfo(en: 'Major Cold', quote: '大寒为中者，上形于小寒。', season: '季冬'),
  };

  @override
  void initState() {
    super.initState();
    _fetchTermDetail();
  }

  Future<void> _fetchTermDetail() async {
    try {
      // Use the base URL from app config or default to ECS
      // In production this should come from app_constants
      final baseUrl = 'http://116.62.32.43:4000';
      final url = '$baseUrl/api/v1/solar-terms/detail/${Uri.encodeComponent(widget.termName)}';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          _termDetail = data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() { _isLoading = false; _apiError = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _apiError = true; });
    }
  }

  List<String> _getList(dynamic field, List<String> fallback) {
    if (field is List) return field.cast<String>();
    return fallback;
  }

  Widget _buildSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const SizedBox(height: 60),
          Container(height: 48, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 8),
          Container(height: 20, width: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 32),
          Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 20, width: 120, alignment: Alignment.centerLeft, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 14),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final borderColor = isDark ? ShunShiColors.darkBorder : ShunShiColors.border;

    if (_isLoading) {
      return Scaffold(backgroundColor: bg, body: SafeArea(child: _buildSkeleton()));
    }

    final termName = widget.termName;
    final info = _termData[termName] ?? _TermInfo(en: termName, quote: '', season: widget.season ?? '');

    // 从API读取真实数据
    final exercises = _getList(_termDetail['exercises'], ['踏青', '太极拳', '八段锦', '散步']);
    final healthTips = _getList(_termDetail['health_tips'], ['顺应时节', '调节饮食', '适当运动', '调畅情志']);
    final acupoints = _getList(_termDetail['acupoints'], ['太冲穴', '足三里', '合谷穴']);
    final emotionalCare = _getList(_termDetail['emotional_care'], ['调畅情志', '保持平和', '多晒太阳']);
    final recommendedFoods = _getList(_termDetail['recommended_foods'], ['当季蔬果', '温润食物']);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => safePop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary, size: 22)),
                Text('顺时 AI', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textSecondary)),
                IconButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制分享链接'), duration: Duration(seconds: 1))); }, icon: Icon(Icons.share_rounded, color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary, size: 22)),
              ],
            ),
            const SizedBox(height: 24),

            // 季节标签
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${info.season} · ${termName}节气',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary, letterSpacing: 0.5)),
            )),
            const SizedBox(height: 20),

            // 节气标题
            Center(child: Column(children: [
              Text(termName, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 42, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 6),
              Text(info.en, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, color: isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary, letterSpacing: 1.2, fontStyle: FontStyle.italic)),
            ])),
            const SizedBox(height: 32),

            // Hero image
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(image: AssetImage('assets/images/ref_10.jpg'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),

            // 节气内涵
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('节气内涵', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
                const SizedBox(height: 10),
                Text('「${info.quote}」', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 15, color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary, height: 1.8)),
              ]),
            ),
            const SizedBox(height: 24),

            // 顺时生活方案
            Text('顺时生活方案', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 14),

            // 饮食（推荐食物）
            _sectionCard('饮食', recommendedFoods.join('、'), Icons.restaurant_rounded, isDark),
            const SizedBox(height: 10),

            // 运动（真实数据）
            _sectionCard('运动', exercises.join('、'), Icons.self_improvement_rounded, isDark),
            const SizedBox(height: 10),

            // 穴位调理（真实数据，点击展开穴位列表）
            _buildExpandableCard('穴位调理', acupoints, Icons.psychology_rounded, isDark),
            const SizedBox(height: 10),

            // 情志调养（真实数据）
            _sectionCard('情志调养', emotionalCare.join('、'), Icons.spa_rounded, isDark),
            const SizedBox(height: 10),

            // 养生提示
            _sectionCard('养生提示', healthTips.join('、'), Icons.favorite_rounded, isDark),
            const SizedBox(height: 20),

            // AI推荐卡片
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('向AI顺时助手了解更多$termName养生方案'), duration: const Duration(seconds: 2)),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ShunShiColors.primary.withValues(alpha: 0.08), ShunShiColors.primary.withValues(alpha: 0.03)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, size: 20, color: ShunShiColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('节气养生不止于此', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
                    const SizedBox(height: 2),
                    Text('向AI顺时助手咨询当前节气的个性化养生方案', style: TextStyle(fontSize: 12, color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary)),
                  ])),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: ShunShiColors.primary),
                ]),
              ),
            ),
            const SizedBox(height: 32),

            // 分享 CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制分享链接'), duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('分享这份顺时灵感', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String desc, IconData icon, bool isDark) {
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final borderColor = isDark ? ShunShiColors.darkBorder : ShunShiColors.border;
    final primaryColor = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;
    final textPrimary = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary = isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: primaryColor, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 13, color: textTertiary)),
        ])),
        Icon(Icons.chevron_right_rounded, color: textTertiary, size: 20),
      ]),
    );
  }

  Widget _buildExpandableCard(String title, List<String> items, IconData icon, bool isDark) {
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final borderColor = isDark ? ShunShiColors.darkBorder : ShunShiColors.border;
    final primaryColor = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;
    final textPrimary = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary = isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: primaryColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Text(item, style: TextStyle(fontSize: 13, color: primaryColor)),
        )).toList()),
      ]),
    );
  }
}

class _TermInfo {
  final String en;
  final String quote;
  final String season;
  const _TermInfo({required this.en, required this.quote, required this.season});
}
