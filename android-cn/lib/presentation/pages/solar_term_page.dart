// lib/presentation/pages/solar_term_page.dart
//
// 节气养生页面 — 按产品文档 FINAL_UI_STRUCTURE.md 实现
// 1. 顶部节气大卡片（渐变背景+节气名+诗词）
// 2. 推荐内容区（横向滚动卡片：食疗/穴位/运动）
// 3. 节气养生建议（分类分组）
// 4. 24节气时间线（可滚动，当前高亮）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/shunshi_colors.dart';
import '../../core/theme/shunshi_spacing.dart';
import '../../core/theme/shunshi_text_styles.dart';
import '../../data/network/api_client.dart';
import 'solar/solar_term_detail_page.dart';

// ── Mock 数据模型 ──────────────────────────────────────

class SolarTermInfo {
  final String name;
  final String date;
  final int month;
  final int day;
  final String season; // spring / summer / autumn / winter
  final String emoji;
  final String poem;
  final List<String> diet;
  final List<String> acupoint;
  final List<String> exercise;
  final List<String> emotion;
  final int durationDays;

  const SolarTermInfo({
    required this.name,
    required this.date,
    required this.month,
    required this.day,
    required this.season,
    required this.emoji,
    required this.poem,
    required this.diet,
    required this.acupoint,
    required this.exercise,
    required this.emotion,
    this.durationDays = 15,
  });

  String get seasonLabel {
    switch (season) {
      case 'spring':
        return '春季';
      case 'summer':
        return '夏季';
      case 'autumn':
        return '秋季';
      case 'winter':
        return '冬季';
      default:
        return '';
    }
  }

  String get seasonShort {
    switch (season) {
      case 'spring':
        return '春';
      case 'summer':
        return '夏';
      case 'autumn':
        return '秋';
      case 'winter':
        return '冬';
      default:
        return '';
    }
  }
}

// ── 24节气完整Mock数据 ─────────────────────────────────

const List<SolarTermInfo> _kAllSolarTerms = [
  SolarTermInfo(
    name: '立春',
    date: '二月四日',
    month: 2,
    day: 4,
    season: 'spring',
    emoji: '🌱',
    poem: '东风送暖立春来，万物复苏百花开',
    diet: ['葱白姜汤', '韭菜炒鸡蛋', '辛甘发散食物'],
    acupoint: ['太冲穴', '足三里', '风池穴'],
    exercise: ['散步', '太极拳', '拉伸运动'],
    emotion: ['保持心情舒畅', '多与朋友交流'],
  ),
  SolarTermInfo(
    name: '雨水',
    date: '二月十九日',
    month: 2,
    day: 19,
    season: 'spring',
    emoji: '🌧️',
    poem: '好雨知时节，当春乃发生',
    diet: ['山药薏米粥', '陈皮普洱', '红豆汤'],
    acupoint: ['足三里', '阴陵泉', '三阴交'],
    exercise: ['八段锦', '室内瑜伽', '慢走'],
    emotion: ['避免忧郁', '保持乐观心态'],
  ),
  SolarTermInfo(
    name: '惊蛰',
    date: '三月五日',
    month: 3,
    day: 5,
    season: 'spring',
    emoji: '🐛',
    poem: '惊蛰到，春雷响，万物长',
    diet: ['蜂蜜水', '菊花枸杞茶', '菠菜春笋'],
    acupoint: ['足三里', '太冲穴', '合谷穴'],
    exercise: ['八段锦', '户外散步', '拉伸运动'],
    emotion: ['舒展身心', '与自然亲近'],
  ),
  SolarTermInfo(
    name: '春分',
    date: '三月二十日',
    month: 3,
    day: 20,
    season: 'spring',
    emoji: '🌸',
    poem: '春分昼夜平，养生贵在衡',
    diet: ['荠菜豆腐汤', '香椿炒蛋', '红枣枸杞粥'],
    acupoint: ['百会穴', '涌泉穴', '三阴交'],
    exercise: ['踏青', '放风筝', '太极拳'],
    emotion: ['平和心态', '情绪稳定'],
  ),
  SolarTermInfo(
    name: '清明',
    date: '四月四日',
    month: 4,
    day: 4,
    season: 'spring',
    emoji: '🌿',
    poem: '清明时节雨纷纷，路上行人欲断魂',
    diet: ['荠菜馄饨', '龙井茶', '春韭炒蛋'],
    acupoint: ['太冲穴', '期门穴', '足三里'],
    exercise: ['踏青', '放风筝', '慢跑'],
    emotion: ['缅怀追思', '珍惜当下'],
  ),
  SolarTermInfo(
    name: '谷雨',
    date: '四月二十日',
    month: 4,
    day: 20,
    season: 'spring',
    emoji: '🌾',
    poem: '雨生百谷春将尽，养肝健脾正当期',
    diet: ['香椿拌豆腐', '谷雨茶', '山药莲子粥'],
    acupoint: ['足三里', '脾俞穴', '中脘穴'],
    exercise: ['慢跑', '太极拳', '登山'],
    emotion: ['防过敏焦虑', '保持心情开朗'],
  ),
  SolarTermInfo(
    name: '立夏',
    date: '五月六日',
    month: 5,
    day: 6,
    season: 'summer',
    emoji: '☀️',
    poem: '立夏荷风送暖香，养心安神度清凉',
    diet: ['绿豆汤', '酸梅汤', '苦瓜炒蛋'],
    acupoint: ['内关穴', '神门穴', '心俞穴'],
    exercise: ['晨练', '游泳', '散步'],
    emotion: ['静心安神', '戒躁戒怒'],
  ),
  SolarTermInfo(
    name: '小满',
    date: '五月二十一日',
    month: 5,
    day: 21,
    season: 'summer',
    emoji: '🌻',
    poem: '小满不满麦渐黄，清热利湿保安康',
    diet: ['冬瓜薏米汤', '莲子羹', '荷叶粥'],
    acupoint: ['阴陵泉', '足三里', '三阴交'],
    exercise: ['散步', '瑜伽', '太极'],
    emotion: ['淡泊明志', '宁静致远'],
  ),
  SolarTermInfo(
    name: '芒种',
    date: '六月六日',
    month: 6,
    day: 6,
    season: 'summer',
    emoji: '🌾',
    poem: '芒种忙种不忙收，清热化湿记心头',
    diet: ['酸梅汤', '绿豆百合粥', '西瓜'],
    acupoint: ['曲池穴', '合谷穴', '大椎穴'],
    exercise: ['游泳', '太极拳', '晨间慢跑'],
    emotion: ['保持心静', '避免烦躁'],
  ),
  SolarTermInfo(
    name: '夏至',
    date: '六月二十一日',
    month: 6,
    day: 21,
    season: 'summer',
    emoji: '🔆',
    poem: '夏至日长夜最短，养阴护阳勿贪凉',
    diet: ['苦瓜排骨汤', '薄荷茶', '冬瓜虾皮汤'],
    acupoint: ['百会穴', '涌泉穴', '太溪穴'],
    exercise: ['晨练', '游泳', '傍晚散步'],
    emotion: ['心静自然凉', '保持平和'],
  ),
  SolarTermInfo(
    name: '小暑',
    date: '七月七日',
    month: 7,
    day: 7,
    season: 'summer',
    emoji: '🌡️',
    poem: '小暑温风至，养心防暑气',
    diet: ['莲藕排骨汤', '金银花茶', '荷叶粥'],
    acupoint: ['内关穴', '神门穴', '太冲穴'],
    exercise: ['晨练', '傍晚散步', '室内瑜伽'],
    emotion: ['静心度夏', '避免情绪波动'],
  ),
  SolarTermInfo(
    name: '大暑',
    date: '七月二十二日',
    month: 7,
    day: 22,
    season: 'summer',
    emoji: '🔥',
    poem: '大暑炎炎热难挡，清热解暑保安康',
    diet: ['绿豆汤', '酸梅汤', '西瓜汁'],
    acupoint: ['曲池穴', '合谷穴', '足三里'],
    exercise: ['晨间运动', '游泳', '晚间散步'],
    emotion: ['心静自然凉', '少思少虑'],
  ),
  SolarTermInfo(
    name: '立秋',
    date: '八月七日',
    month: 8,
    day: 7,
    season: 'autumn',
    emoji: '🍂',
    poem: '立秋凉风至，滋阴润肺时',
    diet: ['银耳雪梨羹', '蜂蜜柚子茶', '百合粥'],
    acupoint: ['肺俞穴', '太渊穴', '列缺穴'],
    exercise: ['慢跑', '登山', '太极拳'],
    emotion: ['收敛精神', '安宁平和'],
  ),
  SolarTermInfo(
    name: '处暑',
    date: '八月二十三日',
    month: 8,
    day: 23,
    season: 'autumn',
    emoji: '🌤️',
    poem: '处暑秋意浓，润燥养阴功',
    diet: ['百合银耳羹', '罗汉果茶', '蜂蜜水'],
    acupoint: ['肺俞穴', '三阴交', '足三里'],
    exercise: ['太极拳', '慢跑', '散步'],
    emotion: ['宁静致远', '平和心态'],
  ),
  SolarTermInfo(
    name: '白露',
    date: '九月七日',
    month: 9,
    day: 7,
    season: 'autumn',
    emoji: '💧',
    poem: '白露秋分夜，一夜凉一夜',
    diet: ['桂花糯米藕', '百合茶', '梨膏糖'],
    acupoint: ['太渊穴', '肺俞穴', '足三里'],
    exercise: ['晨跑', '太极', '登山'],
    emotion: ['注意保暖', '保持乐观'],
  ),
  SolarTermInfo(
    name: '秋分',
    date: '九月二十三日',
    month: 9,
    day: 23,
    season: 'autumn',
    emoji: '🌙',
    poem: '秋分阴阳半，调和身心安',
    diet: ['山药百合粥', '菊花枸杞茶', '桂花糕'],
    acupoint: ['百会穴', '涌泉穴', '三阴交'],
    exercise: ['散步', '瑜伽', '太极'],
    emotion: ['平衡情绪', '知足常乐'],
  ),
  SolarTermInfo(
    name: '寒露',
    date: '十月八日',
    month: 10,
    day: 8,
    season: 'autumn',
    emoji: '🍁',
    poem: '寒露凝霜降，温润防寒凉',
    diet: ['芝麻核桃粥', '红枣桂圆茶', '冰糖雪梨'],
    acupoint: ['肾俞穴', '太溪穴', '足三里'],
    exercise: ['慢跑', '登山', '太极'],
    emotion: ['收敛神气', '避免悲伤'],
  ),
  SolarTermInfo(
    name: '霜降',
    date: '十月二十三日',
    month: 10,
    day: 23,
    season: 'autumn',
    emoji: '❄️',
    poem: '霜降气肃凝，温补气血盈',
    diet: ['柿子', '栗子炖鸡', '姜枣茶'],
    acupoint: ['关元穴', '命门穴', '足三里'],
    exercise: ['太极', '慢跑', '室内运动'],
    emotion: ['养生收藏', '精神内守'],
  ),
  SolarTermInfo(
    name: '立冬',
    date: '十一月七日',
    month: 11,
    day: 7,
    season: 'winter',
    emoji: '🌡️',
    poem: '立冬万物藏，温补养肾方',
    diet: ['羊肉萝卜汤', '核桃黑芝麻糊', '红枣枸杞茶'],
    acupoint: ['关元穴', '肾俞穴', '命门穴'],
    exercise: ['八段锦', '室内运动', '慢走'],
    emotion: ['养藏精气', '静养心神'],
  ),
  SolarTermInfo(
    name: '小雪',
    date: '十一月二十二日',
    month: 11,
    day: 22,
    season: 'winter',
    emoji: '🌨️',
    poem: '小雪天地寒，温阳散寒暖',
    diet: ['牛肉炖萝卜', '姜枣茶', '桂圆红枣粥'],
    acupoint: ['气海穴', '关元穴', '足三里'],
    exercise: ['室内瑜伽', '八段锦', '太极'],
    emotion: ['保暖防寒', '保持心情愉悦'],
  ),
  SolarTermInfo(
    name: '大雪',
    date: '十二月七日',
    month: 12,
    day: 7,
    season: 'winter',
    emoji: '⛄',
    poem: '大雪纷飞天地寒，温补助阳养精全',
    diet: ['羊肉汤', '当归鸡', '核桃红枣粥'],
    acupoint: ['命门穴', '肾俞穴', '气海穴'],
    exercise: ['室内运动', '太极', '八段锦'],
    emotion: ['闭藏养神', '少思寡欲'],
  ),
  SolarTermInfo(
    name: '冬至',
    date: '十二月二十二日',
    month: 12,
    day: 22,
    season: 'winter',
    emoji: '❄️',
    poem: '冬至一阳生，阴极阳动兴',
    diet: ['饺子', '羊肉汤', '八宝粥'],
    acupoint: ['关元穴', '命门穴', '太溪穴'],
    exercise: ['散步', '八段锦', '室内太极'],
    emotion: ['养藏精气', '安神定志'],
  ),
  SolarTermInfo(
    name: '小寒',
    date: '一月五日',
    month: 1,
    day: 5,
    season: 'winter',
    emoji: '🧊',
    poem: '小寒冷气积，温阳散寒宜',
    diet: ['羊肉火锅', '桂圆红枣汤', '当归红茶'],
    acupoint: ['肾俞穴', '命门穴', '足三里'],
    exercise: ['室内运动', '太极', '八段锦'],
    emotion: ['保暖护阳', '心态平和'],
  ),
  SolarTermInfo(
    name: '大寒',
    date: '一月二十日',
    month: 1,
    day: 20,
    season: 'winter',
    emoji: '🧣',
    poem: '大寒到顶点，春来在眼前',
    diet: ['八宝饭', '腊八粥', '姜枣茶'],
    acupoint: ['关元穴', '气海穴', '肾俞穴'],
    exercise: ['室内太极', '八段锦', '慢走'],
    emotion: ['蓄势待发', '迎接新春'],
  ),
];

// ── 按农历顺序排列的索引（立春→大寒） ─────────────────

/// 返回按时间顺序（立春→大寒）排列的24节气
List<SolarTermInfo> _getOrderedTerms() {
  return _kAllSolarTerms;
}

// ── 计算当前节气 ────────────────────────────────────────

SolarTermInfo _getCurrentSolarTerm() {
  final now = DateTime.now();
  final terms = _getOrderedTerms();
  // 按月份+日期排序找到最近的节气
  int currentIndex = 0;
  // 逻辑顺序: 2月立春开始
  // 简化判断：用月份区间
  final m = now.month;
  final d = now.day;

  // 各节气的大致起始日期（月, 日）
  const termDates = [
    (2, 4), (2, 19), (3, 5), (3, 20), // 春
    (4, 4), (4, 20), (5, 6), (5, 21), // 初夏
    (6, 6), (6, 21), (7, 7), (7, 22), // 盛夏
    (8, 7), (8, 23), (9, 7), (9, 23), // 秋
    (10, 8), (10, 23), (11, 7), (11, 22), // 深秋
    (12, 7), (12, 22), (1, 5), (1, 20), // 冬
  ];

  // 从小寒(22)和大寒(23)开始处理年初
  // 找到当前日期所在的节气区间
  for (int i = termDates.length - 1; i >= 0; i--) {
    final (tm, td) = termDates[i];
    // 小寒/大寒在1月，需要特殊处理
    if (tm == 1 && m >= 1 && (m > 1 || d >= td)) {
      currentIndex = i;
      break;
    }
    if (tm == 1) continue;
    if (m > tm || (m == tm && d >= td)) {
      currentIndex = i;
      break;
    }
  }

  return terms[currentIndex];
}

// ── 主页面 ──────────────────────────────────────────────

class SolarTermPage extends ConsumerStatefulWidget {
  const SolarTermPage({super.key});

  @override
  ConsumerState<SolarTermPage> createState() => _SolarTermPageState();
}

class _SolarTermPageState extends ConsumerState<SolarTermPage> {
  late SolarTermInfo _currentTerm;
  final List<SolarTermInfo> _allTerms = _getOrderedTerms();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSolarTerms();
  }

  /// 尝试从API加载，失败则用mock数据
  Future<void> _loadSolarTerms() async {
    try {
      final response = await ApiClient().get('/api/v1/solar-terms/current');
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true && data['data'] is Map<String, dynamic>) {
        final termData = data['data'] as Map<String, dynamic>;
        final name = termData['name'] as String? ?? '';
        // 从mock列表中找到匹配的节气
        final match = _allTerms.where((t) => t.name == name).firstOrNull;
        if (match != null && mounted) {
          setState(() {
            _currentTerm = match;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {
      // API失败，使用本地mock数据
    }
    setState(() {
      _currentTerm = _getCurrentSolarTerm();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: ShunshiColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ShunshiColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 1. 顶部节气大卡片
            _CurrentTermCard(term: _currentTerm),

            // 2. 节气养生建议
            _WellnessAdvice(term: _currentTerm),

            // 4. 24节气时间线
            _SolarTermTimeline(
              allTerms: _allTerms,
              currentIndex: _allTerms.indexOf(_currentTerm),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── 1. 顶部节气大卡片 ────────────────────────────────────

class _CurrentTermCard extends StatelessWidget {
  final SolarTermInfo term;

  const _CurrentTermCard({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B9E7E),
            Color(0xFF6B7E5E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B9E7E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节气emoji + 名称
            Row(
              children: [
                Text(
                  term.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  '今日节气：${term.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 诗词
            Text(
              '「${term.poem}」',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const Spacer(),
            // 日期信息
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '2026年${term.date} · ${term.seasonLabel} · ${term.durationDays}天',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.75),
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

// ── 2. 个性化推荐内容区（横向滚动卡片） ─────────────────────

class _WellnessAdvice extends StatelessWidget {
  final SolarTermInfo term;

  const _WellnessAdvice({required this.term});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '养生建议',
            style: ShunshiTextStyles.heading,
          ),
          const SizedBox(height: 16),
          // 饮食宜忌
          _AdviceGroup(
            icon: '🍵',
            title: '饮食宜忌',
            items: term.diet,
            type: 'food_therapy',
          ),
          const SizedBox(height: 16),
          // 穴位调理
          _AdviceGroup(
            icon: '💆',
            title: '穴位调理',
            items: term.acupoint,
            type: 'acupoint',
          ),
          const SizedBox(height: 16),
          // 运动建议
          _AdviceGroup(
            icon: '🏃',
            title: '运动建议',
            items: term.exercise,
            type: 'exercise',
          ),
          const SizedBox(height: 16),
          // 情志调养
          _AdviceGroup(
            icon: '😊',
            title: '情志调养',
            items: term.emotion,
            type: 'emotion',
          ),
        ],
      ),
    );
  }
}

class _AdviceGroup extends StatelessWidget {
  final String icon;
  final String title;
  final List<String> items;
  final String type; // API type for navigation

  const _AdviceGroup({
    required this.icon,
    required this.title,
    required this.items,
    this.type = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunshiColors.surface,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        border: Border.all(color: ShunshiColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行 — 整行可点击跳分类详情
          GestureDetector(
            onTap: () {
              if (type.isNotEmpty) context.go('/wellness-category/$type');
            },
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: ShunshiTextStyles.heading.copyWith(fontSize: 15),
                ),
                if (type.isNotEmpty) ...[
                  const Spacer(),
                  Text('查看全部', style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.primary)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: ShunshiColors.primary),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 建议项
          ...items.map(
            (item) => GestureDetector(
              onTap: () {
                if (type.isNotEmpty) context.go('/wellness-category/$type');
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ShunshiColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: ShunshiTextStyles.body.copyWith(fontSize: 14),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 14, color: ShunshiColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. 24节气时间线 ──────────────────────────────────────

class _SolarTermTimeline extends StatelessWidget {
  final List<SolarTermInfo> allTerms;
  final int currentIndex;

  const _SolarTermTimeline({
    required this.allTerms,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 按季节分组，每组6个
    final seasons = <MapEntry<String, List<SolarTermInfo>>>[
      const MapEntry('春', []),
      const MapEntry('夏', []),
      const MapEntry('秋', []),
      const MapEntry('冬', []),
    ];

    for (final term in allTerms) {
      final idx = ['spring', 'summer', 'autumn', 'winter'].indexOf(term.season);
      if (idx >= 0 && idx < seasons.length) {
        seasons[idx] = MapEntry(
          seasons[idx].key,
          [...seasons[idx].value, term],
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '24节气时间线',
            style: ShunshiTextStyles.heading,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: seasons.map((season) {
                return _SeasonRow(
                  seasonLabel: season.key,
                  terms: season.value,
                  currentIndex: currentIndex,
                  allTerms: allTerms,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonRow extends StatelessWidget {
  final String seasonLabel;
  final List<SolarTermInfo> terms;
  final int currentIndex;
  final List<SolarTermInfo> allTerms;

  const _SeasonRow({
    required this.seasonLabel,
    required this.terms,
    required this.currentIndex,
    required this.allTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 季节标签
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              seasonLabel,
              style: ShunshiTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: ShunshiColors.primary,
              ),
            ),
          ),
          // 节气时间线
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 季节标签区域
                const SizedBox(width: 0),
                // 节气节点
                ...terms.asMap().entries.expand((entry) {
                  final index = entry.key;
                  final term = entry.value;
                  final globalIndex = allTerms.indexOf(term);
                  final isCurrent = globalIndex == currentIndex;
                  final isPast = globalIndex < currentIndex;

                  final dotColor = isCurrent
                      ? ShunshiColors.primary
                      : isPast
                          ? ShunshiColors.textHint
                          : ShunshiColors.primaryLight;

                  final textColor = isCurrent
                      ? ShunshiColors.primary
                      : isPast
                          ? ShunshiColors.textHint
                          : ShunshiColors.textSecondary;

                  return <Widget>[
                    // 连接线 + 节点 + 文字
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SolarTermDetailPage(
                              termName: term.name,
                              emoji: term.emoji,
                              season: term.season,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 圆点
                          Container(
                            width: isCurrent ? 14 : 10,
                            height: isCurrent ? 14 : 10,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(
                                      color: ShunshiColors.primary,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: ShunshiColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 节气名
                          SizedBox(
                            width: 48,
                            child: Text(
                              term.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isCurrent ? FontWeight.w600 : FontWeight.w400,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 连接线（最后一个不加）
                    if (index < terms.length - 1)
                      Container(
                        width: 24,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isPast
                              ? ShunshiColors.divider
                              : ShunshiColors.primaryLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ];
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
