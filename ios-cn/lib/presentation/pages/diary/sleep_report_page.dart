import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/network/session.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../design_system/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../design_system/app_colors.dart';

/// 睡眠报告页 — 7天柱状图 + AI趋势分析 + 建议
class SleepReportPage extends StatefulWidget {
  const SleepReportPage({super.key});

  @override
  State<SleepReportPage> createState() => _SleepReportPageState();
}

class _SleepReportPageState extends State<SleepReportPage> {
  Map<String, dynamic>? _insight;
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 全部来自服务端：自己写过的日记（睡眠评分）+ 周度洞察。没有记录就是没有，不再读本地缓存、也不再用 prefs 里不存在的 user_id。
    final uid = currentUserId();
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final dio = withSessionAuth(Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: const Duration(seconds: 8))));
      final enc = Uri.encodeComponent(uid);
      final results = await Future.wait([
        dio.get('/api/v1/journal/insights/$enc'),
        dio.get('/api/v1/journal/entries/$enc', queryParameters: {'limit': 7}),
      ]);
      final raw = results[0].data;
      final d = raw is Map && raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : <String, dynamic>{};
      final days = (d['entries_count'] as num?)?.toInt() ?? 0;
      final avgSleep = (d['avg_sleep_quality'] as num?)?.toDouble() ?? 0;
      if (mounted) {
        setState(() {
          _entries = journalEntriesFromBody(results[1].data) ?? const [];
          _insight = days == 0
              ? null
              : {
                  'trend': d['trend_message'] ?? '',
                  'insight': d['tcm_pattern'] ?? '',
                  'score': (avgSleep * 20).round(),
                  'suggestions': d['recommendations'] ?? const [],
                  'data_days': days,
                };
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (_entries.isEmpty) return [];
    final now = DateTime.now();
    final groups = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final entry = _entries.cast<Map<String, dynamic>?>().firstWhere(
        (e) => (e?['date'] ?? '').toString().startsWith(dateStr.substring(0, 10)),
        orElse: () => null,
      );
      final sleep = (entry?['sleep_quality'] ?? 0).toDouble();
      groups.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: sleep,
            color: sleep >= 4 ? const Color(0xFF4CAF50) : sleep >= 3 ? AppColors.primary(context) : const Color(0xFFFF7043),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('睡眠报告',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score card
                  if (_insight != null && (_insight!['score'] ?? 0) > 0) ...[
                    _buildScoreCard(),
                    const SizedBox(height: 24),
                  ],

                  // Bar chart
                  _sectionTitle('7天睡眠质量'),
                  const SizedBox(height: 12),
                  _entries.length >= 3 ? _buildChart() : _buildEmptyState(),
                  const SizedBox(height: 24),

                  // AI Insight
                  if (_insight != null) ...[
                    _sectionTitle('AI 睡眠分析'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGhost(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_insight!['trend'] ?? '',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                          const SizedBox(height: 8),
                          Text(_insight!['insight'] ?? '',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Suggestions
                    if ((_insight!['suggestions'] as List?)?.isNotEmpty == true) ...[
                      _sectionTitle('个性化建议'),
                      const SizedBox(height: 8),
                      ...(_insight!['suggestions'] as List).map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary(context).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s.toString(),
                                style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context), height: 1.5))),
                          ],
                        ),
                      )),

                      // CTA button
                      if ((_insight!['suggestions'] as List?)?.isNotEmpty == true)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              final first = (_insight!['suggestions'] as List).first.toString();
                              context.push('/chat?prefill=${Uri.encodeComponent("我昨晚试了这个建议：$first，感觉如何？")}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('今晚试试这个建议',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily, color: AppColors.textPrimary(context)));

  Widget _buildScoreCard() {
    final score = _insight?['score'] ?? 0;
    final color = score >= 80 ? const Color(0xFF4CAF50) : score >= 60 ? AppColors.primary(context) : const Color(0xFFFF7043);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('睡眠评分', style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context))),
              const SizedBox(height: 4),
              Text('$score', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final groups = _buildBarGroups();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGhost(context)),
      ),
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5,
          barGroups: groups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary(context))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final now = DateTime.now();
                  final d = now.subtract(Duration(days: 6 - v.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${d.month}/${d.day}',
                        style: TextStyle(fontSize: 9, color: AppColors.textTertiary(context))),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppColors.borderGhost(context),
              strokeWidth: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGhost(context)),
      ),
      child: Column(
        children: [
          Text('🌙', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('再记录几天，就能解锁专属睡眠分析 ✨',
              style: TextStyle(fontSize: 15, color: AppColors.textTertiary(context)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
