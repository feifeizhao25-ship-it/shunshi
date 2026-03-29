// lib/presentation/pages/wellness_page.dart
//
// 养生内容库页面 — 个性化推荐 + 分类浏览
// 上方: "为你推荐" (API 个性化推荐)
// 下方: "全部知识" (分类标签筛选: 食疗/茶饮/运动/穴位/睡眠/情绪)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/wellness_assets.dart';
import '../../core/theme/shunshi_colors.dart';
import '../../core/theme/shunshi_spacing.dart';
import '../../core/theme/shunshi_text_styles.dart';
import '../../data/acupoint_images.dart';
import '../../data/network/api_client.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// ── 推荐项数据模型 ──────────────────────────────────────

class _RecommendItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? type;
  final double? matchScore;
  final String? duration;
  final String? difficulty;
  final String? category;
  final List<String> tags;

  const _RecommendItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.type,
    this.matchScore,
    this.duration,
    this.difficulty,
    this.category,
    this.tags = const [],
  });

  factory _RecommendItem.fromJson(Map<String, dynamic> json) {
    return _RecommendItem(
      id: json['id']?.toString() ?? json['content_id']?.toString() ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'],
      type: json['type']?.toString(),
      matchScore: (json['match_score'] ?? json['score'])?.toDouble(),
      duration: json['duration'],
      difficulty: json['difficulty'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

// ── 内容分类 ──────────────────────────────────────────

enum WellnessCategory {
  food,        // 食疗
  acupressure, // 穴位
  exercise,    // 运动
  tea,         // 茶饮
  sleep,       // 睡眠
  emotion,     // 情绪
}

// ── 示例内容数据 ──────────────────────────────────────

class WellnessItem {
  final String title;
  final String subtitle;
  final String emoji;
  final String category;
  final String duration;
  final String difficulty;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;
  final String? tip;
  final String? acupointName;
  final String? image;

  const WellnessItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.category,
    this.duration = '',
    this.difficulty = '',
    this.tags = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.tip,
    this.acupointName,
    this.image,
  });

  String? get acupointImage {
    if (acupointName == null) return null;
    return AcupointImages.getImage(acupointName!);
  }

  String? get displayImage => image ?? acupointImage;
}

const List<WellnessItem> _kWellnessItems = [
  // ── 食疗 ──
  WellnessItem(
    title: '山药粥',
    subtitle: '补气健脾',
    emoji: '🥣',
    category: 'food',
    duration: '30min',
    difficulty: '简单',
    tags: ['补气', '健脾', '易消化'],
    ingredients: ['山药 200g', '粳米 100g', '红枣 5颗'],
    steps: ['山药去皮切块', '粳米洗净浸泡15分钟', '大火煮沸转小火', '慢炖30分钟至粥稠'],
    tip: '可加入红枣增加甜味，糖尿病患者可省略',
    image: 'assets/images/wellness/food_yam_porridge.jpg',
  ),
  WellnessItem(
    title: '银耳莲子羹',
    subtitle: '润肺安神',
    emoji: '🥣',
    category: 'food',
    duration: '2h',
    difficulty: '简单',
    tags: ['润肺', '安神', '滋阴'],
    ingredients: ['银耳 1朵', '莲子 30g', '红枣 5颗', '冰糖'],
    steps: ['银耳泡发撕小朵', '莲子去芯，红枣洗净', '加水大火烧开转小火炖2小时', '至银耳出胶，加冰糖调味'],
    tip: '冷藏后口感更佳，可加入枸杞',
    image: 'assets/images/wellness/food_lotus_soup.jpg',
  ),
  WellnessItem(
    title: '枸杞菊花茶',
    subtitle: '清肝明目',
    emoji: '🍵',
    category: 'food',
    duration: '5min',
    difficulty: '简单',
    tags: ['清肝', '明目', '降火'],
    ingredients: ['菊花 10朵', '枸杞 15粒', '冰糖适量'],
    steps: ['菊花、枸杞用清水冲洗', '放入杯中，加入沸水', '闷泡5分钟即可饮用'],
    tip: '可反复冲泡2-3次，适合长时间用眼后饮用',
    image: 'assets/images/wellness/tea_goji_chrysanthemum.jpg',
  ),
  WellnessItem(
    title: '红豆薏米粥',
    subtitle: '健脾祛湿',
    emoji: '🫘',
    category: 'food',
    duration: '1h',
    difficulty: '简单',
    tags: ['祛湿', '健脾', '消肿'],
    ingredients: ['红豆 50g', '薏米 50g', '粳米 50g'],
    steps: ['红豆、薏米提前浸泡4小时', '粳米洗净', '加水大火煮沸转小火', '煮40分钟至粥稠软烂'],
    tip: '薏米炒制后效果更佳，可减少寒性',
    image: 'assets/images/wellness/food_red_bean_porridge.jpg',
  ),

  // ── 穴位 ──
  WellnessItem(
    title: '合谷穴',
    subtitle: '止痛万能穴',
    emoji: '✋',
    category: 'acupressure',
    duration: '3min',
    difficulty: '简单',
    tags: ['止痛', '头痛', '感冒'],
    acupointName: '合谷',
    steps: ['位于虎口处，拇指与食指之间', '用拇指按揉另一手合谷穴', '每次按揉2-3分钟', '两侧交替进行'],
    tip: '孕妇禁用此穴',
  ),
  WellnessItem(
    title: '足三里',
    subtitle: '养生第一穴',
    emoji: '🦵',
    category: 'acupressure',
    duration: '5min',
    difficulty: '简单',
    tags: ['健脾', '补气', '强身'],
    acupointName: '足三里',
    steps: ['位于膝盖外侧下四横指处', '用拇指按压找到酸胀感', '每次按揉3-5分钟', '早晚各一次效果更佳'],
    tip: '艾灸足三里效果更好，每次15分钟',
  ),
  WellnessItem(
    title: '太冲穴',
    subtitle: '疏肝解郁',
    emoji: '🦶',
    category: 'acupressure',
    duration: '3min',
    difficulty: '简单',
    tags: ['疏肝', '解郁', '降火'],
    acupointName: '太冲',
    steps: ['位于足背，第一、二趾间凹陷处', '用拇指按揉该穴位', '从轻到重按揉2-3分钟', '配合深呼吸效果更好'],
    tip: '情绪烦躁时按揉可快速平复心情',
  ),

  // ── 运动 ──
  WellnessItem(
    title: '八段锦',
    subtitle: '传统气功养生',
    emoji: '🧘',
    category: 'exercise',
    duration: '15min',
    difficulty: '简单',
    tags: ['气功', '养生', '全身'],
    steps: ['双手托天理三焦', '左右开弓似射雕', '调理脾胃须单举', '五劳七伤往后瞧', '摇头摆尾去心火', '两手攀足固肾腰', '攒拳怒目增气力', '背后七颠百病消'],
    tip: '每日练习一次，贵在坚持',
  ),
  WellnessItem(
    title: '太极散步',
    subtitle: '调和气血',
    emoji: '🚶',
    category: 'exercise',
    duration: '20min',
    difficulty: '简单',
    tags: ['散步', '调和', '气血'],
    steps: ['自然呼吸，步伐放松', '配合手臂自然摆动', '保持中正安舒', '步速适中不急不缓'],
    tip: '饭后30分钟再散步为佳',
  ),

  // ── 茶饮 ──
  WellnessItem(
    title: '玫瑰花茶',
    subtitle: '疏肝理气',
    emoji: '🌹',
    category: 'tea',
    duration: '5min',
    difficulty: '简单',
    tags: ['疏肝', '理气', '美容'],
    ingredients: ['玫瑰花 5-8朵', '冰糖适量'],
    steps: ['玫瑰花用清水冲洗', '放入杯中加沸水', '闷泡5分钟即可'],
    tip: '经期不宜饮用',
  ),

  // ── 睡眠 ──
  WellnessItem(
    title: '睡前冥想',
    subtitle: '放松身心入眠',
    emoji: '😴',
    category: 'sleep',
    duration: '10min',
    difficulty: '简单',
    tags: ['放松', '冥想', '助眠'],
    steps: ['平躺闭眼，自然呼吸', '从脚趾到头顶依次放松', '专注于呼吸节奏', '让思绪自然流动'],
    tip: '每天固定时间练习，效果更佳',
  ),

  // ── 情绪 ──
  WellnessItem(
    title: '腹式呼吸',
    subtitle: '缓解焦虑',
    emoji: '🌬️',
    category: 'emotion',
    duration: '5min',
    difficulty: '简单',
    tags: ['呼吸', '焦虑', '放松'],
    steps: ['坐姿放松，一手放胸口一手放腹部', '鼻子吸气4秒，腹部隆起', '嘴巴呼气6秒，腹部收缩', '重复10次'],
    tip: '焦虑时随时可以进行',
  ),
];

// ── 分类Tab数据 ───────────────────────────────────────

class _TabData {
  final String category;
  final String label;
  final String emoji;

  const _TabData(this.category, this.label, this.emoji);
}

const _allCategories = [
  _TabData('all', '全部', '📚'),
  _TabData('food', '食疗', '🍲'),
  _TabData('tea', '茶饮', '🍵'),
  _TabData('exercise', '运动', '🧘'),
  _TabData('acupressure', '穴位', '✋'),
  _TabData('sleep', '睡眠', '😴'),
  _TabData('emotion', '情绪', '🌬️'),
];

// ═══════════════════════════════════════════════════════
// 养生百科页
// ═══════════════════════════════════════════════════════

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  String _selectedCategory = 'all';

  // 个性化推荐数据
  List<_RecommendItem> _personalizedItems = [];
  bool _personalizedLoading = true;
  bool _personalizedError = false;

  // 全部知识数据（API）
  List<Map<String, dynamic>> _knowledgeItems = [];
  bool _knowledgeLoading = false;

  static const _categoryTypeMap = {
    'food': 'food_therapy',
    'acupressure': 'acupoint',
    'exercise': 'exercise',
    'tea': 'tea',
    'sleep': 'sleep_tip',
    'emotion': 'emotion',
  };

  @override
  void initState() {
    super.initState();
    _loadPersonalized();
    _loadKnowledge();
  }

  Future<void> _loadPersonalized() async {
    setState(() {
      _personalizedLoading = true;
      _personalizedError = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final constitution = prefs.getString('constitution_type') ?? 'pinghe';
      final season = _getCurrentSeason();
      final term = _getCurrentSolarTerm();

      final client = ApiClient();
      final response = await client.post('/api/v1/recommend/personalized', data: {
        'constitution_type': constitution,
        'solar_term': term,
        'season': season,
        'categories': ['food_therapy', 'tea', 'exercise', 'acupoint', 'sleep_tip', 'emotion', 'acupressure'],
        'limit': 10,
      });
      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is Map<String, dynamic>) {
          final nested = data['data'];
          if (nested is Map<String, dynamic>) {
            items = nested['items'] ?? nested['recommendations'] ?? [];
          } else if (nested is List) {
            items = nested;
          } else {
            items = data['recommendations'] ?? data['items'] ?? [];
          }
        } else if (data is List) {
          items = data;
        }
        setState(() {
          _personalizedItems = items.map((e) => _RecommendItem.fromJson(e as Map<String, dynamic>)).toList();
          _personalizedLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Personalized recommend error: $e');
      if (mounted) setState(() {
        _personalizedLoading = false;
        _personalizedError = true;
      });
    }
  }

  String _getCurrentSeason() {
    final now = DateTime.now().month;
    if (now >= 3 && now <= 5) return 'spring';
    if (now >= 6 && now <= 8) return 'summer';
    if (now >= 9 && now <= 11) return 'autumn';
    return 'winter';
  }

  String _getCurrentSolarTerm() {
    const terms = [
      ('立春',[1,2]), ('雨水',[1,2]), ('惊蛰',[2,3]), ('春分',[3,3]),
      ('清明',[4,4]), ('谷雨',[4,5]),
      ('立夏',[5,6]), ('小满',[5,6]), ('芒种',[6,6]), ('夏至',[6,7]),
      ('小暑',[7,7]), ('大暑',[7,8]),
      ('立秋',[8,8]), ('处暑',[8,8]), ('白露',[9,9]), ('秋分',[9,10]),
      ('寒露',[10,10]), ('霜降',[10,11]),
      ('立冬',[11,11]), ('小雪',[11,11]), ('大雪',[12,12]), ('冬至',[12,12]),
      ('小寒',[1,1]), ('大寒',[1,1]),
    ];
    final now = DateTime.now();
    for (final t in terms) {
      if (t.$2.contains(now.month)) return t.$1;
    }
    return '春分';
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'all') return _knowledgeItems;
    final apiType = _categoryTypeMap[_selectedCategory] ?? _selectedCategory;
    return _knowledgeItems.where((item) => item['type'] == apiType).toList();
  }

  Future<void> _loadKnowledge() async {
    setState(() => _knowledgeLoading = true);
    try {
      final client = ApiClient();
      final resp = await client.get('/api/v1/contents', queryParameters: {
        'limit': 100,
      });
      if (resp.statusCode == 200 && mounted) {
        final data = resp.data;
        List<dynamic> items = [];
        if (data is Map<String, dynamic>) {
          final nested = data['data'];
          if (nested is Map<String, dynamic>) {
            items = nested['items'] ?? [];
          } else if (nested is List) {
            items = nested;
          }
        } else if (data is List) {
          items = data;
        }
        setState(() {
          _knowledgeItems = items.cast<Map<String, dynamic>>();
          _knowledgeLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Knowledge load error: $e');
      if (mounted) setState(() => _knowledgeLoading = false);
    }
  }

  Future<void> _onCategoryChanged(String category) async {
    setState(() => _selectedCategory = category);
    if (category != 'all') {
      setState(() => _knowledgeLoading = true);
      try {
        final apiType = _categoryTypeMap[category] ?? category;
        final client = ApiClient();
        final resp = await client.get('/api/v1/contents', queryParameters: {
          'type': apiType,
          'limit': 50,
        });
        if (resp.statusCode == 200 && mounted) {
          final data = resp.data;
          List<dynamic> items = [];
          if (data is Map<String, dynamic>) {
            final nested = data['data'];
            if (nested is Map<String, dynamic>) {
              items = nested['items'] ?? [];
            } else if (nested is List) {
              items = nested;
            }
          }
          setState(() {
            _knowledgeItems = items.cast<Map<String, dynamic>>();
            _knowledgeLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _knowledgeLoading = false);
      }
    } else {
      await _loadKnowledge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunshiColors.background,
      body: CustomScrollView(
        slivers: [
          // ── 顶部标题区 ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '养生知识库',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: ShunshiColors.textPrimary, height: 1.2),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '个性化推荐 · 精准养生',
                                style: TextStyle(fontSize: 14, color: ShunshiColors.textSecondary),
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: ShunshiColors.background, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.search_rounded, color: ShunshiColors.textSecondary, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 为你推荐区域 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      const Text('为你推荐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary)),
                      const Spacer(),
                      if (!_personalizedLoading && _personalizedItems.isNotEmpty)
                        GestureDetector(
                          onTap: _loadPersonalized,
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 14, color: ShunshiColors.primary),
                              const SizedBox(width: 4),
                              Text('换一批', style: TextStyle(fontSize: 13, color: ShunshiColors.primary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPersonalizedList(),
                ],
              ),
            ),
          ),

          // ── 分隔线 ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Divider(color: ShunshiColors.divider, thickness: 1),
            ),
          ),

          // ── 全部知识标题 + 分类标签 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('全部知识', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildCategoryTabs(),
                ],
              ),
            ),
          ),

          // ── 内容卡片网格 ──
          _filteredItems.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _KnowledgeCard(item: _filteredItems[index]);
                      },
                      childCount: _filteredItems.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 为你推荐列表
  // ═══════════════════════════════════════════

  Widget _buildPersonalizedList() {
    if (_personalizedLoading) {
      return SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => _buildShimmerCard(),
        ),
      );
    }

    if (_personalizedError || _personalizedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('📋', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text('暂无个性化推荐', style: ShunshiTextStyles.bodySecondary),
            const SizedBox(height: 4),
            Text('完成体质测试后可获得推荐', style: ShunshiTextStyles.caption),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _personalizedItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildPersonalizedCard(_personalizedItems[index]);
        },
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: ShunshiColors.surfaceDim.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: ShunshiColors.divider.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 100, decoration: BoxDecoration(color: ShunshiColors.divider.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 60, decoration: BoxDecoration(color: ShunshiColors.divider.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedCard(_RecommendItem item) {
    return GestureDetector(
      onTap: () => context.go('/content/${item.id}'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, 2), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.asset(
                WellnessAssets.getImageForType(item.type ?? 'tips', item.id),
                width: 150,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 150,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ShunshiColors.primary.withValues(alpha: 0.3), ShunshiColors.primary.withValues(alpha: 0.05)],
                    ),
                  ),
                  child: const Center(child: Text('🍃', style: TextStyle(fontSize: 28))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ShunshiColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildMatchBadge(item.matchScore),
                  const SizedBox(height: 4),
                  if (item.duration != null || item.difficulty != null)
                    Text(
                      '${item.duration ?? ''}${item.duration != null && item.difficulty != null ? ' · ' : ''}${item.difficulty ?? ''}',
                      style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textTertiary),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchBadge(double? score) {
    if (score == null) return const SizedBox.shrink();
    final label = score >= 85 ? '高度匹配' : score >= 65 ? '推荐' : '参考';
    final color = score >= 85 ? const Color(0xFF4CAF50) : score >= 65 ? const Color(0xFFFF9800) : const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text('$label ${score.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }

  // ═══════════════════════════════════════════
  // 分类标签
  // ═══════════════════════════════════════════

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _allCategories[index];
          final isSelected = _selectedCategory == cat.category;
          return GestureDetector(
            onTap: () => _onCategoryChanged(cat.category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? ShunshiColors.primary : ShunshiColors.background,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: isSelected ? ShunshiColors.primary : ShunshiColors.divider.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: TextStyle(fontSize: isSelected ? 14 : 13)),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : ShunshiColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Center(child: Text('📚', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('暂无内容', style: ShunshiTextStyles.heading.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text('更多内容即将上线', style: ShunshiTextStyles.bodySecondary.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── 分类颜色/Emoji映射 ────────────────────────────────

const _categoryGradients = {
  'food': [Color(0xFF8B9E7E), Color(0xFFB5C7A8)],
  'acupressure': [Color(0xFFC4A882), Color(0xFFD4C4A8)],
  'exercise': [Color(0xFFD4956A), Color(0xFFE4B59A)],
  'tea': [Color(0xFF7E9F8B), Color(0xFFA8BFC0)],
  'emotion': [Color(0xFF9B8EC4), Color(0xFFB8B0D4)],
  'sleep': [Color(0xFF7E9FAF), Color(0xFFA0B8C7)],
};

const _categoryEmojis = {
  'food': '🥣',
  'acupressure': '✋',
  'exercise': '🧘',
  'tea': '🍵',
  'emotion': '🌬️',
  'sleep': '😴',
};

// ── 知识卡片（全部知识区域） ──────────────────────────

class _KnowledgeCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _KnowledgeCard({required this.item});

  @override
  State<_KnowledgeCard> createState() => _KnowledgeCardState();
}

class _KnowledgeCardState extends State<_KnowledgeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title => widget.item['title'] as String? ?? '';
  String get _desc => widget.item['description'] as String? ?? widget.item['content'] as String? ?? '';
  String get _type => widget.item['type'] as String? ?? 'food_therapy';
  List<dynamic> get _tags => widget.item['tags'] as List? ?? [];
  String get _contentId => (widget.item['id'] as String?) ?? '';

  Color get _accentColor {
    const typeColors = {
      'food_therapy': Color(0xFF8B9E7E),
      'tea': Color(0xFF7E9F8B),
      'exercise': Color(0xFFD4956A),
      'acupoint': Color(0xFFC4A882),
      'acupressure': Color(0xFFC4A882),
      'sleep_tip': Color(0xFF7E9FAF),
      'emotion': Color(0xFF9B8EC4),
      'recipe': Color(0xFF8B9E7E),
      'tips': Color(0xFFB0BEC5),
    };
    return typeColors[_type] ?? ShunshiColors.primary;
  }

  String get _emoji {
    const emojis = {
      'food_therapy': '🥣', 'recipe': '🥣',
      'tea': '🍵',
      'exercise': '🧘',
      'acupoint': '✋', 'acupressure': '🤲',
      'sleep_tip': '😴',
      'emotion': '🌬️',
      'tips': '💡',
      'solar_term': '🌿',
    };
    return emojis[_type] ?? '📋';
  }

  String get _categoryLabel {
    const labels = {
      'food_therapy': '食疗', 'recipe': '食谱',
      'tea': '茶饮',
      'exercise': '运动',
      'acupoint': '穴位', 'acupressure': '按摩',
      'sleep_tip': '睡眠',
      'emotion': '情志',
      'tips': '养生',
      'solar_term': '节气',
    };
    return labels[_type] ?? '养生';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (_contentId.isNotEmpty) {
          context.go('/content/$_contentId');
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedScale(
        scale: _scaleAnimation.value,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部 Emoji 区
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(_emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              // 文字内容
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_desc.isNotEmpty)
                      Text(
                        _desc,
                        style: ShunshiTextStyles.caption.copyWith(fontSize: 11, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_categoryLabel, style: const TextStyle(fontSize: 10, color: ShunshiColors.primary)),
                          ),
                          if (_tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ShunshiColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _tags.first.toString(),
                                style: const TextStyle(fontSize: 10, color: ShunshiColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
