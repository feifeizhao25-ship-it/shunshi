import '../../../core/router/safe_pop.dart';
import '../../../design_system/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../data/network/session.dart';
import '../../../core/network/locale_headers.dart';
import '../../../design_system/theme.dart';

/// 日记周报页 — 7 天趋势 + 观察建议
class DiaryReportPage extends StatefulWidget {
  const DiaryReportPage({super.key});

  @override
  State<DiaryReportPage> createState() => _DiaryReportPageState();
}

class _DiaryReportPageState extends State<DiaryReportPage> {
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    // 取最近 7 篇自己写过的日记；没有记录就是没有——不再编一周假数据，也不再用写死的 guest 账号。
    final uid = currentUserId();
    if (uid == null) {
      if (mounted) setState(() { _trends = []; _loading = false; });
      return;
    }
    try {
      final dio = withSessionAuth(Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: const Duration(seconds: 8), headers: LocaleHeaders.values)));
      final res = await dio.get('/api/v1/journal/entries/${Uri.encodeComponent(uid)}', queryParameters: {'limit': 7});
      final entries = journalEntriesFromBody(res.data) ?? const <Map<String, dynamic>>[];
      final rows = entries.reversed.map((e) {
        final d = '${e['date'] ?? ''}';
        return <String, dynamic>{
          'date': d.length >= 10 ? d.substring(5, 10) : d,
          'mood': e['mood'] ?? 0,
          'sleep': e['sleep_quality'] ?? 0,
          'energy': e['energy'] ?? 0,
        };
      }).toList();
      if (mounted) setState(() { _trends = rows; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _trends = []; _loading = false; });
    }
  }

  String _generateObservation() {
    if (_trends.isEmpty) return 'No data for this week yet.';
    final avgMood = _trends.map((e) => (e['mood'] ?? 0) as num).reduce((a, b) => a + b) / _trends.length;
    final avgSleep = _trends.map((e) => (e['sleep'] ?? 0) as num).reduce((a, b) => a + b) / _trends.length;
    final parts = <String>[];
    if (avgMood >= 3.5) {
      parts.add('Your mood has held up well this week ✨');
    } else if (avgMood >= 2.5) parts.add('Ups and downs are normal — noticing them is a good start 🌿');
    else parts.add('Your mood has been low this week; be gentle with yourself 🤗');
    if (avgSleep >= 4) {
      parts.add('Your sleep quality has been improving steadily this week 🌙');
    } else if (avgSleep < 3) parts.add('Your sleep needs attention — try a foot soak before bed 💤');
    return parts.join('\n');
  }

  List<String> _generateSuggestions() {
    if (_trends.isEmpty) return ['Start keeping a daily wellness diary!'];
    final avgEnergy = _trends.map((e) => (e['energy'] ?? 0) as num).reduce((a, b) => a + b) / _trends.length;
    final s = <String>[];
    if (avgEnergy < 3) s.add('Energy was low this week. Try a 20-minute midday nap, plus some Baduanjin to recover.');
    s.add('Next week, try logging one small wellness habit a day and watch what changes.');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('Weekly report',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trend chart
                  _sectionTitle('7-day trend'),
                  const SizedBox(height: 16),
                  _buildTrendChart(),
                  const SizedBox(height: 24),

                  // Observations
                  _sectionTitle('This week\'s observations'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGhost(context)),
                    ),
                    child: Text(_generateObservation(),
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.7)),
                  ),
                  const SizedBox(height: 24),

                  // Suggestions
                  _sectionTitle('Next week\'s suggestions'),
                  const SizedBox(height: 8),
                  ..._generateSuggestions().map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary(context).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s,
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context), height: 1.5))),
                    ]),
                  )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily, color: AppColors.textPrimary(context)));

  Widget _buildTrendChart() {
    if (_trends.isEmpty) {
      return Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No data yet', style: TextStyle(color: AppColors.textTertiary(context))),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGhost(context)),
      ),
      child: Column(
        children: [
          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(AppColors.primary(context), 'Mood'),
            const SizedBox(width: 16),
            _legendDot(ShunShiColors.blue, 'Sleep'),
            const SizedBox(width: 16),
            _legendDot(ShunShiColors.secondary, 'Energy'),
          ]),
          const SizedBox(height: 16),
          // Bar chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _trends.map((d) {
                final mood = ((d['mood'] ?? 0) as num).toDouble().clamp(0, 5);
                final sleep = ((d['sleep'] ?? 0) as num).toDouble().clamp(0, 5);
                final energy = ((d['energy'] ?? 0) as num).toDouble().clamp(0, 5);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Mood bar
                        Container(width: 6, height: mood * 20,
                            decoration: BoxDecoration(color: AppColors.primary(context), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(height: 2),
                        // Sleep bar
                        Container(width: 6, height: sleep * 20,
                            decoration: BoxDecoration(color: ShunShiColors.blue, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(height: 2),
                        // Energy bar
                        Container(width: 6, height: energy * 20,
                            decoration: BoxDecoration(color: ShunShiColors.secondary, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(height: 4),
                        Text(d['date']?.toString() ?? '',
                            style: TextStyle(fontSize: 9, color: AppColors.textTertiary(context))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary(context))),
  ]);
}
