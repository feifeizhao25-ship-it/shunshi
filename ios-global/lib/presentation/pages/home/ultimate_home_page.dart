/// Home Page (Today) — aligned with UI reference _1
/// Design: Ink wash paper style + frosted glass AI module
/// Structure: TopBar → ShiChen title → Hero wellness image → Bento actions → AI assistant → CTA
library;

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../design_system/theme.dart';
import 'package:go_router/go_router.dart';
import 'widgets/home_skeleton.dart';
import '../../../core/culture/device_hints.dart';
import '../../../core/culture/opening_greeting.dart';
import '../../../core/day_part/day_part.dart';
import '../settings/culture_binding.dart';
import 'widgets/personal_home_binding.dart';
import '../../widgets/personal_home_section.dart';
import '../../../data/services/offline_cache.dart';

// ═══════════════════════════════════════════════════════════════
// Solar Term Mapping (approximate by month)
// ═══════════════════════════════════════════════════════════════

(String, String) _currentTermAndNorthSeason() {
  final now = DateTime.now();
  final month = now.month;
  final day = now.day;
  // Approximate mapping
  const terms = [
    (1, 6, 'Minor Cold', 'Late Winter'), (1, 20, 'Major Cold', 'Late Winter'),
    (2, 4, 'Start of Spring', 'Early Spring'), (2, 19, 'Rain Water', 'Early Spring'),
    (3, 6, 'Awakening', 'Mid Spring'), (3, 21, 'Spring Equinox', 'Mid Spring'),
    (4, 5, 'Clear & Bright', 'Late Spring'), (4, 20, 'Grain Rain', 'Late Spring'),
    (5, 6, 'Start of Summer', 'Early Summer'), (5, 21, 'Grain Buds', 'Early Summer'),
    (6, 6, 'Grain in Ear', 'Mid Summer'), (6, 21, 'Summer Solstice', 'Mid Summer'),
    (7, 7, 'Minor Heat', 'Late Summer'), (7, 23, 'Major Heat', 'Late Summer'),
    (8, 7, 'Start of Autumn', 'Early Autumn'), (8, 23, 'End of Heat', 'Early Autumn'),
    (9, 8, 'White Dew', 'Mid Autumn'), (9, 23, 'Autumn Equinox', 'Mid Autumn'),
    (10, 8, 'Cold Dew', 'Late Autumn'), (10, 23, 'Frost Descent', 'Late Autumn'),
    (11, 7, 'Start of Winter', 'Early Winter'), (11, 22, 'Minor Snow', 'Early Winter'),
    (12, 7, 'Major Snow', 'Mid Winter'), (12, 22, 'Winter Solstice', 'Mid Winter'),
  ];
  String termName = 'Clear & Bright';
  String season = 'Late Spring';
  for (final t in terms) {
    if (month < t.$1 || (month == t.$1 && day < t.$2)) break;
    termName = t.$3;
    season = t.$4;
  }
  return (termName, season);
}

// ═══════════════════════════════════════════════════════════════
// Home Page Widget
// ═══════════════════════════════════════════════════════════════

class UltimateHomePage extends StatefulWidget {
  const UltimateHomePage({super.key});

  @override
  State<UltimateHomePage> createState() => _UltimateHomePageState();
}

class _UltimateHomePageState extends State<UltimateHomePage> {
  static const _baseUrl = 'https://api.seasonsapp.com';
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));

  late DayPartData _dayPart;
  String _solarTermInfo = '';
  String _dailyInsight = '';
  // ignore: unused_field
  List<Map<String, dynamic>> _apiSuggestions = [];
  bool _loading = true;

  Map<String, dynamic> _followUp = {};
  bool _hasFollowUp = false;

  @override
  void initState() {
    super.initState();
    _dayPart = getCurrentDayPart();
    _solarTermInfo = _pill();
    _syncDevice();
    _fetchDashboard();
  }

  /// "Frost Descent · Late Autumn" in the north; the local season and its stage in the south.
  String _pill() {
    final (term, season) = _currentTermAndNorthSeason();
    return homeSeasonPill(termName: term, northSeasonLabel: season, hemisphere: HemisphereResolver.current());
  }

  /// Tell the server what this device detected (once per session; it never replaces a hemisphere the user chose),
  /// then redraw the season line with the hemisphere the server settled on.
  Future<void> _syncDevice() async {
    await CultureBinding.syncDeviceOnce();
    if (mounted) setState(() => _solarTermInfo = _pill());
  }

  Future<void> _fetchDashboard() async {
    // Try offline cache first
    try {
      final cached = await OfflineCache.getCachedDashboard();
      if (cached != null && mounted) {
        _applyData(Map<String, dynamic>.from(cached));
        setState(() => _loading = false);
      }
    } catch (_) {}

    try {
      final results = await Future.wait([
        _dio.get('/api/v1/contents/recommend?locale=en-US'),
        _dio.get('/api/v1/solar-terms/enhanced/current'),
        _dio.get('/api/v1/followup/due', queryParameters: {'user_id': StorageManager.user.getUserId() ?? 'guest', 'limit': 1}),
      ]);

      if (!mounted) return;

      final dash = results[0].data;
      if (dash is Map) {
        await OfflineCache.cacheDashboard(Map<String, dynamic>.from(dash));
        _applyData(Map<String, dynamic>.from(dash));
      }

      final solar = results[1].data;
      if (solar is Map) {
        // Could enhance solar term info from API
      }

      final followupRes = results[2].data;
      if (followupRes is Map && followupRes['due_followups'] is List) {
        final due = (followupRes['due_followups'] as List);
        if (due.isNotEmpty) {
          _followUp = Map<String, dynamic>.from(due.first);
          _hasFollowUp = true;
        }
      }

      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyData(Map dash) {
    final insight = dash['daily_insight'];
    if (insight is Map) {
      _dailyInsight = insight['text']?.toString() ?? _dailyInsight;
    }
    final sugList = dash['gentle_suggestions'] ?? dash['suggestions'];
    if (sugList is List) {
      _apiSuggestions = sugList.cast<Map<String, dynamic>>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _dayPart;
    final timeDisplay = sc.timeDisplay;

    if (_loading) return const HomeSkeleton();

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ═══════════════ TopAppBar ═══════════════
            SliverToBoxAdapter(
              child: _buildTopBar(sc),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ═══════════════ 时辰大标题 + 节气胶囊 ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildHeroTitle(sc, timeDisplay),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            // ═══════════════ Picked for you ═══════════════
            SliverToBoxAdapter(child: PersonalHomeSection(api: PersonalHomeBinding.api())),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ═══════════════ Hero 经络意境区 ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildHeroImage(sc),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ═══════════════ Bento 行动建议 (2列) ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildBentoGrid(sc),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ═══════════════ AI 助手模块 (毛玻璃) ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildAIModule(sc),
              ),
            ),

            // ═══════════════ 今日洞察 (如有) ═══════════════
            if (_dailyInsight.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildDailyInsight(),
                ),
              ),
            ],

            // ═══════════════ 顺时提醒 (如有) ═══════════════
            if (_hasFollowUp) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildFollowUpCard(),
                ),
              ),
            ],

            // ═══════════════ CTA 按钮 ═══════════════
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCTA(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  // ─── TopAppBar ───
  Widget _buildTopBar(DayPartData sc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu + Brand
          Row(children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu, size: 20, color: ShunShiColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'SEASONS',
              style: ShunShiTypography.headlineSmall.copyWith(
                fontFamily: ShunShiTypography.serifFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ]),
          // Right: Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ShunShiColors.borderGhost, width: 1.5),
              ),
              child: const CircleAvatar(
                backgroundColor: ShunShiColors.surfaceContainerLow,
                child: Icon(Icons.person, size: 20, color: ShunShiColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 时辰大标题 + 节气胶囊 ───
  Widget _buildHeroTitle(DayPartData sc, String timeDisplay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time range label
        Text(
          timeDisplay,
          style: ShunShiTypography.labelMedium.copyWith(
            color: ShunShiColors.secondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        // Main title
        RichText(
          text: TextSpan(
            style: ShunShiTypography.displayLarge.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: '${sc.name} · '),
              TextSpan(
                text: sc.focus,
                style: TextStyle(color: ShunShiColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Solar term pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: ShunShiColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _solarTermInfo,
            style: ShunShiTypography.caption.copyWith(
              color: ShunShiColors.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Hero 经络意境区 ───
  Widget _buildHeroImage(DayPartData sc) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ShunShiColors.primary.withValues(alpha: 0.12),
            ShunShiColors.surfaceContainerLow,
            ShunShiColors.goldLight.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative ink circles
          ...List.generate(5, (i) {
            final rng = Random(i * 37 + sc.name.hashCode);
            return Positioned(
              left: rng.nextDouble() * 280,
              top: rng.nextDouble() * 200,
              child: Container(
                width: 40 + rng.nextDouble() * 60,
                height: 40 + rng.nextDouble() * 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ShunShiColors.primary.withValues(alpha: 0.04 + rng.nextDouble() * 0.06),
                ),
              ),
            );
          }),
          // Center meridian icon
          Center(
            child: Icon(
              sc.icon,
              size: 64,
              color: ShunShiColors.primary.withValues(alpha: 0.15),
            ),
          ),
          // Bottom gradient overlay
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ShunShiColors.background.withValues(alpha: 0),
                    ShunShiColors.background.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          // Wellness principle card
          Positioned(
            left: 16, right: 16, bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ShunShiColors.background.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wellness Principle',
                    style: ShunShiTypography.caption.copyWith(
                      color: ShunShiColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sc.wellnessPrinciple,
                    style: ShunShiTypography.serifTitle.copyWith(
                      fontSize: 18,
                      color: ShunShiColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bento Action Suggestions (vertical list) ───
  Widget _buildBentoGrid(DayPartData sc) {
    return Column(
      children: sc.actions.map((action) => _buildBentoCard(action)).toList()
        ..insert(1, const SizedBox(height: 16)),
    );
  }

  Widget _buildBentoCard(BentoAction action) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShunShiShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: ShunShiColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, size: 24, color: ShunShiColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: ShunShiTypography.titleLarge.copyWith(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.description,
                  style: ShunShiTypography.bodySmall.copyWith(
                    height: 1.6,
                    color: ShunShiColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI Assistant Module ───
  Widget _buildAIModule(DayPartData sc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ShunShiColors.borderGhost),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          SizedBox(
            width: 52, height: 52,
            child: Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(
                    color: ShunShiColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                // Pulse indicator
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: ShunShiColors.goldLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: ShunShiColors.background, width: 2.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: ShunShiColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // AI text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEASONS AI Assistant',
                  style: ShunShiTypography.titleMedium.copyWith(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${sc.aiQuote}"',
                  style: ShunShiTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: ShunShiColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 今日洞察 ───
  Widget _buildDailyInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ShunShiColors.primary,
            ShunShiColors.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Insight",
            style: ShunShiTypography.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dailyInsight,
            style: ShunShiTypography.bodyMedium.copyWith(
              color: Colors.white,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 顺时提醒 ───
  Widget _buildFollowUpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: ShunShiColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active, color: ShunShiColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEASONS Reminder', style: ShunShiTypography.labelMedium.copyWith(
                  color: ShunShiColors.primary, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(
                  _followUp['title']?.toString() ?? _followUp['description']?.toString() ?? '',
                  style: ShunShiTypography.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
        ],
      ),
    );
  }

  // ─── CTA 按钮 ───
  Widget _buildCTA() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/solar-wellness'),
        icon: const Icon(Icons.arrow_forward, size: 20),
        label: const Text('View Full ShiChen Wellness Chart'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunShiColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

}
