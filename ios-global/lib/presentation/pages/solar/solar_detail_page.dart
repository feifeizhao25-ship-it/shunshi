/// 节气养生详情页 — 对接 /api/v1/solar-wellness API
/// 显示: 节气信息 + 饮食建议 + 运动建议 + 睡眠建议 + 时辰信息
library;

import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import 'package:dio/dio.dart';

class SolarDetailPage extends StatefulWidget {
  const SolarDetailPage({super.key});

  @override
  State<SolarDetailPage> createState() => _SolarDetailPageState();
}

class _SolarDetailPageState extends State<SolarDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.seasonsapp.com',
        connectTimeout: const Duration(seconds: 5),
      ));
      final res = await dio.get('/api/v1/solar-wellness/daily-advice');
      if (res.data is Map && res.data['success'] == true) {
        _data = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_data == null) {
      return const Scaffold(body: Center(child: Text('加载失败')));
    }

    final solar = _data!['solar_term'] as Map<String, dynamic>? ?? {};
    final shichen = _data!['shichen'] as Map<String, dynamic>? ?? {};
    final dietList = (_data!['diet_recommend'] as List?)?.cast<String>() ?? [];
    final avoidList = (_data!['diet_avoid'] as List?)?.cast<String>() ?? [];
    final exercise = _data!['exercise'] as String? ?? '';
    final sleepAdvice = _data!['sleep_advice'] as String? ?? '';
    final nextTerm = _data!['next_term'] as String? ?? '';

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        title: Text('${solar['name'] ?? '节气'}养生', style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.textPrimary,
          fontWeight: FontWeight.w700,
        )),
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ShunShiColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ShunShiColors.primary, ShunShiColors.primary.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(solar['name'] ?? '', style: TextStyle(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFDF9F4),
                  )),
                  const SizedBox(height: 8),
                  Text(solar['principle'] ?? '', style: TextStyle(
                    fontSize: 16, color: Color(0xFFFDF9F4).withValues(alpha: 0.9),
                  )),
                  const SizedBox(height: 12),
                  Row(children: [
                    _buildBadge('${solar['element'] ?? ''}行'),
                    const SizedBox(width: 8),
                    _buildBadge('${solar['organ'] ?? ''}经'),
                    const SizedBox(width: 8),
                    _buildBadge('${shichen['name'] ?? ''} ${shichen['organ'] ?? ''}经'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 宜食
            _buildSection('宜食', Icons.restaurant, dietList, ShunShiColors.primary),
            const SizedBox(height: 16),

            // 忌食
            if (avoidList.isNotEmpty) ...[
              _buildSection('少食', Icons.block, avoidList, Color(0xFF74593C)),
              const SizedBox(height: 16),
            ],

            // 运动
            if (exercise.isNotEmpty) ...[
              _buildInfoCard('运动建议', Icons.fitness_center, exercise),
              const SizedBox(height: 16),
            ],

            // 睡眠
            if (sleepAdvice.isNotEmpty) ...[
              _buildInfoCard('睡眠建议', Icons.bedtime, sleepAdvice),
              const SizedBox(height: 16),
            ],

            // 时辰
            _buildInfoCard('当前时辰', Icons.access_time,
              '${shichen['name'] ?? ''}（${shichen['organ'] ?? ''}经当令）\n${shichen['advice'] ?? ''}'),
            const SizedBox(height: 16),

            // 下一个节气
            if (nextTerm.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.arrow_forward, color: ShunShiColors.textTertiary, size: 20),
                  const SizedBox(width: 8),
                  Text('下一个节气：$nextTerm', style: TextStyle(
                    color: ShunShiColors.textTertiary, fontSize: 14,
                  )),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFFDF9F4).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: Color(0xFFFDF9F4))),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(item, style: TextStyle(fontSize: 14, color: color)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: ShunShiColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}
