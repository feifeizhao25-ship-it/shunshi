/// 节气AI详情页 — 对齐UI参考 _10
/// 固定顶栏(返回+ShunShi AI+分享) → Hero水墨画 → 节气内涵卡片 → Bento Grid(饮食/起居/功法) → 冥想音频卡 → 浮动分享
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class SolarTermAIDetailPage extends StatelessWidget {
  final String termName;
  final String? season;
  final String? englishName;

  const SolarTermAIDetailPage({
    super.key,
    required this.termName,
    this.season,
    this.englishName,
  });

  // 节气数据映射
  static const _termData = {
    '春分': _TermData(
      englishName: 'Spring Equinox',
      season: '春季 · 第四节气',
      quote: '昼夜均而寒暑平。',
      description: '春分，是春季九十日之半。此日太阳直射赤道，阴阳相半，万物生长进入最为繁茂的阶段。于身心而言，正是调和阴阳、顺应生发的黄金时刻。',
      foodTitle: '食春鲜 · 助生发',
      foodDesc: '推荐食用香椿、豆芽、春笋等时令蔬菜，以辛甘发散之品，助益脾气。',
      foodTags: ['香椿炒蛋', '凉拌豆芽'],
      livingTitle: '夜卧早起',
      livingDesc: '早起以顺应阳气生发，披发缓行，广步于庭。',
      exerciseTitle: '八段锦 · 第三式',
      exerciseDesc: '调理脾胃须单举。调理脾胃气机，促进中焦运化。',
      meditationTitle: '春分 · 阴阳平衡引导',
      meditationDesc: '随着柔和的春雨声，引导意识在身体内达成动态平衡，如同春分的昼夜一般和谐。',
      meditationDuration: '12:00 MIN',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
    ),
    '惊蛰': _TermData(
      englishName: 'Awakening of Insects',
      season: '春季 · 第三节气',
      quote: '春雷响，万物长。',
      description: '惊蛰时节，阳气上升，万物萌动。人体肝气亦随之旺盛，宜疏肝理气、养护脾胃。',
      foodTitle: '养肝护脾',
      foodDesc: '宜食菠菜、春笋、山药，少酸多甘，以养脾气。',
      foodTags: ['菠菜猪肝汤', '山药粥'],
      livingTitle: '早睡早起',
      livingDesc: '顺应阳气升发，广步于庭，舒展筋骨。',
      exerciseTitle: '八段锦 · 第一式',
      exerciseDesc: '两手托天理三焦。疏通三焦气机，调和内脏。',
      meditationTitle: '惊蛰 · 肝木舒展',
      meditationDesc: '倾听春雷渐起，感受体内阳气如草木般萌动。',
      meditationDuration: '10:00 MIN',
      gradient: [Color(0xFF2D5A3D), Color(0xFF3B684A)],
    ),
  };

  _TermData get _data =>
      _termData[termName] ??
      _TermData(
        englishName: englishName ?? termName,
        season: season ?? '二十四节气',
        quote: '顺天时，养正气。',
        description: '$termName时节，阴阳交替，万物更新。顺应自然节律，调和身心。',
        foodTitle: '时令饮食',
        foodDesc: '选用当季食材，调和五脏。',
        foodTags: ['推荐食谱'],
        livingTitle: '起居有常',
        livingDesc: '顺应日出日落，调整作息。',
        exerciseTitle: '传统功法',
        exerciseDesc: '适度运动，疏通经络。',
        meditationTitle: '$termName · 静心引导',
        meditationDesc: '聆听自然之声，感受节气韵律。',
        meditationDuration: '10:00 MIN',
        gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final surfaceLow = isDark ? ShunShiColors.darkSurfaceContainerLow : ShunShiColors.surfaceContainerLow;
    final d = _data;
    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── Hero Section ──
                _buildHeroSection(context, d),
                // ── 节气内涵 ──
                _buildInsightSection(d),
                // ── 顺时生活方案 Bento Grid ──
                _buildBentoSection(d),
                // ── 冥想音频卡 ──
                _buildMeditationCard(d),
                const SizedBox(height: 120),
              ],
            ),
          ),

          // ── 固定顶栏 ──
          _buildTopBar(context),

          // ── 浮动分享按钮 ──
          Positioned(
            bottom: 36,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: ShunShiColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.share, size: 20, color: Colors.white),
                      SizedBox(width: 10),
                      Text('分享这份顺时灵感', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark ? ShunShiColors.darkBackground : ShunShiColors.background;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.8),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, size: 20, color: ShunShiColors.primary),
                  ),
                ),
                const Text('ShunShi AI', style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.italic,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: ShunShiColors.primary,
                )),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share, size: 20, color: ShunShiColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, _TermData d) {
    final bg = Theme.of(context).brightness == Brightness.dark ? ShunShiColors.darkBackground : ShunShiColors.background;
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          // Gradient background (代替水墨画)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: d.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                termName,
                style: TextStyle(
                  fontSize: 120,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: Colors.white.withValues(alpha: 0.08),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bg.withValues(alpha: 0.3),
                  bg,
                ],
                stops: const [0.5, 0.75, 1.0],
              ),
            ),
          ),
          // Text overlay
          Positioned(
            bottom: 40,
            left: 24, right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(d.season, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 3,
                    color: Colors.white,
                  )),
                ),
                const SizedBox(height: 16),
                Text(termName, style: TextStyle(
                  fontSize: 52, fontWeight: FontWeight.w400,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: ShunShiColors.textPrimary,
                )),
                const SizedBox(height: 6),
                Text(d.englishName, style: TextStyle(
                  fontSize: 18, fontStyle: FontStyle.italic,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: ShunShiColors.secondary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(_TermData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, -24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.1)),
          boxShadow: ShunShiShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 28, height: 1, color: ShunShiColors.apricot),
                const SizedBox(width: 12),
                Text('节气内涵', style: TextStyle(
                  fontSize: 13, letterSpacing: 3,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: ShunShiColors.secondary,
                )),
              ],
            ),
            const SizedBox(height: 20),
            Text(d.quote, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w400, height: 1.4,
              fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            )),
            const SizedBox(height: 16),
            Text(d.description, style: TextStyle(
              fontSize: 15, height: 1.8,
              color: ShunShiColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoSection(_TermData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 28, height: 1, color: ShunShiColors.apricot),
              const SizedBox(width: 12),
              Text('顺时生活方案', style: TextStyle(
                fontSize: 13, letterSpacing: 3,
                fontFamily: ShunShiTypography.serifFamily,
                color: ShunShiColors.secondary,
              )),
            ],
          ),
          const SizedBox(height: 24),
          // Bento grid
          Column(
            children: [
              // Full-width food card
              _foodCard(d),
              const SizedBox(height: 12),
              // Two-column row
              Row(
                children: [
                  Expanded(child: _livingCard(d)),
                  const SizedBox(width: 12),
                  Expanded(child: _exerciseCard(d)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _foodCard(_TermData d) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, size: 20, color: ShunShiColors.primary),
              const SizedBox(width: 8),
              Text('饮食之道', style: TextStyle(
                fontSize: 11, letterSpacing: 2,
                color: ShunShiColors.primary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Text(d.foodTitle, style: TextStyle(
            fontSize: 20, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.textPrimary,
          )),
          const SizedBox(height: 12),
          Text(d.foodDesc, style: TextStyle(
            fontSize: 13, height: 1.6, color: ShunShiColors.textSecondary,
          )),
          const SizedBox(height: 16),
          Row(
            children: d.foodTags.map((tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.2)),
                ),
                child: Text(tag, style: TextStyle(
                  fontSize: 11, color: ShunShiColors.secondary,
                )),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _livingCard(_TermData d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShunShiColors.apricotLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime, size: 20, color: ShunShiColors.secondary),
              const SizedBox(width: 8),
              Text('起居之律', style: TextStyle(
                fontSize: 11, letterSpacing: 2, color: ShunShiColors.secondary,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Text(d.livingTitle, style: TextStyle(
            fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.textPrimary,
          )),
          const SizedBox(height: 8),
          Text(d.livingDesc, style: TextStyle(
            fontSize: 12, height: 1.6, color: ShunShiColors.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _exerciseCard(_TermData d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShunShiColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.self_improvement, size: 20, color: ShunShiColors.primary),
              const SizedBox(width: 8),
              Text('功法练习', style: TextStyle(
                fontSize: 11, letterSpacing: 2,
                color: ShunShiColors.primary.withValues(alpha: 0.7),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Text(d.exerciseTitle, style: TextStyle(
            fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.textPrimary,
          )),
          const SizedBox(height: 8),
          Text(d.exerciseDesc, style: TextStyle(
            fontSize: 12, height: 1.6,
            color: ShunShiColors.primary.withValues(alpha: 0.8),
          )),
        ],
      ),
    );
  }

  Widget _buildMeditationCard(_TermData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLow.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          boxShadow: ShunShiShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.graphic_eq, size: 20, color: ShunShiColors.primary),
                    const SizedBox(width: 8),
                    Text('静心冥想', style: TextStyle(
                      fontSize: 11, letterSpacing: 2, color: ShunShiColors.primary,
                    )),
                  ],
                ),
                Text(d.meditationDuration, style: TextStyle(
                  fontSize: 10,
                  color: ShunShiColors.textSecondary.withValues(alpha: 0.6),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Text(d.meditationTitle, style: TextStyle(
              fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            )),
            const SizedBox(height: 12),
            Text(d.meditationDesc, style: TextStyle(
              fontSize: 13, height: 1.7, color: ShunShiColors.textSecondary,
            )),
            const SizedBox(height: 24),
            // Audio player row
            Row(
              children: [
                // Play button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: ShunShiColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ShunShiColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                // Progress bar
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: ShunShiColors.textTertiary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.33,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ShunShiColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: constraints.maxWidth * 0.33 - 4,
                              top: -2,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: ShunShiColors.primary, shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TermData {
  final String englishName;
  final String season;
  final String quote;
  final String description;
  final String foodTitle;
  final String foodDesc;
  final List<String> foodTags;
  final String livingTitle;
  final String livingDesc;
  final String exerciseTitle;
  final String exerciseDesc;
  final String meditationTitle;
  final String meditationDesc;
  final String meditationDuration;
  final List<Color> gradient;

  const _TermData({
    required this.englishName,
    required this.season,
    required this.quote,
    required this.description,
    required this.foodTitle,
    required this.foodDesc,
    required this.foodTags,
    required this.livingTitle,
    required this.livingDesc,
    required this.exerciseTitle,
    required this.exerciseDesc,
    required this.meditationTitle,
    required this.meditationDesc,
    required this.meditationDuration,
    required this.gradient,
  });
}
