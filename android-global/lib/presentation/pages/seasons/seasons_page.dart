// lib/presentation/pages/seasons/seasons_page.dart
//
// Seasons 页面 — 更极简、顶部视觉占比50%
// 国际版：Season名称32sp w200，内容更少，间距更大
// 背景渐变更柔和，SingleChildScrollView滚动

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../providers/seasons_provider.dart';

// ── 季节配色 — 更柔和的渐变 ──────────────────────────

Color _seasonBgStart(String season) {
  switch (season) {
    case 'spring':
      return const Color(0xFFC8DCC5); // sage
    case 'summer':
      return const Color(0xFFE8D4B8); // warm amber
    case 'autumn':
      return const Color(0xFFDDD4C6); // earth
    case 'winter':
      return const Color(0xFFC0D4E0); // calm blue
    default:
      return SeasonsColors.primaryLight;
  }
}

Color _seasonBgEnd(String season) {
  switch (season) {
    case 'spring':
      return const Color(0xFFF2F5F0);
    case 'summer':
      return const Color(0xFFFAF5EF);
    case 'autumn':
      return const Color(0xFFF8F4EE);
    case 'winter':
      return const Color(0xFFF0F5FA);
    default:
      return SeasonsColors.background;
  }
}

String _seasonEmoji(String season) {
  switch (season) {
    case 'spring':
      return '🌱';
    case 'summer':
      return '☀️';
    case 'autumn':
      return '🍂';
    case 'winter':
      return '❄️';
    default:
      return '🌿';
  }
}

String _seasonDisplayName(String season) {
  return season[0].toUpperCase() + season.substring(1);
}

// ── 当前季节辅助 ──────────────────────────────────────

String _getCurrentSeason() {
  final month = DateTime.now().month;
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  if (month >= 9 && month <= 11) return 'autumn';
  return 'winter';
}

// ── 主页面 ────────────────────────────────────────────

class SeasonsPage extends ConsumerWidget {
  const SeasonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsState = ref.watch(seasonsProvider);
    final currentSeason = _getCurrentSeason();
    final currentInsight =
        seasonsState.seasonInsights.entries
            .where((e) => e.key.name == currentSeason)
            .firstOrNull;

    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 顶部大视觉区域 (50%) ──
            _HeroSection(season: currentSeason),

            // ── 季节感悟 ──
            if (currentInsight != null)
              _InsightSection(
                insight: currentInsight.value,
                season: currentSeason,
              ),

            // ── 生活建议 ──
            if (currentInsight != null)
              _GentleSuggestions(
                insight: currentInsight.value,
                season: currentSeason,
              ),

            // ── 其他季节快速导航 ──
            _OtherSeasons(current: currentSeason),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── 顶部大视觉区域 — 50%，更柔和渐变 ──

class _HeroSection extends StatelessWidget {
  final String season;

  const _HeroSection({required this.season});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.50;

    return Container(
      height: heroHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _seasonBgStart(season),
            _seasonBgEnd(season),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(SeasonsSpacing.radiusXL),
          bottomRight: Radius.circular(SeasonsSpacing.radiusXL),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(
              _seasonEmoji(season),
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 20),
            // Season name — 32sp w200
            Text(
              _seasonDisplayName(season),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w200,
                color: SeasonsColors.textPrimary,
                height: 1.3,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Subtle tagline
            Text(
              _getSeasonTagline(season),
              style: SeasonsTextStyles.bodySecondary.copyWith(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getSeasonTagline(String season) {
    switch (season) {
      case 'spring':
        return 'A time for renewal';
      case 'summer':
        return 'Embrace the warmth';
      case 'autumn':
        return 'Transition & reflection';
      case 'winter':
        return 'Rest & nourish';
      default:
        return 'Live in rhythm';
    }
  }
}

// ── 季节感悟 ──

class _InsightSection extends StatelessWidget {
  final dynamic insight;
  final String season;

  const _InsightSection({required this.insight, required this.season});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            insight.insight as String,
            style: SeasonsTextStyles.body.copyWith(
              fontSize: 18,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 生活建议（极简版，只取前3条）───────────────────────

class _GentleSuggestions extends StatelessWidget {
  final dynamic insight;
  final String season;

  const _GentleSuggestions({
    required this.insight,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    final foods = (insight.foodSuggestions as List?)?.take(3).toList() ?? [];
    final stretches =
        (insight.stretchRoutines as List?)?.take(2).toList() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Food
          if (foods.isNotEmpty) ...[
            Text(
              'Nourish',
              style: SeasonsTextStyles.heading,
            ),
            const SizedBox(height: 18),
            ...foods.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GentleCard(
                    emoji: '🍽️',
                    text: f as String,
                  ),
                )),
          ],

          // Movement
          if (stretches.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Move',
              style: SeasonsTextStyles.heading,
            ),
            const SizedBox(height: 18),
            ...stretches.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GentleCard(
                    emoji: '🧘',
                    text: s as String,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── 极简建议卡片 ──

class _GentleCard extends StatelessWidget {
  final String emoji;
  final String text;

  const _GentleCard({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: SeasonsColors.surface,
        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
        border: Border.all(
          color: SeasonsColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: SeasonsTextStyles.body.copyWith(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 其他季节导航 ──

class _OtherSeasons extends StatelessWidget {
  final String current;

  const _OtherSeasons({required this.current});

  @override
  Widget build(BuildContext context) {
    final others = ['spring', 'summer', 'autumn', 'winter']
        .where((s) => s != current)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Other Seasons',
            style: SeasonsTextStyles.heading.copyWith(
              color: SeasonsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ...others.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: SeasonsColors.surface,
                    borderRadius: BorderRadius.circular(
                      SeasonsSpacing.radiusMedium,
                    ),
                    border: Border.all(
                      color: SeasonsColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _seasonEmoji(s),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _seasonDisplayName(s),
                        style: SeasonsTextStyles.body.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
