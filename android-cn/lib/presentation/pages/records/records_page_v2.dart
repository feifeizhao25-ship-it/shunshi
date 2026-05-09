/// 养生记录页 V3 — 接 API
/// GET /api/v1/records/care/today, /care/stats, /emotion, /sleep
library;

import 'package:dio/dio.dart';
import '../../widgets/state_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class RecordsPageV2 extends StatefulWidget {
  const RecordsPageV2({super.key});
  @override
  State<RecordsPageV2> createState() => _RecordsPageV2State();
}

class _RecordsPageV2State extends State<RecordsPageV2> {
  static const _baseUrl = 'http://116.62.32.43:4000';
  final _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 8)));
  
  int _weekStreak = 0;
  int _totalPoints = 0;
  int _todayDone = 0;
  int _todayTotal = 5;
  List<Map<String, dynamic>> _emotionTrends = [];
  Map<String, dynamic> _sleepStats = {};
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getToken();
    await _fetchData();
  }

  Future<void> _getToken() async {
    try {
      final res = await _dio.post('/api/v1/auth/guest-login', data: {});
      _token = res.data['data']['token'];
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    if (_token == null) { setState(() => _loading = false); return; }
    final headers = {'Authorization': 'Bearer $_token'};
    try {
      final results = await Future.wait([
        _dio.get('/api/v1/records/care/stats', options: Options(headers: headers)),
        _dio.get('/api/v1/records/care/today', options: Options(headers: headers)),
        _dio.get('/api/v1/records/emotion/trends', options: Options(headers: headers)),
        _dio.get('/api/v1/records/sleep/stats', options: Options(headers: headers)),
      ]);
      // Stats
      final stats = results[0].data;
      if (stats is Map && stats['data'] is Map) {
        final d = stats['data'] as Map<String, dynamic>;
        _weekStreak = d['week_streak'] as int? ?? 0;
        _totalPoints = d['total_points'] as int? ?? 0;
      }
      // Today
      final today = results[1].data;
      if (today is Map && today['data'] is Map) {
        final d = today['data'] as Map<String, dynamic>;
        _todayDone = d['completed'] as int? ?? 0;
        _todayTotal = d['total'] as int? ?? 5;
      }
      // Emotion trends
      final emotions = results[2].data;
      if (emotions is Map && emotions['data'] is List) {
        _emotionTrends = (emotions['data'] as List).cast<Map<String, dynamic>>();
      }
      // Sleep stats
      final sleep = results[3].data;
      if (sleep is Map && sleep['data'] is Map) {
        _sleepStats = Map<String, dynamic>.from(sleep['data'] as Map);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    if (_loading) return Scaffold(backgroundColor: bg, body: const LoadingSkeleton());

    final progress = _todayTotal > 0 ? _todayDone / _todayTotal : 0.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('养生记录', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: ShunShiColors.primary,
        onRefresh: _fetchData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Stats card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(child: _buildStat('本周打卡', '$_weekStreak天')),
                Expanded(child: _buildStat('今日完成', '$_todayDone/$_todayTotal')),
                Expanded(child: _buildStat('累计积分', '$_totalPoints')),
              ]),
            ),
            const SizedBox(height: 16),

            // Today progress
            Text('今日进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(progress >= 1.0 ? Icons.celebration : Icons.wb_sunny, color: ShunShiColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('今天', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const Spacer(),
                  Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 13, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 8),
                Text(progress >= 1.0 ? '已完成全部习惯！' : '已完成 $_todayDone/$_todayTotal 项习惯',
                  style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: progress, backgroundColor: ShunShiColors.surfaceContainerLow, color: ShunShiColors.primary, minHeight: 4)),
              ]),
            ),
            const SizedBox(height: 16),

            // Sleep stats
            if (_sleepStats.isNotEmpty) ...[
              Text('睡眠统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.bedtime, color: ShunShiColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('平均睡眠', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                    Text('${_sleepStats['avg_hours'] ?? '-'}小时', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
                  ])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('质量评分', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                    Text('${_sleepStats['avg_quality'] ?? '-'}/5', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Emotion trends
            if (_emotionTrends.isNotEmpty) ...[
              Text('情绪趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 12),
              ..._emotionTrends.take(5).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(_emotionIcon(e['avg_mood'] as int? ?? 3), color: ShunShiColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(e['date']?.toString().substring(5, 10) ?? '', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
                    const Spacer(),
                    Text(_emotionLabel(e['avg_mood'] as int? ?? 3), style: TextStyle(fontSize: 13, color: ShunShiColors.textPrimary)),
                  ]),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
    ]);
  }

  IconData _emotionIcon(int mood) {
    if (mood >= 4) return Icons.sentiment_satisfied;
    if (mood >= 3) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _emotionLabel(int mood) {
    if (mood >= 5) return '很开心';
    if (mood >= 4) return '心情不错';
    if (mood >= 3) return '比较平静';
    if (mood >= 2) return '有些疲惫';
    return '心情低落';
  }
}
