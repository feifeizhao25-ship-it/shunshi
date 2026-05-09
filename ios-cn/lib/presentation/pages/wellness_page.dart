// lib/presentation/pages/wellness_page.dart
//
// 养生内容库页面 — 按分类Tab展示
// 食疗 · 穴位 · 运动 · 茶饮 (4 tabs)
// 内容卡片网格：圆角12，无阴影，surfaceDim背景
// SingleChildScrollView滚动

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/shunshi_colors.dart';
import '../../core/theme/shunshi_spacing.dart';
import '../../core/theme/shunshi_text_styles.dart';

// ── 内容分类 ──────────────────────────────────────────

enum WellnessCategory {
  food,        // 食疗
  acupressure, // 穴位
  exercise,    // 运动
  tea,         // 茶饮
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
  });
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
    steps: [
      '山药去皮切块',
      '粳米洗净浸泡15分钟',
      '大火煮沸转小火',
      '慢炖30分钟至粥稠',
    ],
    tip: '可加入红枣增加甜味，糖尿病患者可省略',
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
    steps: [
      '银耳泡发撕小朵',
      '莲子去芯，红枣洗净',
      '加水大火烧开转小火炖2小时',
      '至银耳出胶，加冰糖调味',
    ],
    tip: '冷藏后口感更佳，可加入枸杞',
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
    steps: [
      '菊花、枸杞用清水冲洗',
      '放入杯中，加入沸水',
      '闷泡5分钟即可饮用',
    ],
    tip: '可反复冲泡2-3次，适合长时间用眼后饮用',
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
    steps: [
      '红豆、薏米提前浸泡4小时',
      '粳米洗净',
      '加水大火煮沸转小火',
      '煮40分钟至粥稠软烂',
    ],
    tip: '薏米炒制后效果更佳，可减少寒性',
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
    steps: [
      '位于虎口处，拇指与食指之间',
      '用拇指按揉另一手合谷穴',
      '每次按揉2-3分钟',
      '两侧交替进行',
    ],
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
    steps: [
      '位于膝盖外侧下四横指处',
      '用拇指按压找到酸胀感',
      '每次按揉3-5分钟',
      '早晚各一次效果更佳',
    ],
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
    steps: [
      '位于足背，第一、二趾间凹陷处',
      '用拇指按揉该穴位',
      '从轻到重按揉2-3分钟',
      '配合深呼吸效果更好',
    ],
    tip: '情绪烦躁时按揉可快速平复心情',
  ),

  // ── 运动 ──
  WellnessItem(
    title: '八段锦',
    subtitle: '全身经络疏通',
    emoji: '🧘',
    category: 'exercise',
    duration: '12min',
    difficulty: '入门',
    tags: ['全身', '经络', '柔韧'],
    steps: [
      '双手托天理三焦',
      '左右开弓似射雕',
      '调理脾胃须单举',
      '五劳七伤往后瞧',
      '摇头摆尾去心火',
      '两手攀足固肾腰',
      '攒拳怒目增气力',
      '背后七颠百病消',
    ],
    tip: '配合呼吸，每个动作做6-8次',
  ),
  WellnessItem(
    title: '晨起伸展',
    subtitle: '5分钟唤醒身体',
    emoji: '🌅',
    category: 'exercise',
    duration: '5min',
    difficulty: '入门',
    tags: ['晨练', '拉伸', '唤醒'],
    steps: [
      '仰卧，双臂上举伸展全身',
      '左右侧弯，拉伸腰侧',
      '抱膝，放松背部',
      '坐起，体前屈触碰脚趾',
      '站立，缓缓后仰展胸',
    ],
    tip: '动作轻柔，不可强迫拉伸',
  ),
  WellnessItem(
    title: '睡前安神功',
    subtitle: '助眠放松操',
    emoji: '😴',
    category: 'exercise',
    duration: '8min',
    difficulty: '入门',
    tags: ['助眠', '放松', '安神'],
    steps: [
      '盘坐，闭眼，深呼吸3次',
      '双肩缓慢上提后放下',
      '转动颈部，左右各5次',
      '搓手捂眼，放松眼部',
      '腹式呼吸2分钟',
    ],
    tip: '睡前30分钟做，效果最佳',
  ),

  // ── 茶饮 ──
  WellnessItem(
    title: '玫瑰花茶',
    subtitle: '疏肝解郁养颜',
    emoji: '🌹',
    category: 'tea',
    duration: '5min',
    difficulty: '简单',
    tags: ['疏肝', '养颜', '活血'],
    ingredients: ['玫瑰花 5-8朵', '冰糖适量'],
    steps: [
      '玫瑰花用清水冲洗',
      '放入杯中，加沸水',
      '闷泡5分钟即可饮用',
    ],
    tip: '可加入蜂蜜调味，经期不宜饮用',
  ),
  WellnessItem(
    title: '山楂陈皮茶',
    subtitle: '消食化滞',
    emoji: '🍊',
    category: 'tea',
    duration: '10min',
    difficulty: '简单',
    tags: ['消食', '化滞', '理气'],
    ingredients: ['山楂 10g', '陈皮 5g', '冰糖适量'],
    steps: [
      '山楂、陈皮洗净',
      '加水500ml大火煮沸',
      '转小火煮10分钟',
      '滤渣加冰糖饮用',
    ],
    tip: '饭后半小时饮用效果最佳',
  ),
  WellnessItem(
    title: '桂圆红枣茶',
    subtitle: '补气血暖身',
    emoji: '🫘',
    category: 'tea',
    duration: '15min',
    difficulty: '简单',
    tags: ['补气血', '暖身', '安神'],
    ingredients: ['桂圆 10粒', '红枣 5颗', '红糖适量'],
    steps: [
      '桂圆去壳，红枣去核',
      '加水600ml大火煮沸',
      '转小火煮15分钟',
      '加红糖搅拌融化',
    ],
    tip: '冬季暖身佳品，可反复冲泡',
  ),
];

// ── 主页面 ────────────────────────────────────────────

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WellnessCategory _selectedCategory = WellnessCategory.food;

  static const _categories = [
    _TabData(WellnessCategory.food, '食疗', '🍲'),
    _TabData(WellnessCategory.acupressure, '穴位', '✋'),
    _TabData(WellnessCategory.exercise, '运动', '🧘'),
    _TabData(WellnessCategory.tea, '茶饮', '🍵'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _categories[_tabController.index].category;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<WellnessItem> get _filteredItems {
    final catName = _selectedCategory.name;
    return _kWellnessItems.where((item) => item.category == catName).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunshiColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 标题 ──
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ShunshiSpacing.pagePadding,
                  20,
                  ShunshiSpacing.pagePadding,
                  8,
                ),
                child: Text(
                  '养生内容',
                  style: ShunshiTextStyles.greeting,
                ),
              ),
            ),

            // ── 分类Tab (下划线指示器) ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ShunshiSpacing.pagePadding,
              ),
              child: _CategoryTabs(
                controller: _tabController,
                categories: _categories,
              ),
            ),

            const SizedBox(height: 20),

            // ── 内容网格 ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ShunshiSpacing.pagePadding,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
                children: _filteredItems.map((item) {
                  return _ContentCard(
                    item: item,
                    onTap: () => _showDetail(context, item),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WellnessItem item) {
    context.go('/content/${item.title}');
  }
}

// ── 分类Tab组件 ───────────────────────────────────────

class _TabData {
  final WellnessCategory category;
  final String label;
  final String emoji;

  const _TabData(this.category, this.label, this.emoji);
}

class _CategoryTabs extends StatelessWidget {
  final TabController controller;
  final List<_TabData> categories;

  const _CategoryTabs({
    required this.controller,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ShunshiColors.divider,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        indicatorColor: ShunshiColors.primary,
        labelColor: ShunshiColors.textPrimary,
        unselectedLabelColor: ShunshiColors.textSecondary,
        labelStyle: ShunshiTextStyles.button,
        unselectedLabelStyle: ShunshiTextStyles.buttonSmall,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: categories
            .map((c) => Tab(text: '${c.emoji} ${c.label}'))
            .toList(),
      ),
    );
  }
}

// ── 内容卡片 — 圆角12，无阴影，surfaceDim背景 ──

class _ContentCard extends StatelessWidget {
  final WellnessItem item;
  final VoidCallback onTap;

  const _ContentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ShunshiColors.surfaceDim,
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
          // 无阴影
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // emoji区域
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ShunshiColors.surfaceDim.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ShunshiSpacing.radiusMedium),
                  ),
                ),
                child: Center(
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            // 文字区域
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: ShunshiTextStyles.heading.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: ShunshiTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (item.duration.isNotEmpty) ...[
                          Text(
                            item.duration,
                            style: ShunshiTextStyles.overline,
                          ),
                          if (item.difficulty.isNotEmpty) ...[
                            Text(
                              ' · ',
                              style: ShunshiTextStyles.overline,
                            ),
                            Text(
                              item.difficulty,
                              style: ShunshiTextStyles.overline,
                            ),
                          ],
                        ],
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
}

