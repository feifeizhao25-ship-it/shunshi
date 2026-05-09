/// 节气AI详情页 — 对齐UI参考 _10
/// 固定顶栏(返回+ShunShi AI+分享) → Hero水墨画 → 节气内涵卡片 → Bento Grid(饮食/起居/功法) → 冥想音频卡 → 浮动分享
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

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
    'Spring Equinox': _TermData(
      englishName: 'Spring Equinox',
      season: 'Spring · 4th Solar Term',
      quote: 'Day and night are equal, cold and heat are balanced.',
      description: 'Spring Equinox marks the midpoint of spring. The sun shines directly on the equator, Yin and Yang are equally balanced. It is the golden time to harmonize Yin and Yang and follow nature\'s generative energy.',
      foodTitle: 'Eat Spring Greens · Aid Growth',
      foodDesc: 'Enjoy seasonal vegetables like Chinese toon, bean sprouts, and spring bamboo shoots. Pungent-sweet foods help Spleen Qi.',
      foodTags: ['Toon Egg Scramble', 'Bean Sprout Salad'],
      livingTitle: 'Sleep Later, Rise Early',
      livingDesc: 'Rise early to follow Yang Qi\'s ascent. Walk slowly and freely in the courtyard.',
      exerciseTitle: 'Baduanjin · Form 3',
      exerciseDesc: 'Separate Heaven and Earth. Regulates Spleen and Stomach Qi, promotes middle Jiao function.',
      meditationTitle: 'Spring Equinox · Yin-Yang Balance',
      meditationDesc: 'With gentle spring rain sounds, guide awareness to dynamic balance within, as harmonious as day and night at equinox.',
      meditationDuration: '12:00 MIN',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
    ),
    'Awakening of Insects': _TermData(
      englishName: 'Awakening of Insects',
      season: 'Spring · 3rd Solar Term',
      quote: 'Spring thunder sounds, all things grow.',
      description: 'During Awakening of Insects, Yang Qi rises and all things stir. Liver Qi also becomes vigorous — soothe Liver, regulate Qi, and care for Spleen and Stomach.',
      foodTitle: 'Nourish Liver, Protect Spleen',
      foodDesc: 'Eat spinach, spring bamboo shoots, and yam. Less sour, more sweet to nourish Spleen Qi.',
      foodTags: ['Spinach Liver Soup', 'Yam Porridge'],
      livingTitle: 'Early to Bed, Early to Rise',
      livingDesc: 'Follow the rising Yang Qi, walk in the courtyard, stretch your body.',
      exerciseTitle: 'Baduanjin · Form 1',
      exerciseDesc: 'Two Hands Hold Up the Heavens. Opens Triple Burner Qi, harmonizes internal organs.',
      meditationTitle: 'Awakening · Liver Wood Stretching',
      meditationDesc: 'Listen to spring thunder rising, feel Yang Qi within stirring like sprouting plants.',
      meditationDuration: '10:00 MIN',
      gradient: [Color(0xFF2D5A3D), Color(0xFF3B684A)],
    ),
  };

  _TermData get _data =>
      _termData[termName] ??
      _TermData(
        englishName: englishName ?? termName,
        season: season ?? '24 Solar Terms',
        quote: 'Follow natural timing, nourish upright Qi.',
        description: 'During $termName, Yin and Yang alternate, all things renew. Follow natural rhythms, harmonize body and mind.',
        foodTitle: 'Seasonal Diet',
        foodDesc: 'Choose seasonal ingredients to harmonize the five organs.',
        foodTags: ['Recommended Recipes'],
        livingTitle: 'Regular Routine',
        livingDesc: 'Follow sunrise and sunset to adjust your schedule.',
        exerciseTitle: 'Traditional Practice',
        exerciseDesc: 'Moderate exercise to unblock meridians.',
        meditationTitle: '$termName · Calm Mind Guidance',
        meditationDesc: 'Listen to nature\'s sounds, feel the rhythm of the solar term.',
        meditationDuration: '10:00 MIN',
        gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      );

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
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
                _buildInsightSection(context, d),
                // ── 顺时生活方案 Bento Grid ──
                _buildBentoSection(context, d),
                // ── 冥想音频卡 ──
                _buildMeditationCard(context, d),
                SizedBox(height: 120),
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
                    children: [
                      Icon(Icons.share, size: 20, color: Colors.white),
                      SizedBox(width: 10),
                      Text(AppLocalizations.of(context).t('solar_share_this_seasons_inspiration'), style: TextStyle(
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
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: ShunShiColors.background.withValues(alpha: 0.8),
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
                    child: Icon(Icons.arrow_back, size: 20, color: ShunShiColors.primary),
                  ),
                ),
                Text(AppLocalizations.of(context).t('profile_brand'), style: TextStyle(
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
                    child: Icon(Icons.share, size: 20, color: ShunShiColors.primary),
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
                  ShunShiColors.background.withValues(alpha: 0.3),
                  ShunShiColors.background,
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
                SizedBox(height: 16),
                Text(termName, style: TextStyle(
                  fontSize: 52, fontWeight: FontWeight.w400,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: ShunShiColors.textPrimary,
                )),
                SizedBox(height: 6),
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

  Widget _buildInsightSection(BuildContext context, _TermData d) {
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
                SizedBox(width: 12),
                Text(AppLocalizations.of(context).t('solar_solar_term_essence'), style: TextStyle(
                  fontSize: 13, letterSpacing: 3,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: ShunShiColors.secondary,
                )),
              ],
            ),
            SizedBox(height: 20),
            Text(d.quote, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w400, height: 1.4,
              fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            )),
            SizedBox(height: 16),
            Text(d.description, style: TextStyle(
              fontSize: 15, height: 1.8,
              color: ShunShiColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoSection(BuildContext context, _TermData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 28, height: 1, color: ShunShiColors.apricot),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context).t('solar_seasons_living_guide'), style: TextStyle(
                fontSize: 13, letterSpacing: 3,
                fontFamily: ShunShiTypography.serifFamily,
                color: ShunShiColors.secondary,
              )),
            ],
          ),
          SizedBox(height: 24),
          // Bento grid
          Column(
            children: [
              // Full-width food card
              _foodCard(context, d),
              SizedBox(height: 12),
              // Two-column row
              Row(
                children: [
                  Expanded(child: _livingCard(context, d)),
                  SizedBox(width: 12),
                  Expanded(child: _exerciseCard(context, d)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _foodCard(BuildContext context, _TermData d) {
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
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).t('home_dietary_wisdom'), style: TextStyle(
                fontSize: 11, letterSpacing: 2,
                color: ShunShiColors.primary,
              )),
            ],
          ),
          SizedBox(height: 16),
          Text(d.foodTitle, style: TextStyle(
            fontSize: 20, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.textPrimary,
          )),
          SizedBox(height: 12),
          Text(d.foodDesc, style: TextStyle(
            fontSize: 13, height: 1.6, color: ShunShiColors.textSecondary,
          )),
          SizedBox(height: 16),
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

  Widget _livingCard(BuildContext context, _TermData d) {
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
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).t('solar_daily_rhythm'), style: TextStyle(
                fontSize: 11, letterSpacing: 2, color: ShunShiColors.secondary,
              )),
            ],
          ),
          SizedBox(height: 12),
          Text(d.livingTitle, style: TextStyle(
            fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.textPrimary,
          )),
          SizedBox(height: 8),
          Text(d.livingDesc, style: TextStyle(
            fontSize: 12, height: 1.6, color: ShunShiColors.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, _TermData d) {
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
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).t('home_movement_practice'), style: TextStyle(
                fontSize: 11, letterSpacing: 2,
                color: ShunShiColors.primary.withValues(alpha: 0.7),
              )),
            ],
          ),
          SizedBox(height: 12),
          Text(d.exerciseTitle, style: TextStyle(
            fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
            color: ShunShiColors.textPrimary,
          )),
          SizedBox(height: 8),
          Text(d.exerciseDesc, style: TextStyle(
            fontSize: 12, height: 1.6,
            color: ShunShiColors.primary.withValues(alpha: 0.8),
          )),
        ],
      ),
    );
  }

  Widget _buildMeditationCard(BuildContext context, _TermData d) {
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
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context).t('solar_mindful_meditation'), style: TextStyle(
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
            SizedBox(height: 16),
            Text(d.meditationTitle, style: TextStyle(
              fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            )),
            SizedBox(height: 12),
            Text(d.meditationDesc, style: TextStyle(
              fontSize: 13, height: 1.7, color: ShunShiColors.textSecondary,
            )),
            SizedBox(height: 24),
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
                    child: Icon(Icons.play_arrow, size: 28, color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
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
