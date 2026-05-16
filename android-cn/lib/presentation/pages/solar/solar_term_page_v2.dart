/// 节气详情页 — 沉浸式 UI v3
/// 数据: /api/v1/solar-terms/enhanced/current + /enhanced/{name}
/// 展示节气内涵、饮食/运动/茶饮建议
/// v3: 沉浸大卡片 + 进度环 + Tab分组 + 入场动画 + 滑动切换
library;

import 'dart:math' as math;
import '../../widgets/state_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/cache_service.dart';
import '../../../core/loading/loading_state_manager.dart';

// ── 季节渐变色配置 ──
class _SeasonColors {
  final List<Color> gradient;
  final Color accent;
  final Color accentDim;

  const _SeasonColors({
    required this.gradient,
    required this.accent,
    required this.accentDim,
  });

  static _SeasonColors forName(String? name) {
    if (name == null) return spring;
    // 24 节气按季节分组
    const springTerms = {'立春', '雨水', '惊蛰', '春分', '清明', '谷雨'};
    const summerTerms = {'立夏', '小满', '芒种', '夏至', '小暑', '大暑'};
    const autumnTerms = {'立秋', '处暑', '白露', '秋分', '寒露', '霜降'};
    if (springTerms.contains(name)) return spring;
    if (summerTerms.contains(name)) return summer;
    if (autumnTerms.contains(name)) return autumn;
    return winter;
  }

  static const spring = _SeasonColors(
    gradient: [Color(0xFF2D5A3D), Color(0xFF4A7C59)],
    accent: Color(0xFF7CB68A),
    accentDim: Color(0xFF3E6B4D),
  );
  static const summer = _SeasonColors(
    gradient: [Color(0xFF8B3A3A), Color(0xFFC05050)],
    accent: Color(0xFFE88A7A),
    accentDim: Color(0xFF7A3535),
  );
  static const autumn = _SeasonColors(
    gradient: [Color(0xFF8B6914), Color(0xFFC49B2A)],
    accent: Color(0xFFE4C285),
    accentDim: Color(0xFF7A5E18),
  );
  static const winter = _SeasonColors(
    gradient: [Color(0xFF3A5A7A), Color(0xFF5A8AAF)],
    accent: Color(0xFF8AB8D8),
    accentDim: Color(0xFF2E4A66),
  );
}

class SolarTermPageV2 extends StatefulWidget {
  final String? termName;
  const SolarTermPageV2({super.key, this.termName});

  @override
  State<SolarTermPageV2> createState() => _SolarTermPageV2State();
}

class _SolarTermPageV2State extends State<SolarTermPageV2>
    with TickerProviderStateMixin {
  final _api = ApiClient();
  final _cache = CacheService();
  late final LoadingDelayManager _loadingDelay;

  Map<String, dynamic> _term = {};
  Map<String, dynamic> _next = {};
  Map<String, dynamic> _wellness = {};
  bool _loading = true;
  bool _showLoading = false;

  // Tab & animation state
  int _wellnessTab = 0;
  late final AnimationController _staggerController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<double>> _scaleAnimations;

  static const _staggerCount = 5; // hero, next, progress, tabs, bottom

  @override
  void initState() {
    super.initState();
    _loadingDelay = LoadingDelayManager(
      delayMs: 200,
      minDisplayMs: 400,
      onStateChanged: () {
        if (mounted) setState(() => _showLoading = _loadingDelay.showLoading);
      },
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimations = List.generate(_staggerCount, (i) {
      final start = i * 0.1;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, start + 0.4, curve: Curves.easeOut),
      );
    });
    _scaleAnimations = List.generate(_staggerCount, (i) {
      final start = i * 0.1;
      return Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, start + 0.4, curve: Curves.easeOut),
        ),
      );
    });

    _fetchData();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _loadingDelay.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    const cacheConfig = CacheConfig(
      staleTime: Duration(minutes: 30),
      gcTime: Duration(hours: 24),
      persist: true,
    );

    final path = widget.termName != null
        ? '/solar-terms/enhanced/${Uri.encodeComponent(widget.termName!)}'
        : '/solar-terms/enhanced/current';
    final cacheKey = CacheKeys.solarTerm(widget.termName ?? 'current');

    final cached =
        _cache.get<Map<String, dynamic>>(cacheKey, config: cacheConfig);
    if (cached != null) {
      _applyData(cached.data);
      if (mounted) setState(() => _loading = false);
      _staggerController.forward();
      if (!cached.isStale) return;
    } else {
      _loadingDelay.startLoading();
      if (mounted) setState(() => _showLoading = true);
    }

    try {
      final res = await _api.get(path, level: SpeedLevel.s2);
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final d = data['data'] as Map;
        final cacheData = <String, dynamic>{};
        if (d['current'] is Map) {
          _term = Map<String, dynamic>.from(d['current']);
          cacheData['current'] = _term;
          if (d['next'] is Map) {
            _next = Map<String, dynamic>.from(d['next']);
            cacheData['next'] = _next;
          }
        } else if (d['term'] is Map) {
          _term = Map<String, dynamic>.from(d['term']);
          cacheData['term'] = _term;
        }
        if (d['wellness_plan'] is Map) {
          _wellness = Map<String, dynamic>.from(d['wellness_plan']);
          cacheData['wellness_plan'] = _wellness;
        }
        await _cache.set(cacheKey, cacheData, config: cacheConfig);
      }
      _loadingDelay.stopLoading();
      if (mounted) {
        setState(() {
          _loading = false;
          _showLoading = _loadingDelay.showLoading;
        });
        _staggerController.forward(from: 0);
      }
    } catch (_) {
      _loadingDelay.stopLoading();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showLoading = _loadingDelay.showLoading;
      });
    }
  }

  void _applyData(Map<String, dynamic> data) {
    if (data['current'] is Map) {
      _term = Map<String, dynamic>.from(data['current']);
      if (data['next'] is Map) _next = Map<String, dynamic>.from(data['next']);
    } else if (data['term'] is Map) {
      _term = Map<String, dynamic>.from(data['term']);
    }
    if (data['wellness_plan'] is Map) {
      _wellness = Map<String, dynamic>.from(data['wellness_plan']);
    }
  }

  // ── 节气进度计算 ──
  double get _progress {
    final daysRemaining = _term['days_remaining'];
    final totalDays = _term['total_days'] ?? 15;
    if (daysRemaining is num && totalDays > 0) {
      final elapsed = (totalDays - daysRemaining.toInt()).clamp(0, totalDays);
      return elapsed / totalDays;
    }
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final season = _SeasonColors.forName(_term['name']?.toString());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      body: _loading && _showLoading
          ? const LoadingSkeleton()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── 1. 沉浸式节气大卡片 ──
                SliverToBoxAdapter(
                  child: _AnimatedStaggerBlock(
                    fade: _fadeAnimations[0],
                    scale: _scaleAnimations[0],
                    child: _buildHeroCard(isDark, season),
                  ),
                ),

                // ── 2. 下一个节气预告 + 进度环 ──
                SliverToBoxAdapter(
                  child: _AnimatedStaggerBlock(
                    fade: _fadeAnimations[1],
                    scale: _scaleAnimations[1],
                    child: _buildNextAndProgress(isDark, season),
                  ),
                ),

                // ── 3. 养生建议 Tab 分组 ──
                SliverToBoxAdapter(
                  child: _AnimatedStaggerBlock(
                    fade: _fadeAnimations[2],
                    scale: _scaleAnimations[2],
                    child: _buildWellnessTabs(isDark),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. 沉浸式节气大卡片 — 渐变背景随季节变化
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeroCard(bool isDark, _SeasonColors season) {
    final topPadding = MediaQuery.of(context).padding.top + 56; // AppBar height

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Stack(
        children: [
          // ── Background image ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/solar_term_hero.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // ── Gradient overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [season.gradient[0].withValues(alpha: 0.7), season.gradient[1].withValues(alpha: 0.6)]
                      : [season.gradient[0].withValues(alpha: 0.75), season.gradient[1].withValues(alpha: 0.65)],
                ),
              ),
            ),
          ),
          // ── Card content ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPadding, 24, 28),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Hero(
                tag: 'solar_term_${_term['name'] ?? 'unknown'}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    _term['emoji']?.toString() ?? '🌿',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _term['name']?.toString() ?? '节气',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // name_en removed for CN version
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date + countdown
          if (_term['date'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 6),
                  Text(
                    '${_term['date']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (_term['days_remaining'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: season.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time,
                      size: 14, color: season.accent),
                  const SizedBox(width: 6),
                  Text(
                    '距下一节气 ${_term['days_remaining']} 天',
                    style: TextStyle(
                      fontSize: 13,
                      color: season.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. 下一个节气预告 + 进度环
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNextAndProgress(bool isDark, _SeasonColors season) {
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final textPrimary =
        isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary =
        isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 进度环
            _ProgressRing(
              progress: _progress,
              color: season.accent,
              trackColor: isDark
                  ? ShunShiColors.darkSurfaceContainerLowest
                  : ShunShiColors.surfaceContainerLow,
              size: 68,
              strokeWidth: 5,
              child: Text(
                '${(_progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 虚线连接器
            Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: CustomPaint(
                    size: const Size(2, double.infinity),
                    painter: _DashedLinePainter(
                      color: isDark
                          ? ShunShiColors.darkBorder
                          : ShunShiColors.borderGhost,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(width: 12),

            // 下一个节气 mini card
            if (_next.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? ShunShiColors.darkBorder
                          : ShunShiColors.borderGhost,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下一个节气',
                        style: TextStyle(
                          fontSize: 11,
                          color: textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(_next['emoji']?.toString() ?? '🌱',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _next['name']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_next['countdown_days'] != null ? '${_next['countdown_days']}天后' : _next['date'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. 养生建议 Tab 分组
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWellnessTabs(bool isDark) {
    final tabs = <_WellnessTabConfig>[
      _WellnessTabConfig(
        label: '饮食',
        icon: Icons.restaurant,
        key: 'diet',
        emoji: '🍲',
      ),
      _WellnessTabConfig(
        label: '运动',
        icon: Icons.fitness_center,
        key: 'exercise',
        emoji: '🧘',
      ),
      _WellnessTabConfig(
        label: '茶饮',
        icon: Icons.local_cafe,
        key: 'tea',
        emoji: '🫖',
      ),
    ];

    // Filter to only tabs that have data
    final activeTabs =
        tabs.where((t) => _wellness[t.key] is List).toList();
    if (activeTabs.isEmpty) return const SizedBox.shrink();

    // Ensure _wellnessTab is valid
    if (_wellnessTab >= activeTabs.length) _wellnessTab = 0;

    final textPrimary =
        isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final primaryColor = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            '养生建议',
            style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? ShunShiColors.darkSurfaceContainerLow
                  : ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(activeTabs.length, (i) {
                final selected = _wellnessTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _wellnessTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark
                                ? ShunShiColors.darkSurfaceContainerLowest
                                : ShunShiColors.surfaceContainerLowest)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(activeTabs[i].icon,
                              size: 16,
                              color: selected
                                  ? primaryColor
                                  : (isDark
                                      ? ShunShiColors.darkTextTertiary
                                      : ShunShiColors.textTertiary)),
                          const SizedBox(width: 6),
                          Text(
                            activeTabs[i].label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? primaryColor
                                  : (isDark
                                      ? ShunShiColors.darkTextTertiary
                                      : ShunShiColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          _buildWellnessCardList(
            activeTabs[_wellnessTab],
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessCardList(_WellnessTabConfig tab, bool isDark) {
    final items = (_wellness[tab.key] as List)
        .cast<Map<String, dynamic>>()
        .toList();
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final textPrimary =
        isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary =
        isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    final primaryColor =
        isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              final id = item['id']?.toString();
              if (id != null && id.isNotEmpty) {
                context.push('/content-detail', extra: {'contentId': id});
              } else {
                final termName = _term['name']?.toString() ?? '';
                context.push('/solar-ai/${Uri.encodeComponent(termName)}');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? ShunShiColors.darkBorder : ShunShiColors.borderGhost,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(tab.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['description']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: textTertiary,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((item['tags'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (item['tags'] as List)
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

class _WellnessTabConfig {
  final String label;
  final IconData icon;
  final String key;
  final String emoji;
  const _WellnessTabConfig({
    required this.label,
    required this.icon,
    required this.key,
    required this.emoji,
  });
}

/// Staggered fade + scale animation wrapper
class _AnimatedStaggerBlock extends StatelessWidget {
  final Animation<double> fade;
  final Animation<double> scale;
  final Widget child;

  const _AnimatedStaggerBlock({
    required this.fade,
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: child,
      ),
    );
  }
}

/// 进度环 — CustomPainter
class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.size = 68,
    this.strokeWidth = 5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          trackColor: trackColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 虚线连接线
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpacing = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => false;
}
