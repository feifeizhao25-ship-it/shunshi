import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/config/app_config.dart';

/// 成就页
///
/// 参考: _6/code.html — Achievements + 进度统计 + 徽章收集
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''), connectTimeout: const Duration(seconds: 8)));
  int _points = 0;
  int _level = 1;
  int _streak = 0;
  List<Map<String, dynamic>> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await _dio.get('/api/v1/gamification/user/guest');
      final data = res.data;
      if (data is Map) {
        final d = data['data'] is Map ? data['data'] as Map : data;
        setState(() {
          _points = (d['points'] ?? 0) as int;
          _level = (d['level'] ?? 1) as int;
          _streak = (d['streak_days'] ?? 0) as int;
        });
      }
    } catch (_) {}
    try {
      final res = await _dio.get('/api/v1/gamification/badges');
      final data = res.data;
      if (data is Map && data['data'] is List) {
        setState(() => _badges = (data['data'] as List).cast<Map<String, dynamic>>());
      } else if (data is List) {
        setState(() => _badges = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  // Fallback badges
  static const _fallbackBadges = [
    {'icon': '🌅', 'name': '早起达人', 'unlocked': true},
    {'icon': '🧘', 'name': '修炼入门', 'unlocked': true},
    {'icon': '🍵', 'name': '食疗专家', 'unlocked': true},
    {'icon': '🏔️', 'name': '百日坚持', 'unlocked': false},
    {'icon': '🌿', 'name': '节气大师', 'unlocked': false},
    {'icon': '⭐', 'name': '社区之星', 'unlocked': false},
  ];

  List<Map<String, dynamic>> get _displayBadges => _badges.isNotEmpty ? _badges : _fallbackBadges;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '成就',
                              style: TextStyle(
                                fontFamily: ShunShiTypography.sansFamily,
                                fontSize: 13,
                                color: ShunShiColors.textTertiary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '养生成就',
                              style: TextStyle(
                                fontFamily: ShunShiTypography.serifFamily,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: ShunShiColors.primary,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ShunShiColors.surfaceContainerLow,
                          ),
                          child: const Icon(Icons.person_outline,
                              color: ShunShiColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '记录您养生旅程的每一步',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 14,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Stats Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _StatCard('连续打卡', '$_streak', ' 天', Icons.local_fire_department),
                    const SizedBox(width: 12),
                    _StatCard('等级', '$_level', '', Icons.military_tech),
                    const SizedBox(width: 12),
                    _StatCard('积分', '$_points', '', Icons.stars),
                  ],
                ),
              ),
            ),

            // ── Progress Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前进度',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ShunShiColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressCard(
                      title: '百日养生挑战',
                      current: 42,
                      total: 100,
                      icon: Icons.emoji_events,
                    ),
                    const SizedBox(height: 12),
                    _ProgressCard(
                      title: '功法全集',
                      current: 3,
                      total: 8,
                      icon: Icons.self_improvement,
                    ),
                    const SizedBox(height: 12),
                    _ProgressCard(
                      title: '二十四节气养生',
                      current: 6,
                      total: 24,
                      icon: Icons.filter_vintage,
                    ),
                  ],
                ),
              ),
            ),

            // ── Badges Grid ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '已获徽章',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ShunShiColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        ..._displayBadges.map((b) => _BadgeCard(
                          icon: (b['icon'] ?? b['emoji'] ?? '🏅') as String,
                          label: (b['name'] ?? b['title'] ?? '') as String,
                          unlocked: (b['unlocked'] ?? b['is_unlocked'] ?? false) as bool,
                        )),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _StatCard(this.label, this.value, this.unit, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: ShunShiColors.primary, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ShunShiColors.primary,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: unit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 11,
                color: ShunShiColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final int current;
  final int total;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.current,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: ShunShiColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: ShunShiColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$current / $total',
                style: TextStyle(
                  fontFamily: ShunShiTypography.sansFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ShunShiColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: ShunShiColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(ShunShiColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool unlocked;

  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: ShunShiColors.goldLight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 32,
              color: unlocked ? null : ShunShiColors.textDisabled,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: ShunShiTypography.sansFamily,
              fontSize: 12,
              color: unlocked ? ShunShiColors.textPrimary : ShunShiColors.textDisabled,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
