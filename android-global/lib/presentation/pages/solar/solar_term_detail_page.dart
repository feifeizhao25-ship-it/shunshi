// ignore_for_file: unused_field
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:shimmer/shimmer.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
import '../../../core/config/app_config.dart';
import '../../../data/en_content.dart';

class SolarTermDetailPage extends StatefulWidget {
  final String termName;
  final String? season;

  const SolarTermDetailPage({super.key, required this.termName, this.season});

  @override
  State<SolarTermDetailPage> createState() => _SolarTermDetailPageState();
}

class _SolarTermDetailPageState extends State<SolarTermDetailPage> {
  bool _apiError = false;
  bool _isLoading = true;

  Map<String, dynamic> _termDetail = {};

  static const Map<String, _TermInfo> _termData = {
    'Start of Spring': _TermInfo(en: 'Start of Spring', quote: 'Spring three months, called "pushing up and out", heaven and earth both generate, all things flourish.', season: 'Early Spring'),
    'Rain Water': _TermInfo(en: 'Rain Water', quote: 'Good rain knows its season, when spring arrives it brings life.', season: 'Early Spring'),
    'Awakening of Insects': _TermInfo(en: 'Awakening of Insects', quote: 'Spring thunder sounds, all things grow.', season: 'Mid Spring'),
    'Spring Equinox': _TermInfo(en: 'Spring Equinox', quote: 'Day and night are equal, Yin and Yang are in harmony.', season: 'Mid Spring'),
    'Clear and Bright': _TermInfo(en: 'Clear and Bright', quote: 'A drizzling rain falls like tears on the Mourning Day.', season: 'Late Spring'),
    'Grain Rain': _TermInfo(en: 'Grain Rain', quote: 'Rain gives birth to all grains, all things are renewed.', season: 'Late Spring'),
    'Start of Summer': _TermInfo(en: 'Start of Summer', quote: 'Summer three months, called "flourishing and elegant", heaven and earth energy intermingle, all things bloom and bear fruit.', season: 'Early Summer'),
    'Grain Buds': _TermInfo(en: 'Grain Buds', quote: 'Wheat ears begin to fill, rivers gradually swell.', season: 'Early Summer'),
    'Grain in Ear': _TermInfo(en: 'Grain in Ear', quote: 'Busy sowing during Grain in Ear, the hardest time for farmers.', season: 'Mid Summer'),
    'Summer Solstice': _TermInfo(en: 'Summer Solstice', quote: 'The day is at its longest, shadows at their shortest.', season: 'Mid Summer'),
    'Minor Heat': _TermInfo(en: 'Minor Heat', quote: 'Minor and Major Heat, steaming above and boiling below.', season: 'Late Summer'),
    'Major Heat': _TermInfo(en: 'Major Heat', quote: 'Major Heat is the peak of hotness.', season: 'Late Summer'),
    'Start of Autumn': _TermInfo(en: 'Start of Autumn', quote: 'Autumn three months, called "tranquil balance", heaven\'s energy is urgent, earth\'s energy is clear.', season: 'Early Autumn'),
    'End of Heat': _TermInfo(en: 'End of Heat', quote: 'End of Heat means heat recedes, though midday remains warm.', season: 'Early Autumn'),
    'White Dew': _TermInfo(en: 'White Dew', quote: 'Dew condenses white, the autumn mood deepens.', season: 'Mid Autumn'),
    'Autumnal Equinox': _TermInfo(en: 'Autumnal Equinox', quote: 'Autumn Equinox, Yin and Yang are equally balanced.', season: 'Mid Autumn'),
    'Cold Dew': _TermInfo(en: 'Cold Dew', quote: 'Gentle cool winds stir, cold dew falls softly.', season: 'Late Autumn'),
    'Frost\'s Descent': _TermInfo(en: "Frost's Descent", quote: 'Frost descends, bring flowers indoors.', season: 'Late Autumn'),
    'Start of Winter': _TermInfo(en: 'Start of Winter', quote: 'Winter three months, called "closing and storing", water freezes and earth cracks, do not disturb Yang.', season: 'Early Winter'),
    'Minor Snow': _TermInfo(en: 'Minor Snow', quote: 'Minor Snow, the air grows cold and snow is coming.', season: 'Early Winter'),
    'Major Snow': _TermInfo(en: 'Major Snow', quote: 'Heavy snow falls, a timely snow promises a good harvest.', season: 'Mid Winter'),
    'Winter Solstice': _TermInfo(en: 'Winter Solstice', quote: 'At Winter Solstice one Yang is born, shadows reach their longest.', season: 'Mid Winter'),
    'Minor Cold': _TermInfo(en: 'Minor Cold', quote: 'Minor Cold and Major Cold, freezing into ice.', season: 'Late Winter'),
    'Major Cold': _TermInfo(en: 'Major Cold', quote: 'Major Cold is the extreme, building upon Minor Cold.', season: 'Late Winter'),
  };

  @override
  void initState() {
    super.initState();
    _fetchTermDetail();
  }

  Future<void> _fetchTermDetail() async {
    try {
      // Use the base URL from app config or default to ECS
      // In production this should come from app_constants
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/api/v1/solar-terms/detail/${Uri.encodeComponent(widget.termName)}?locale=en-US';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          _termDetail = data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() { _isLoading = false; _apiError = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _apiError = true; });
    }
  }

  List<String> _getList(dynamic field, List<String> fallback) {
    if (field is List) return field.cast<String>();
    return fallback;
  }

  /// Filter out Chinese strings, replace with fallback if all are Chinese
  List<String> _filterChinese(List<String> items) {
    final nonChinese = items.where((s) => !ZhEnMapper.isChinese(s)).toList();
    return nonChinese.isNotEmpty ? nonChinese : items;
  }

  Widget _buildSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : ShunShiColors.borderGhost!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const SizedBox(height: 60),
          Container(height: 48, width: 120, decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 8),
          Container(height: 20, width: 160, decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 32),
          Container(height: 180, decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 100, decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 20, width: 120, alignment: Alignment.centerLeft, decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 14),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(height: 72, decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background, body: SafeArea(child: _buildSkeleton()));
    }

    final termName = widget.termName;
    final info = _termData[termName] ?? _TermInfo(en: termName, quote: '', season: widget.season ?? '');

    // 从API读取真实数据
    final exercises = _filterChinese(_getList(_termDetail['exercises'], ['Outing', 'Tai Chi', 'Baduanjin', 'Walking']));
    final healthTips = _filterChinese(_getList(_termDetail['health_tips'], ['Follow the season', 'Adjust diet', 'Moderate exercise', 'Regulate emotions']));
    final acupoints = _filterChinese(_getList(_termDetail['acupoints'], ['Taichong (LR3)', 'Zusanli (ST36)', 'Hegu (LI4)']));
    final emotionalCare = _filterChinese(_getList(_termDetail['emotional_care'], ['Regulate emotions', 'Stay calm', 'Get more sunlight']));
    final recommendedFoods = _filterChinese(_getList(_termDetail['recommended_foods'], ['Seasonal produce', 'Warming foods']));

    return Scaffold(


      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => safePop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: ShunShiColors.textPrimary, size: 22)),
                Text('SEASONS AI', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textSecondary)),
                IconButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('solar_share_link_copied')), duration: Duration(seconds: 1))); }, icon: Icon(Icons.share_rounded, color: ShunShiColors.textSecondary, size: 22)),
              ],
            ),
            const SizedBox(height: 24),

            // Season tag
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${info.season} · ${termName} Solar Term',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ShunShiColors.primary, letterSpacing: 0.5)),
            )),
            const SizedBox(height: 20),

            // Solar term title
            Center(child: Column(children: [
              Text(termName, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 42, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 6),
              Text(info.en, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, color: ShunShiColors.textTertiary, letterSpacing: 1.2, fontStyle: FontStyle.italic)),
            ])),
            const SizedBox(height: 32),

            // Hero image
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(image: AssetImage('assets/images/ref_10.jpg'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),

            // Solar Term Essence
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).t('solar_solar_term_essence'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
                const SizedBox(height: 10),
                Text('「${info.quote}」', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 15, color: ShunShiColors.textSecondary, height: 1.8)),
              ]),
            ),
            const SizedBox(height: 24),

            // 顺时生活方案
            Text(AppLocalizations.of(context).t('solar_seasons_living_guide'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 14),

            // 饮食（推荐食物）
            _sectionCard('Diet', recommendedFoods.join(', '), Icons.restaurant_rounded),
            const SizedBox(height: 10),

            // 运动（真实数据）
            _sectionCard('Exercise', exercises.join(', '), Icons.self_improvement_rounded),
            const SizedBox(height: 10),

            // 穴位调理（真实数据，点击展开穴位列表）
            _buildExpandableCard('Acupressure Care', acupoints, Icons.psychology_rounded),
            const SizedBox(height: 10),

            // 情志调养（真实数据）
            _sectionCard('Emotional Care', emotionalCare.join(', '), Icons.spa_rounded),
            const SizedBox(height: 10),

            // 养生提示
            _sectionCard('Wellness Tips', healthTips.join(', '), Icons.favorite_rounded),
            const SizedBox(height: 20),

            // AI推荐卡片
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ask SEASONS AI about personalized $termName wellness plan'), duration: const Duration(seconds: 2)),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ShunShiColors.primary.withValues(alpha: 0.08), ShunShiColors.primary.withValues(alpha: 0.03)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, size: 20, color: ShunShiColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppLocalizations.of(context).t('solar_solar_term_wellness_goes_further'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
                    const SizedBox(height: 2),
                    Text('Ask SEASONS AI for a personalized wellness plan for the current solar term', style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary)),
                  ])),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: ShunShiColors.primary),
                ]),
              ),
            ),
            const SizedBox(height: 32),

            // Share CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('solar_term_detail_share_link_copied')), duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: Text(AppLocalizations.of(context).t('solar_share_this_seasonal_inspiration'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String desc, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunShiColors.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: ShunShiColors.primary, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 13, color: ShunShiColors.textTertiary)),
        ])),
        Icon(Icons.chevron_right_rounded, color: ShunShiColors.textTertiary, size: 20),
      ]),
    );
  }

  Widget _buildExpandableCard(String title, List<String> items, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunShiColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: ShunShiColors.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Text(item, style: TextStyle(fontSize: 13, color: ShunShiColors.primary)),
        )).toList()),
      ]),
    );
  }
}

class _TermInfo {
  final String en;
  final String quote;
  final String season;
  const _TermInfo({required this.en, required this.quote, required this.season});
}
