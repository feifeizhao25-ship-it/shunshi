/// 节气养生详情页 — 对接 /api/v1/solar-wellness API
/// 显示: 节气信息 + 饮食建议 + 运动建议 + 睡眠建议 + 时辰信息
library;

import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/cache_service.dart';
import '../../../core/loading/loading_state_manager.dart';

class SolarDetailPage extends StatefulWidget {
  const SolarDetailPage({super.key});

  @override
  State<SolarDetailPage> createState() => _SolarDetailPageState();
}

class _SolarDetailPageState extends State<SolarDetailPage> {
  final _api = ApiClient();
  final _cache = CacheService();
  late final LoadingDelayManager _loadingDelay;
  bool _showLoading = false;
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadingDelay = LoadingDelayManager(delayMs: 200, minDisplayMs: 400, onStateChanged: () { if (mounted) setState(() => _showLoading = _loadingDelay.showLoading); });
    _loadData();
  }

  @override
  void dispose() {
    _loadingDelay.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 缓存配置: wellness staleTime=5min
    const cacheConfig = CacheConfig(
      staleTime: Duration(minutes: 5),
      gcTime: Duration(hours: 24),
      persist: true,
    );
    const cacheKey = 'solar_wellness_daily_advice';

    // 1. Try cache
    final cached = _cache.get<Map<String, dynamic>>(cacheKey, config: cacheConfig);
    if (cached != null) {
      _data = cached.data;
      if (mounted) setState(() => _loading = false);
      if (!cached.isStale) return;
    } else {
      _loadingDelay.startLoading();
      if (mounted) setState(() => _showLoading = true);
    }

    // 2. Network
    try {
      final res = await _api.get('/solar-wellness/daily-advice', level: SpeedLevel.s2);
      if (res.data is Map && res.data['success'] == true) {
        _data = Map<String, dynamic>.from(res.data['data']);
        await _cache.set(cacheKey, _data!, config: cacheConfig);
      }
    } catch (_) {}
    _loadingDelay.stopLoading();
    if (mounted) setState(() { _loading = false; _showLoading = _loadingDelay.showLoading; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _showLoading) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final cardBg = isDark ? ShunShiColors.darkSurface : ShunShiColors.background;

    return Scaffold(
      backgroundColor: cardBg,
      appBar: AppBar(
        title: Text('${solar['name'] ?? '节气'}养生', style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.textPrimary,
          fontWeight: FontWeight.w700,
        )),
        backgroundColor: cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary),
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
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
                  const SizedBox(height: 8),
                  Text(solar['principle'] ?? '', style: TextStyle(
                    fontSize: 16, color: Colors.white.withValues(alpha: 0.9),
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
              _buildSection('少食', Icons.block, avoidList, isDark ? ShunShiColors.darkSecondary : ShunShiColors.secondary),
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

  Widget _buildBadge(String text, {Color? textColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = textColor ?? (isDark ? ShunShiColors.darkTextPrimary : Colors.white);
    final bgAlpha = isDark ? 0.3 : 0.2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: tc)),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> items, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child: Text(item, style: TextStyle(fontSize: 14, color: isDark ? ShunShiColors.darkTextPrimary : color)),
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
