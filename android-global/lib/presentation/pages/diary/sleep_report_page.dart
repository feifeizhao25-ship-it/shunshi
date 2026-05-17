import 'dart:convert';
import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
import '../../../core/config/app_config.dart';

/// Sleep Report页 — 7天柱状图 + AI趋势分析 + 建议
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

  Future<Dio> _dio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
    ));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final dio = await _dio();

    try {
      final [insightRes, entriesRes] = await Future.wait([
        dio.get('/api/v1/records/sleep/stats', queryParameters: {'user_id': userId}),
        dio.get('/api/v1/journal/entries/$userId', queryParameters: {
          
          'limit': 7,
        }),
      ]);
      setState(() {
        _insight = Map<String, dynamic>.from(insightRes.data);
        _entries = List<Map<String, dynamic>>.from(entriesRes.data ?? []);
        _loading = false;
      });
    } catch (_) {
      // Offline fallback: try cached entries
      final cached = prefs.getString('diary_entries');
      if (cached != null) {
        try {
          final list = List<Map<String, dynamic>>.from(
            (const JsonDecoder().convert(cached) as List).map((e) => Map<String, dynamic>.from(e)),
          );
          setState(() {
            _entries = list.take(7).toList();
            _insight = {
              'insight': list.length < 3
                  ? 'Log a few more days to unlock your personalized sleep analysis ✨'
                  : 'Sleep analysis loading — connect to network for full report',
              'trend': 'Collecting data',
              'score': 0,
              'suggestions': ['Keep logging your sleep quality daily'],
              'source_references': [],
              'data_days': list.length,
            };
          });
        } catch (_) {}
      }
      setState(() => _loading = false);
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
        (e) => (e?['entry_date'] ?? '').toString().startsWith(dateStr.substring(0, 10)),
        orElse: () => null,
      );
      final sleep = (entry?['sleep_quality'] ?? 0).toDouble();
      groups.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: sleep,
            color: sleep >= 4 ? const Color(0xFF4CAF50) : sleep >= 3 ? ShunShiColors.primary : const Color(0xFFFF7043),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: Text(AppLocalizations.of(context).t('sleep_report'),
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
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
                  _sectionTitle('7-Day Sleep Quality'),
                  const SizedBox(height: 12),
                  _entries.length >= 3 ? _buildChart() : _buildEmptyState(),
                  const SizedBox(height: 24),

                  // AI Insight
                  if (_insight != null) ...[
                    _sectionTitle('AI Sleep Analysis'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ShunShiColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ShunShiColors.borderGhost),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_insight!['trend'] ?? '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(_insight!['insight'] ?? '',
                              style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Suggestions
                    if ((_insight!['suggestions'] as List?)?.isNotEmpty == true) ...[
                      _sectionTitle('Personalized Tips'),
                      const SizedBox(height: 8),
                      ...(_insight!['suggestions'] as List).map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s.toString(),
                                style: const TextStyle(fontSize: 14, color: ShunShiColors.textPrimary, height: 1.5))),
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
                              context.push('/chat?prefill=${Uri.encodeComponent("I tried this tip last night: $first. How did it feel?")}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ShunShiColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(AppLocalizations.of(context).t('diary_try_this_tonight'),
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary));

  Widget _buildScoreCard() {
    final score = _insight?['score'] ?? 0;
    final color = score >= 80 ? const Color(0xFF4CAF50) : score >= 60 ? ShunShiColors.primary : const Color(0xFFFF7043);
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
              Text(AppLocalizations.of(context).t('diary_sleep_score'), style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
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
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.borderGhost),
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
                    style: const TextStyle(fontSize: 10, color: ShunShiColors.textTertiary)),
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
                        style: const TextStyle(fontSize: 9, color: ShunShiColors.textTertiary)),
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
              color: ShunShiColors.borderGhost,
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
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.borderGhost),
      ),
      child: const Column(
        children: [
          Text('🌙', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('Log a few more days to unlock your personalized sleep analysis ✨',
              style: TextStyle(fontSize: 15, color: ShunShiColors.textTertiary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
