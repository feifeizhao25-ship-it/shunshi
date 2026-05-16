/// 节气详情页 — API 驱动
/// 数据: /api/v1/solar-terms/enhanced/current + /enhanced/{name}
/// 展示节气内涵、饮食/起居/功法/冥想建议
library;

import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';import '../../widgets/state_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../data/en_content.dart';

class SolarTermPageV2 extends StatefulWidget {
  final String? termName;
  const SolarTermPageV2({super.key, this.termName});

  @override
  State<SolarTermPageV2> createState() => _SolarTermPageV2State();
}

class _SolarTermPageV2State extends State<SolarTermPageV2> {
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''), connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 15)));

  Map<String, dynamic> _term = {};
  Map<String, dynamic> _next = {};
  Map<String, dynamic> _wellness = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final url = widget.termName != null
          ? '/api/v1/solar-terms/enhanced/${Uri.encodeComponent(widget.termName!)}?locale=en-US'
          : '/api/v1/solar-terms/enhanced/current?locale=en-US';
      final res = await _dio.get(url);
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final d = data['data'] as Map;
        if (d['current'] is Map) {
          _term = Map<String, dynamic>.from(d['current']);
          if (d['next'] is Map) _next = Map<String, dynamic>.from(d['next']);
        } else if (d['term'] is Map) {
          _term = Map<String, dynamic>.from(d['term']);
        }
        if (d['wellness_plan'] is Map) {
          _wellness = Map<String, dynamic>.from(d['wellness_plan']);
        }
      }
    } catch (_) {}

    // Fallback to local English data if API data is empty or Chinese
    if (_term.isEmpty) {
      _term = {
        'name': 'Current Solar Term',
        'name_en': 'Seasonal Transition',
        'emoji': '🌿',
        'date': '',
      };
    }

    // Ensure name_en is set for Chinese name
    if (_term.containsKey('name') && !_term.containsKey('name_en')) {
      _term['name_en'] = ZhEnMapper.solarTerm(_term['name']?.toString());
    }

    // Replace Chinese wellness data with local English content
    _replaceChineseWellnessData();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// Replace any Chinese content in wellness plan with local English data
  void _replaceChineseWellnessData() {
    bool hasChinese = false;

    void checkAndReplace(List<dynamic>? items, List<EnContent> replacements, String key) {
      if (items == null || items.isEmpty) return;
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item is Map<String, dynamic>) {
          final title = item['title']?.toString() ?? '';
          final desc = item['description']?.toString() ?? '';
          if (ZhEnMapper.isChinese(title) || ZhEnMapper.isChinese(desc)) {
            hasChinese = true;
            if (i < replacements.length) {
              item['title'] = replacements[i].title;
              item['description'] = replacements[i].description;
              item['tags'] = replacements[i].tags;
            }
          }
        }
      }
    }

    // Check and replace diet
    final diet = _wellness['diet'];
    if (diet is List) checkAndReplace(diet.cast<Map<String, dynamic>>(), EnContentData.foods, 'diet');

    // Check and replace exercise
    final exercise = _wellness['exercise'];
    if (exercise is List) checkAndReplace(exercise.cast<Map<String, dynamic>>(), EnContentData.exercises, 'exercise');

    // Check and replace tea
    final tea = _wellness['tea'];
    if (tea is List) checkAndReplace(tea.cast<Map<String, dynamic>>(), EnContentData.teas, 'tea');

    // If ALL wellness data was Chinese, rebuild from local
    if (_wellness.isEmpty || hasChinese && _wellness.isEmpty) {
      _wellness = {
        'diet': EnContentData.foods.take(3).map((f) => <String, dynamic>{
          'title': f.title,
          'description': f.description,
          'tags': f.tags,
        }).toList(),
        'exercise': EnContentData.exercises.take(2).map((e) => <String, dynamic>{
          'title': e.title,
          'description': e.description,
          'tags': e.tags,
        }).toList(),
        'tea': EnContentData.teas.take(2).map((t) => <String, dynamic>{
          'title': t.title,
          'description': t.description,
          'tags': t.tags,
        }).toList(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: _loading
          ? const LoadingSkeleton()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back, size: 20, color: ShunShiColors.textPrimary),
                          ),
                        ),
                        const Spacer(),
                        Text(AppLocalizations.of(context).t('app_title'), style: TextStyle(
                          fontFamily: ShunShiTypography.serifFamily,
                          fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.primary,
                        )),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ]),
                    ),
                  ),
                ),

                // 节气标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(_term['emoji']?.toString() ?? '🌿', style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ZhEnMapper.solarTermFromApi(_term), style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 32, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
                          )),
                          Text(ZhEnMapper.isChinese(_term['name']?.toString()) ? _term['name']?.toString() ?? '' : '', style: TextStyle(
                            fontSize: 14, color: ShunShiColors.textTertiary,
                          )),
                        ])),
                      ]),
                      const SizedBox(height: 8),
                      if (_term['date'] != null)
                        Text('${_term['date']}', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
                      if (_term['days_remaining'] != null) ...[
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).t('solar_days_until_next', params: {'days': '${_term['days_remaining']}'}), style: TextStyle(fontSize: 13, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
                      ],
                    ]),
                  ),
                ),

                // 下一个节气预告
                if (_next.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Text(_next['emoji']?.toString() ?? '🌱', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${AppLocalizations.of(context).t('solar_next').replaceAll('{name}', ZhEnMapper.solarTermFromApi(_next))}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                            Text('${ZhEnMapper.isChinese(_next['name']?.toString()) ? _next['name'] ?? '' : ''} · ${_next['countdown_days'] != null ? '${_next['countdown_days']}d away' : _next['date'] ?? ''}',
                              style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                          ])),
                        ]),
                      ),
                    ),
                  ),

                // 饮食建议
                if (_wellness['diet'] is List) ...[
                  _buildSectionTitle(AppLocalizations.of(context).t('solar_dietary_care')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Column(children: (_wellness['diet'] as List).take(3).cast<Map<String, dynamic>>().map((item) => _buildWellnessCard(
                        icon: '🍲',
                        title: item['title']?.toString() ?? '',
                        desc: item['description']?.toString() ?? '',
                        tags: (item['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
                      )).toList()),
                    ),
                  ),
                ],

                // 运动建议
                if (_wellness['exercise'] is List) ...[
                  _buildSectionTitle(AppLocalizations.of(context).t('solar_exercise')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Column(children: (_wellness['exercise'] as List).take(2).cast<Map<String, dynamic>>().map((item) => _buildWellnessCard(
                        icon: '🧘',
                        title: item['title']?.toString() ?? '',
                        desc: item['description']?.toString() ?? '',
                        tags: (item['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
                      )).toList()),
                    ),
                  ),
                ],

                // 茶饮建议
                if (_wellness['tea'] is List) ...[
                  _buildSectionTitle(AppLocalizations.of(context).t('solar_seasonal_teas')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Column(children: (_wellness['tea'] as List).take(2).cast<Map<String, dynamic>>().map((item) => _buildWellnessCard(
                        icon: '🫖',
                        title: item['title']?.toString() ?? '',
                        desc: item['description']?.toString() ?? '',
                        tags: (item['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
                      )).toList()),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
      ),
    );
  }

  Widget _buildWellnessCard({required String icon, required String title, required String desc, List<String> tags = const []}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary))),
          ]),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
              child: Text(t, style: TextStyle(fontSize: 10, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
            )).toList()),
          ],
        ]),
      ),
    );
  }
}
