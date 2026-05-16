import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

/// Journalweek报页 — 7 day趋势 + 观察suggestion: 
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
    try {
      final dio = Dio();
      final res = await dio.get('/api/v1/journal/trends');
      if (res.data is List) {
        setState(() {
          _trends = List<Map<String, dynamic>>.from(res.data);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Demo data
    final now = DateTime.now();
    setState(() {
      _trends = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return {
          'date': '${d.month}/${d.day}',
          'mood': 2.5 + (i * 0.3).clamp(0, 2),
          'sleep': 3.0 + (i % 3) * 0.5,
          'energy': 2.0 + i * 0.4,
        };
      });
      _loading = false;
    });
  }

  String _generateObservation() {
    if (_trends.isEmpty) return 'This weekNo data。';
    final avgMood = _trends.map((e) => (e['mood'] ?? 0) as num).reduce((a, b) => a + b) / _trends.length;
    final avgSleep = _trends.map((e) => (e['sleep'] ?? 0) as num).reduce((a, b) => a + b) / _trends.length;
    final parts = <String>[];
    if (avgMood >= 3.5) {
      parts.add('Your emotional wellbeing this week has been great ✨');
    } else if (avgMood >= 2.5) parts.add('Emotional fluctuations are normal — staying mindful is a great start 🌿');
    else parts.add('This week emotions are a bit low — remember to be gentle with yourself 🤗');
    if (avgSleep >= 4) {
      parts.add('Sleep quality improved steadily this week 🌙');
    } else if (avgSleep < 3) parts.add('Sleep quality needs attention — try a warm foot bath before bed 💤');
    return parts.join('\n');
  }

  List<String> _generateSuggestions() {
    if (_trends.isEmpty) return ['Start recording your daily wellness journal!'];
    final avgEnergy = _trends.map((e) => (e['energy'] ?? 0) as num).reduce((a, b) => a + b) / _trends.length;
    final s = <String>[];
    if (avgEnergy < 3) s.add('Low energy this week — try a 20 min nap in the noon hour, combined with Baduanjin to restore Qi.');
    s.add('Next week, try recording one wellness habit daily and observe the changes.');
    return s;
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
        title: Text(AppLocalizations.of(context).t('diary_weekly_report'),
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trend chart
                  _sectionTitle('7-Day Trend'),
                  const SizedBox(height: 16),
                  _buildTrendChart(),
                  const SizedBox(height: 24),

                  // Observations
                  _sectionTitle('This Week\'s Observations'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ShunShiColors.borderGhost),
                    ),
                    child: Text(_generateObservation(),
                        style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.7)),
                  ),
                  const SizedBox(height: 24),

                  // Suggestions
                  _sectionTitle('Next Week Suggestions'),
                  const SizedBox(height: 8),
                  ..._generateSuggestions().map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ShunShiColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s,
                          style: const TextStyle(fontSize: 14, color: ShunShiColors.textPrimary, height: 1.5))),
                    ]),
                  )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary));

  Widget _buildTrendChart() {
    if (_trends.isEmpty) {
      return Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(AppLocalizations.of(context).t('diary_no_data'), style: TextStyle(color: ShunShiColors.textTertiary)),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.borderGhost),
      ),
      child: Column(
        children: [
          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(ShunShiColors.primary, 'Mood'),
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
                            decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: BorderRadius.circular(3))),
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
                            style: const TextStyle(fontSize: 9, color: ShunShiColors.textTertiary)),
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
    Text(label, style: const TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
  ]);
}
