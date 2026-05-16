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
import '../../../data/services/offline_cache.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
import '../../../data/en_content.dart';

// ═══════════════════════════════════════════════════════════════
// Twelve ShiChen Data Model (local computation)
// ═══════════════════════════════════════════════════════════════

class ShiChenData {
  final String name;
  final String timeRange;
  final String meridian;
  final String principle;       // e.g. "Stillness · Nourish Gallbladder Qi"
  final String principleShort;  // e.g. "Nourish Gallbladder Qi" (for titles)
  final String wellnessPrinciple; // Wellness essence e.g. "Nourish Yin, Tonify Kidney"
    final String aiQuote;         // AI quote
  final IconData icon;           // Material icon
  final List<BentoAction> actions;

  const ShiChenData({
    required this.name,
    required this.timeRange,
    required this.meridian,
    required this.principle,
    required this.principleShort,
    required this.wellnessPrinciple,
    required this.aiQuote,
    required this.icon,
    required this.actions,
  });
}

class BentoAction {
  final IconData icon;
  final String title;
  final String description;
  const BentoAction({required this.icon, required this.title, required this.description});
}

ShiChenData getCurrentShiChen() {
  final hour = DateTime.now().hour;
  for (final sc in _shiChenList) {
    final parts = sc.timeRange.split('-');
    final start = int.parse(parts[0]);
    final end = int.parse(parts[1]);
    if (start <= end) {
      if (hour >= start && hour < end) return sc;
    } else {
      if (hour >= start || hour < end) return sc;
    }
  }
  return _shiChenList[0];
}

final _shiChenList = <ShiChenData>[
  ShiChenData(
    name: 'Zi', timeRange: '23-1', meridian: 'Gallbladder',
    principle: 'Stillness', principleShort: 'Nourish Gallbladder Qi',
    wellnessPrinciple: 'Calm the mind, warm and nourish Gallbladder Qi',
    aiQuote: 'The Zi hour marks the birth of Yang Qi, when all is still. Sleep deeply now to let the Gallbladder meridian restore, laying the foundation for tomorrow\'s vitality.',
    icon: Icons.dark_mode,
    actions: [
      BentoAction(icon: Icons.nightlight_round, title: 'ultimate_home_deep_sleep', description: 'Deep sleep during Zi hour supports bile metabolism and nighttime repair.'),
      BentoAction(icon: Icons.air, title: 'ultimate_home_rest_quietly', description: 'Stay still and calm, avoid disturbing the newborn Yang Qi. Lie on your right side.'),
    ],
  ),
  ShiChenData(
    name: 'Chou', timeRange: '1-3', meridian: 'Liver',
    principle: 'Liver Blood Storage', principleShort: 'Nourish Liver Yin',
    wellnessPrinciple: 'Nourish blood, soothe the Liver, moisten Yin',
    aiQuote: 'The Chou hour activates the Liver meridian, a critical time for detox and blood storage. Deep sleep helps the liver complete metabolic repair for a healthy complexion.',
    icon: Icons.night_shelter,
    actions: [
      BentoAction(icon: Icons.bedtime, title: 'ultimate_home_deep_sleep_1', description: 'Liver meridian peaks at Chou hour. Deep sleep nourishes Liver blood.'),
      BentoAction(icon: Icons.local_florist, title: 'ultimate_home_protect_liver', description: 'Avoid staying up late to let the liver fully rest and detoxify.'),
    ],
  ),
  ShiChenData(
    name: 'Yin', timeRange: '3-5', meridian: 'Lung',
    principle: 'Qi Distribution', principleShort: 'Nourish Lung Qi',
    wellnessPrinciple: 'Moisten Lungs, boost Qi, harmonize defenses',
    aiQuote: 'The Yin hour is when the Lung meridian distributes Qi and blood throughout the body. Stay asleep to let the Lungs complete their distribution to all meridians.',
    icon: Icons.cloud,
    actions: [
      BentoAction(icon: Icons.air, title: 'ultimate_home_deep_breathing', description: 'Lung meridian peaks at Yin hour. Maintain slow, deep breaths.'),
      BentoAction(icon: Icons.spa, title: 'ultimate_home_peaceful_sleep', description: 'Let the Lungs complete Qi distribution. Avoid waking abruptly.'),
    ],
  ),
  ShiChenData(
    name: 'Mao', timeRange: '5-7', meridian: 'Large Intestine',
    principle: 'Dawn Elimination', principleShort: 'Clear Intestines',
    wellnessPrinciple: 'Moisten intestines, clear stagnation',
    aiQuote: 'The Mao hour activates the Large Intestine meridian — the best time for elimination. Drink a cup of warm water and move gently to help your body detox and refresh.',
    icon: Icons.light_mode,
    actions: [
      BentoAction(icon: Icons.water_drop, title: 'ultimate_home_warm_water', description: 'A cup of warm water wakes the digestive system and promotes elimination.'),
      BentoAction(icon: Icons.directions_walk, title: 'ultimate_home_morning_activity', description: 'Light movement promotes intestinal motility and clears the bowels.'),
    ],
  ),
  ShiChenData(
    name: 'Chen', timeRange: '7-9', meridian: 'Stomach',
    principle: 'Morning Nourishment', principleShort: 'Boost Qi & Blood',
    wellnessPrinciple: 'Warm the Stomach, strengthen Spleen, boost Qi',
    aiQuote: 'The Chen hour peaks the Stomach meridian — golden time for breakfast. A warm, nutritious breakfast provides ample energy for the whole day and nourishes Qi and blood.',
    icon: Icons.breakfast_dining,
    actions: [
      BentoAction(icon: Icons.rice_bowl, title: 'ultimate_home_warm_breakfast', description: 'Eat warm, easily digestible food to nourish Stomach Qi.'),
      BentoAction(icon: Icons.local_cafe, title: 'ultimate_home_ginger_jujube_tea', description: 'Ginger and jujube tea warms the stomach, dispels cold, and harmonizes Spleen and Stomach.'),
    ],
  ),
  ShiChenData(
    name: 'Si', timeRange: '9-11', meridian: 'Spleen',
    principle: 'Transform & Transport', principleShort: 'Strengthen Spleen',
    wellnessPrinciple: 'Strengthen Spleen, boost Qi, resolve dampness',
    aiQuote: 'The Si hour activates the Spleen meridian — optimal time for digestion and absorption. Energy is abundant, ideal for productive work. The Spleen is the foundation of postnatal health.',
    icon: Icons.psychology,
    actions: [
      BentoAction(icon: Icons.work, title: 'ultimate_home_productive_work', description: 'Energy peaks at Si hour. Ideal for handling important tasks.'),
      BentoAction(icon: Icons.emoji_food_beverage, title: 'ultimate_home_spleen_tea', description: 'Aged tangerine peel and Pu-erh tea strengthens the Spleen and aids digestion.'),
    ],
  ),
  ShiChenData(
    name: 'Wu', timeRange: '11-13', meridian: 'Heart',
    principle: 'Midday Heart Care', principleShort: 'Balance Yin & Yang',
    wellnessPrinciple: 'Nourish Heart, calm Spirit, harmonize Heart & Kidney',
    aiQuote: 'The Wu hour peaks the Heart meridian, the transition between Yin and Yang. A short nap after lunch nourishes the Heart and calms the spirit for greater afternoon vitality.',
    icon: Icons.wb_sunny,
    actions: [
      BentoAction(icon: Icons.hotel, title: 'ultimate_home_midday_nap', description: 'A 15-30 minute nap at Wu hour nourishes the Heart and calms the spirit.'),
      BentoAction(icon: Icons.favorite, title: 'ultimate_home_quiet_meditation', description: 'Close your eyes and meditate to calm the Heart and settle Heart Fire.'),
    ],
  ),
  ShiChenData(
    name: 'Wei', timeRange: '13-15', meridian: 'Small Intestine',
    principle: 'Separate & Absorb', principleShort: 'Aid Digestion',
    wellnessPrinciple: 'Clear the heart, guide out turbidity, harmonize intestines',
    aiQuote: 'The Wei hour activates the Small Intestine meridian, responsible for absorbing nutrients and separating waste. Moderate activity and hydration support digestion.',
    icon: Icons.filter_alt,
    actions: [
      BentoAction(icon: Icons.directions_walk, title: 'ultimate_home_afternoon_walk', description: 'Light activity aids digestion and absorption after lunch.'),
      BentoAction(icon: Icons.water_drop, title: 'ultimate_home_stay_hydrated', description: 'Drink plenty of water during Wei hour to support metabolism and detox.'),
    ],
  ),
  ShiChenData(
    name: 'Shen', timeRange: '15-17', meridian: 'Bladder',
    principle: 'Detox & Drain', principleShort: 'Clear Heat',
    wellnessPrinciple: 'Open water passages, clear heat and toxins',
    aiQuote: 'The Shen hour peaks the Bladder meridian — the best time for detox. Drink water and exercise moderately to sweat out metabolic waste for a refreshed body and mind.',
    icon: Icons.wb_cloudy,
    actions: [
      BentoAction(icon: Icons.directions_run, title: 'ultimate_home_moderate_exercise', description: 'Physical stamina is good at Shen hour. Ideal for exercise to sweat out toxins.'),
      BentoAction(icon: Icons.water_drop, title: 'ultimate_home_drink_warm_water', description: 'Supports Bladder meridian detox, promotes urination and reduces swelling.'),
    ],
  ),
  ShiChenData(
    name: 'You', timeRange: '17-19', meridian: 'Kidney',
    principle: 'Store Essence', principleShort: 'Nourish Kidney Yuan',
    wellnessPrinciple: 'Nourish Yin, tonify Kidney, clear heat and fire',
    aiQuote: 'The You hour activates the Kidney meridian, the time to store essence. Best to gather your spirit and let the body complete a deep self-repair in stillness.',
    icon: Icons.auto_awesome,
    actions: [
      BentoAction(icon: Icons.water_drop, title: 'ultimate_home_hydrate', description: 'Kidney detox peaks at You hour. Drink warm water to support metabolism.'),
      BentoAction(icon: Icons.accessibility_new, title: 'ultimate_home_tap_heels', description: 'The Kidney meridian starts at the soles. Tap your heels gently to stimulate Kidney Qi.'),
    ],
  ),
  ShiChenData(
    name: 'Xu', timeRange: '19-21', meridian: 'Pericardium',
    principle: 'Heart Protection', principleShort: 'Ease Emotions',
    wellnessPrinciple: 'Open the chest, regulate Qi, relieve stagnation',
    aiQuote: 'The Xu hour activates the Pericardium meridian, the time to protect the Heart and relieve stress. Enjoy leisure, connect with family, and let your heart be light and open.',
    icon: Icons.music_note,
    actions: [
      BentoAction(icon: Icons.music_note, title: 'ultimate_home_listen_to_music', description: 'Relax your mood during Xu hour and ease the day\'s stress.'),
      BentoAction(icon: Icons.local_cafe, title: 'ultimate_home_floral_tea', description: 'Rose tea soothes the Liver, regulates Qi, and calms the spirit.'),
    ],
  ),
  ShiChenData(
    name: 'Hai', timeRange: '21-23', meridian: 'Triple Burner',
    principle: 'All Meridians Harmonize', principleShort: 'Prepare for Sleep',
    wellnessPrinciple: 'Regulate Triple Burner, calm spirit, aid sleep',
    aiQuote: 'The Hai hour activates the Triple Burner meridian, when all meridians harmonize. Soak your feet in warm water, read quietly, let go of the day\'s rush, and prepare for restful sleep.',
    icon: Icons.nights_stay,
    actions: [
      BentoAction(icon: Icons.spa, title: 'ultimate_home_foot_soak', description: 'Soaking feet at Hai hour draws fire back to its source and warms the meridians for better sleep.'),
      BentoAction(icon: Icons.menu_book, title: 'ultimate_home_quiet_reading', description: 'Put down your phone, read quietly, and prepare for sleep to nourish all meridians.'),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════
// Solar Term Mapping (approximate by month)
// ═══════════════════════════════════════════════════════════════

String _getCurrentSolarTermInfo() {
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
  return '$termName \u00b7 $season';
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
  final _dio = apiClient.dio;

  late ShiChenData _currentShiChen;
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
    _currentShiChen = getCurrentShiChen();
    _solarTermInfo = _getCurrentSolarTermInfo();
    _fetchDashboard();
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
        _dio.get('/api/v1/solar-terms/enhanced/current?locale=en-US'),
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
        // Update solar term info from API if available, ensuring English
        final solarData = solar['data'] is Map ? solar['data'] as Map : (solar.containsKey('current') ? solar : null);
        if (solarData != null && solarData['current'] is Map) {
          final current = Map<String, dynamic>.from(solarData['current']);
          final enName = ZhEnMapper.solarTermFromApi(current);
          if (enName.isNotEmpty) {
            // Could enhance solar term info if needed
          }
        }
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
    final sc = _currentShiChen;
    final timeDisplay = '${sc.timeRange.replaceAll('-', ':00 - ')}:00';

    if (_loading) return const HomeSkeleton();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
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
  Widget _buildTopBar(ShiChenData sc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu + Brand
          Row(children: [
            GestureDetector(
              onTap: () => context.push('/profile'),
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
              AppLocalizations.of(context).get('app_title'),
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
  Widget _buildHeroTitle(ShiChenData sc, String timeDisplay) {
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
                text: '${sc.meridian} ${AppLocalizations.of(context).get('home_meridian_active')}',
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
  Widget _buildHeroImage(ShiChenData sc) {
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
                    color: ShunShiColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).get('home_wellness_principle'),
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
  Widget _buildBentoGrid(ShiChenData sc) {
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
  Widget _buildAIModule(ShiChenData sc) {
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
                  child: Icon(
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
                  AppLocalizations.of(context).get('home_ai_assistant'),
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
            AppLocalizations.of(context).get('home_daily_insight'),
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
                Text(AppLocalizations.of(context).get('home_reminder'), style: ShunShiTypography.labelMedium.copyWith(
                  color: ShunShiColors.primary, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(
                  ZhEnMapper.isChinese(_followUp['title']?.toString()) ? 'You have a wellness reminder' : _followUp['title']?.toString() ?? _followUp['description']?.toString() ?? '',
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
        label: Text(AppLocalizations.of(context).get('home_view_wellness_chart')),
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
