/// Wellness馆Home — 参考UI _14
/// DiscoverWellness内容的入口
///
/// 结构:
/// 1. Search栏
/// 2. 6个分类卡片（2行3列）
/// 3. EditFeatured文章列表
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../data/en_content.dart';
import '../../../core/network/api_singleton.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _dio = apiClient.dio;

  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();

  static final _categories = [
    _Category(Icons.health_and_safety, 'Body Type Care', const Color(0xFFE8F5E9), 'constitution'),
    _Category(Icons.restaurant_menu, 'Solar TermRecipes', const Color(0xFFFFF3E0), 'diet'),
    _Category(Icons.emoji_food_beverage, 'Wellness Tea', const Color(0xFFE3F2FD), 'tea'),
    _Category(Icons.architecture, 'MeridianAcupressure', const Color(0xFFFCE4EC), 'meridian'),
    _Category(Icons.self_improvement, 'Traditional Qigong', const Color(0xFFE8EAF6), 'exercise'),
    _Category(Icons.settings_voice, 'Sleep & Calming', const Color(0xFFE0F2F1), 'sleep'),
  ];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await _dio.get('/api/v1/contents/search', queryParameters: {'q': query.trim()});
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final items = data['data']['items'];
        if (items is List) _searchResults = items.cast<Map<String, dynamic>>();
      }
      setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    // Use local English content
    final localArticles = EnContentData.articles.map((c) => EnContentData.toMap(c)).toList();
    if (!mounted) return;
    setState(() {
      _articles = localArticles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: RefreshIndicator(
        color: ShunShiColors.primary,
        onRefresh: _fetchArticles,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
            title: Text(AppLocalizations.of(context).t('discover_wellness_library'), style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily,
              color: ShunShiColors.textPrimary,
            )),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                color: ShunShiColors.textSecondary,
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => _search(v),
                  decoration: InputDecoration(
                    hintText: 'Search recipes, tea, qigong...',
                    hintStyle: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 20, color: ShunShiColors.textTertiary),
                    suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: ShunShiColors.textTertiary),
                      onPressed: () { _searchController.clear(); setState(() { _searchResults = []; _searching = false; }); },
                    ) : null,
                  ),
                  style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary),
                ),
              ),
            ),
          ),

          // ── Search Results ──
          if (_searching && _searchResults.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text('Search Results (${_searchResults.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final item = _searchResults[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.article, color: ShunShiColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['title']?.toString() ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
                        if (item['description'] != null) Text(item['description'].toString(), style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                    ]),
                  ),
                );
              }, childCount: _searchResults.length),
            ),
          ] else if (_searching && _searchResults.isEmpty && _searchController.text.isNotEmpty) ...[
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(AppLocalizations.of(context).t('discover_no_relevant_results_found'), style: TextStyle(color: ShunShiColors.textTertiary))))),
          ],

          // ── Category Grid (hide when searching) ──
          if (!_searching) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: _categories.map((cat) => _categoryCard(context, cat)).toList(),
              ),
            ),
          ),
          ], // end if (!_searching)

          // ── Editor's Choice Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: Row(children: [
                Text(AppLocalizations.of(context).t('discover_featurededit'), style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: ShunShiColors.textPrimary,
                  fontFamily: ShunShiTypography.serifFamily,
                )),
                Text(AppLocalizations.of(context).t('discover_editors_choice'), style: TextStyle(
                  fontSize: 12, color: ShunShiColors.textTertiary,
                  fontFamily: ShunShiTypography.sansFamily,
                )),
                const Spacer(),
                GestureDetector(
                onTap: () {
                    context.push('/wellness-category/food_therapy');
                  },
                  child: Row(children: [
                    Text(AppLocalizations.of(context).t('view_all'), style: TextStyle(
                      fontSize: 13, color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.sansFamily,
                    )),
                    const Icon(Icons.chevron_right, size: 18, color: ShunShiColors.primary),
                  ]),
                ),
              ]),
            ),
          ),

          // ── Article List (API) ──
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (_loading && index == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: ShunShiColors.primary)),
                  );
                }
                if (index >= _articles.length) return const SizedBox.shrink();
                final item = _articles[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _apiArticleCard(item),
                );
              },
              childCount: _loading ? 1 : _articles.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      ),
    );
  }

  Widget _categoryCard(BuildContext ctx, _Category cat) {
    return GestureDetector(
      onTap: () {
        if (cat.route == 'constitution') {
          ctx.push('/constitution');
        } else if (cat.route == 'diet') {
          ctx.push('/wellness-category/food_therapy');
        } else if (cat.route == 'meridian') {
          ctx.push('/wellness-category/acupressure');
        } else {
          ctx.push('/wellness-category/${cat.route}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: cat.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.icon, size: 24, color: ShunShiColors.primary),
            ),
            const SizedBox(height: 8),
            Text(cat.title, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: ShunShiColors.textPrimary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
          ],
        ),
      ),
    );
  }

  Widget _apiArticleCard(Map<String, dynamic> item) {
    final tags = (item['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final type = item['type']?.toString() ?? '';
    return GestureDetector(
      onTap: () {
        final id = item['id']?.toString();
        if (id != null) context.push('/content-detail', extra: {'contentId': id});
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _articleTag(item['category']?.toString() ?? type),
            if (item['duration'] != null) ...[
              const SizedBox(width: 8),
              Text(item['duration'].toString(), style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
            ],
          ]),
          const SizedBox(height: 8),
          Text(item['title']?.toString() ?? '', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary,
            fontFamily: ShunShiTypography.serifFamily,
          )),
          const SizedBox(height: 6),
          Text(item['description']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(
            fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5,
          )),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: tags.take(3).map((t) => _articleTag(t)).toList()),
          ],
        ],
      ),
    ),
    );
  }

  Widget _articleTag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: ShunShiColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500,
      color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
    )),
  );
}

class _Category {
  final IconData icon;
  final String title;
  final Color bgColor;
  final String route;
  const _Category(this.icon, this.title, this.bgColor, this.route);
}

class _Article {
  final String tag;
  final String readTime;
  final String title;
  final String excerpt;
  final String likes;
  const _Article(this.tag, this.readTime, this.title, this.excerpt, this.likes);
}
