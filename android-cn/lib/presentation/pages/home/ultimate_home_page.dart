/// 首页（今日页）— 升级版 UI v2
/// 设计: 水墨宣纸风格 + 毛玻璃 AI 模块 + Staggered Animation
/// 结构: TopBar → 时辰大标题 → Hero养生图 → Bento行动建议 → AI助手 → 今日推荐 → CTA
library;

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import 'package:go_router/go_router.dart';
import 'widgets/home_skeleton.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/cache_service.dart';
import '../../../data/storage/storage_manager.dart';

// ═══════════════════════════════════════════════════════════════
// 十二时辰数据模型（本地计算）
// ═══════════════════════════════════════════════════════════════

class ShiChenData {
  final String name;
  final String timeRange;
  final String meridian;
  final String principle;       // 如 "万籁俱寂·养胆气"
  final String principleShort;  // 如 "养胆气" (用于标题)
  final String wellnessPrinciple; // 养生精要 如 "滋阴补肾，清热降火"
  final String aiQuote;         // AI引言
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

const _shiChenList = <ShiChenData>[
  ShiChenData(
    name: '子时', timeRange: '23-1', meridian: '胆经',
    principle: '万籁俱寂', principleShort: '养胆气',
    wellnessPrinciple: '安神定志，温养胆气',
    aiQuote: '子时是人体阳气初生的时刻，万物归寂。此时应熟睡，让胆经得以修复，为明日精力储备打下根基。',
    icon: Icons.dark_mode,
    actions: [
      BentoAction(icon: Icons.nightlight_round, title: '熟睡养胆', description: '子时深睡可助胆汁新陈代谢，完成夜间修复。'),
      BentoAction(icon: Icons.air, title: '静卧养神', description: '保持安静，不扰动阳气初生，宜右侧卧。'),
    ],
  ),
  ShiChenData(
    name: '丑时', timeRange: '1-3', meridian: '肝经',
    principle: '肝血归藏', principleShort: '养肝阴',
    wellnessPrinciple: '养血柔肝，滋阴润燥',
    aiQuote: '丑时肝经活跃，是肝脏解毒和藏血的关键时段。深度睡眠能帮助肝脏完成代谢修复，让面色红润。',
    icon: Icons.night_shelter,
    actions: [
      BentoAction(icon: Icons.bedtime, title: '深度睡眠', description: '丑时肝经当令，深度睡眠养肝血。'),
      BentoAction(icon: Icons.local_florist, title: '养肝护肝', description: '避免熬夜，让肝脏充分休息排毒。'),
    ],
  ),
  ShiChenData(
    name: '寅时', timeRange: '3-5', meridian: '肺经',
    principle: '气血布散', principleShort: '养肺气',
    wellnessPrinciple: '润肺益气，调和营卫',
    aiQuote: '寅时是肺经输布气血的时刻，全身经络得以濡养。此时应安睡，让肺脏将气血分配到全身。',
    icon: Icons.cloud,
    actions: [
      BentoAction(icon: Icons.air, title: '深呼吸养肺', description: '寅时肺经当令，宜保持深长呼吸。'),
      BentoAction(icon: Icons.spa, title: '安睡养气', description: '让肺脏完成气血分配，莫要惊醒。'),
    ],
  ),
  ShiChenData(
    name: '卯时', timeRange: '5-7', meridian: '大肠经',
    principle: '天明排便', principleShort: '通肠腑',
    wellnessPrinciple: '润肠通便，清理积滞',
    aiQuote: '卯时大肠经当令，是排便的最佳时机。晨起喝一杯温水，配合轻度活动，帮助身体排毒焕新。',
    icon: Icons.light_mode,
    actions: [
      BentoAction(icon: Icons.water_drop, title: '晨起温水', description: '一杯温水唤醒肠胃，促进排便排毒。'),
      BentoAction(icon: Icons.directions_walk, title: '晨起活动', description: '轻度活动促进肠蠕动，通调腑气。'),
    ],
  ),
  ShiChenData(
    name: '辰时', timeRange: '7-9', meridian: '胃经',
    principle: '朝食养胃', principleShort: '补气血',
    wellnessPrinciple: '温胃健脾，补中益气',
    aiQuote: '辰时胃经最旺，是吃早餐的黄金时间。温热、营养的早餐能为一整天提供充足能量，滋养气血。',
    icon: Icons.breakfast_dining,
    actions: [
      BentoAction(icon: Icons.rice_bowl, title: '温热早餐', description: '吃温热、易消化的早餐养胃气。'),
      BentoAction(icon: Icons.local_cafe, title: '姜枣茶饮', description: '生姜红枣泡水暖胃驱寒，调和脾胃。'),
    ],
  ),
  ShiChenData(
    name: '巳时', timeRange: '9-11', meridian: '脾经',
    principle: '运化水谷', principleShort: '健脾土',
    wellnessPrinciple: '健脾益气，运化水湿',
    aiQuote: '巳时脾经当令，消化吸收最佳时段。此时精力旺盛，适合高效工作。脾为后天之本，宜细嚼慢咽。',
    icon: Icons.psychology,
    actions: [
      BentoAction(icon: Icons.work, title: '高效工作', description: '巳时精力充沛，适合处理重要事务。'),
      BentoAction(icon: Icons.emoji_food_beverage, title: '健脾茶饮', description: '陈皮普洱健脾理气，助消化。'),
    ],
  ),
  ShiChenData(
    name: '午时', timeRange: '11-13', meridian: '心经',
    principle: '日中养心', principleShort: '调阴阳',
    wellnessPrinciple: '养心安神，交通心肾',
    aiQuote: '午时心经最旺，阴阳交替之际。午餐后小憩片刻，有助于养心安神，下午更有精力应对万事。',
    icon: Icons.wb_sunny,
    actions: [
      BentoAction(icon: Icons.hotel, title: '午间小憩', description: '午时小睡15-30分钟养心安神。'),
      BentoAction(icon: Icons.favorite, title: '养心静坐', description: '闭目静坐调养心神，平复心火。'),
    ],
  ),
  ShiChenData(
    name: '未时', timeRange: '13-15', meridian: '小肠经',
    principle: '分清泌浊', principleShort: '利消化',
    wellnessPrinciple: '清心导浊，调和肠胃',
    aiQuote: '未时小肠经活跃，负责将食物精华吸收、糟粕排出。适度活动和补充水分有助于消化吸收。',
    icon: Icons.filter_alt,
    actions: [
      BentoAction(icon: Icons.directions_walk, title: '午后散步', description: '轻度活动帮助消化吸收，促进运化。'),
      BentoAction(icon: Icons.water_drop, title: '补充水分', description: '未时宜多喝水促进代谢排毒。'),
    ],
  ),
  ShiChenData(
    name: '申时', timeRange: '15-17', meridian: '膀胱经',
    principle: '排毒利水', principleShort: '泻火气',
    wellnessPrinciple: '通利水道，清热解毒',
    aiQuote: '申时膀胱经最活跃，是排毒的好时机。多喝水、适度运动出汗，帮助身体排出代谢废物，神清气爽。',
    icon: Icons.wb_cloudy,
    actions: [
      BentoAction(icon: Icons.directions_run, title: '适度运动', description: '申时体能较好，适合运动排汗排毒。'),
      BentoAction(icon: Icons.water_drop, title: '多饮温水', description: '促进膀胱经排毒，利尿消肿。'),
    ],
  ),
  ShiChenData(
    name: '酉时', timeRange: '17-19', meridian: '肾经',
    principle: '藏精纳气', principleShort: '养肾元',
    wellnessPrinciple: '滋阴补肾，清热降火',
    aiQuote: '酉时肾经当令，是储藏精华的时刻。最宜收敛心神，让身体在安静中完成一次深度的自我修复。',
    icon: Icons.auto_awesome,
    actions: [
      BentoAction(icon: Icons.water_drop, title: '补充水分', description: '酉时肾脏排毒最为旺盛，适量饮用温水辅助代谢。'),
      BentoAction(icon: Icons.accessibility_new, title: '轻拍足跟', description: '足少阴肾经起于足底，轻拍足跟激发肾经经气。'),
    ],
  ),
  ShiChenData(
    name: '戌时', timeRange: '19-21', meridian: '心包经',
    principle: '护心减压', principleShort: '畅情志',
    wellnessPrinciple: '宽胸理气，疏解郁结',
    aiQuote: '戌时心包经当令，是护心减压的时刻。适合休闲娱乐、与家人交流，让心情愉悦放松，心胸开阔。',
    icon: Icons.music_note,
    actions: [
      BentoAction(icon: Icons.music_note, title: '听音乐放松', description: '戌时宜放松心情，舒缓一天的压力。'),
      BentoAction(icon: Icons.local_cafe, title: '花茶安神', description: '玫瑰花茶疏肝理气，宁心安神。'),
    ],
  ),
  ShiChenData(
    name: '亥时', timeRange: '21-23', meridian: '三焦经',
    principle: '百脉通调', principleShort: '备入眠',
    wellnessPrinciple: '通调三焦，安神助眠',
    aiQuote: '亥时三焦经当令，是百脉通调的时刻。温水泡脚、静心阅读，放下全日奔忙，为优质睡眠做最后准备。',
    icon: Icons.nights_stay,
    actions: [
      BentoAction(icon: Icons.spa, title: '温水泡脚', description: '亥时泡脚引火归元助眠，温通经络。'),
      BentoAction(icon: Icons.menu_book, title: '静心阅读', description: '放下手机，静心准备入睡，养百脉。'),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════
// 节气名称映射（根据月份大致推算）
// ═══════════════════════════════════════════════════════════════

String _getCurrentSolarTermInfo() {
  final now = DateTime.now();
  final month = now.month;
  final day = now.day;
  const terms = [
    (1, 6, '小寒', '季冬'), (1, 20, '大寒', '季冬'),
    (2, 4, '立春', '孟春'), (2, 19, '雨水', '孟春'),
    (3, 6, '惊蛰', '仲春'), (3, 21, '春分', '仲春'),
    (4, 5, '清明', '季春'), (4, 20, '谷雨', '季春'),
    (5, 6, '立夏', '孟夏'), (5, 21, '小满', '孟夏'),
    (6, 6, '芒种', '仲夏'), (6, 21, '夏至', '仲夏'),
    (7, 7, '小暑', '季夏'), (7, 23, '大暑', '季夏'),
    (8, 7, '立秋', '孟秋'), (8, 23, '处暑', '孟秋'),
    (9, 8, '白露', '仲秋'), (9, 23, '秋分', '仲秋'),
    (10, 8, '寒露', '季秋'), (10, 23, '霜降', '季秋'),
    (11, 7, '立冬', '孟冬'), (11, 22, '小雪', '孟冬'),
    (12, 7, '大雪', '仲冬'), (12, 22, '冬至', '仲冬'),
  ];
  String termName = '清明';
  String season = '季春';
  for (final t in terms) {
    if (month < t.$1 || (month == t.$1 && day < t.$2)) break;
    termName = t.$3;
    season = t.$4;
  }
  return '$termName · $season之节';
}

// ═══════════════════════════════════════════════════════════════
// 今日推荐数据
// ═══════════════════════════════════════════════════════════════

class TodayRecommendation {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final Color accentColor;
  final String? route; // navigation route
  final String? imageAsset; // AI-generated image

  const TodayRecommendation({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accentColor,
    this.route,
    this.imageAsset,
  });

  factory TodayRecommendation.fromApi(Map<String, dynamic> json, bool isDark) {
    final tag = json['category']?.toString() ?? json['type']?.toString() ?? '推荐';
    final accentColor = _accentForTag(tag);
    return TodayRecommendation(
      icon: _iconForTag(tag),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '推荐',
      subtitle: json['description']?.toString() ?? json['subtitle']?.toString() ?? '',
      tag: tag,
      accentColor: accentColor,
      route: _routeForTag(tag),
    );
  }

  static Color _accentForTag(String tag) {
    switch (tag) {
      case '食物': case '饮食': case '食疗': return ShunShiColors.apricot;
      case '茶饮': case '茶': return ShunShiColors.warm;
      case '运动': case '锻炼': return ShunShiColors.primaryLight;
      case '养生': case '穴位': return ShunShiColors.calm;
      default: return ShunShiColors.secondary;
    }
  }

  static IconData _iconForTag(String tag) {
    switch (tag) {
      case '食物': case '饮食': case '食疗': return Icons.rice_bowl;
      case '茶饮': case '茶': return Icons.local_cafe;
      case '运动': case '锻炼': return Icons.directions_walk;
      case '养生': case '穴位': return Icons.spa;
      default: return Icons.auto_awesome;
    }
  }

  static String? _routeForTag(String tag) {
    switch (tag) {
      case '食物': case '饮食': case '食疗': return '/diet-recommend';
      case '茶饮': case '茶': return '/tea';
      case '运动': case '锻炼': return '/exercise-detail';
      default: return null;
    }
  }
}

List<TodayRecommendation> _getTodayRecommendations(ShiChenData sc) {
  // 根据时辰给出不同推荐
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) {
    return const [
      TodayRecommendation(icon: Icons.rice_bowl, title: '小米山药粥', subtitle: '温补脾胃，晨起首选', tag: '食物', accentColor: ShunShiColors.apricot, imageAsset: 'assets/images/morning_tea.jpg'),
      TodayRecommendation(icon: Icons.local_cafe, title: '陈皮普洱茶', subtitle: '理气健脾，助消化', tag: '茶饮', accentColor: ShunShiColors.warm, imageAsset: 'assets/images/herbal_soup.jpg'),
      TodayRecommendation(icon: Icons.self_improvement, title: '八段锦晨练', subtitle: '舒展筋骨，调和气血', tag: '运动', accentColor: ShunShiColors.primaryLight, imageAsset: 'assets/images/breathing.jpg'),
      TodayRecommendation(icon: Icons.spa, title: '穴位按压', subtitle: '足三里·健脾胃', tag: '养生', accentColor: ShunShiColors.calm, imageAsset: 'assets/images/evening_yoga.jpg'),
    ];
  } else if (hour >= 11 && hour < 17) {
    return const [
      TodayRecommendation(icon: Icons.set_meal, title: '莲子百合汤', subtitle: '清心安神，午间滋养', tag: '食物', accentColor: ShunShiColors.apricot, imageAsset: 'assets/images/herbal_soup.jpg'),
      TodayRecommendation(icon: Icons.emoji_food_beverage, title: '菊花枸杞茶', subtitle: '清肝明目，下午提神', tag: '茶饮', accentColor: ShunShiColors.warm, imageAsset: 'assets/images/seasonal_fruit.jpg'),
      TodayRecommendation(icon: Icons.directions_walk, title: '午后散步', subtitle: '消食化积，通调腑气', tag: '运动', accentColor: ShunShiColors.primaryLight, imageAsset: 'assets/images/breathing.jpg'),
      TodayRecommendation(icon: Icons.nights_stay, title: '静坐冥想', subtitle: '收敛心神，养心安神', tag: '养生', accentColor: ShunShiColors.calm, imageAsset: 'assets/images/meditation.jpg'),
    ];
  } else {
    return const [
      TodayRecommendation(icon: Icons.soup_kitchen, title: '银耳红枣羹', subtitle: '滋阴润燥，晚间养颜', tag: '食物', accentColor: ShunShiColors.apricot, imageAsset: 'assets/images/herbal_soup.jpg'),
      TodayRecommendation(icon: Icons.local_cafe, title: '玫瑰花茶', subtitle: '疏肝理气，宁心安神', tag: '茶饮', accentColor: ShunShiColors.warm, imageAsset: 'assets/images/bedtime_tea.jpg'),
      TodayRecommendation(icon: Icons.hot_tub, title: '温水泡脚', subtitle: '引火归元，助眠安神', tag: '运动', accentColor: ShunShiColors.primaryLight, imageAsset: 'assets/images/evening_yoga.jpg'),
      TodayRecommendation(icon: Icons.menu_book, title: '静心阅读', subtitle: '放下手机，养百脉', tag: '养生', accentColor: ShunShiColors.calm, imageAsset: 'assets/images/bedtime_tea.jpg'),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════
// 首页 Widget
// ═══════════════════════════════════════════════════════════════

class UltimateHomePage extends StatefulWidget {
  const UltimateHomePage({super.key});

  @override
  State<UltimateHomePage> createState() => _UltimateHomePageState();
}

class _UltimateHomePageState extends State<UltimateHomePage>
    with TickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  final _api = ApiClient();
  final _cache = CacheService();

  late ShiChenData _currentShiChen;
  String _solarTermInfo = '';
  String _dailyInsight = '';
  // ignore: unused_field
  List<Map<String, dynamic>> _apiSuggestions = [];
  bool _loading = true;

  Map<String, dynamic> _followUp = {};
  bool _hasFollowUp = false;
  List<TodayRecommendation> _todayRecs = [];

  // ── Animation controllers ──
  late AnimationController _breathController;  // 节气胶囊呼吸
  late AnimationController _pulseController;   // AI 脉冲光点
  late AnimationController _shimmerController; // 经络图 shimmer
  late List<AnimationController> _staggerControllers; // 各区块入场

  @override
  void initState() {
    super.initState();
    _currentShiChen = getCurrentShiChen();
    _solarTermInfo = _getCurrentSolarTermInfo();

    // 呼吸动画 (节气胶囊)
    _breathController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // AI 脉冲光点
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Shimmer 效果
    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Staggered 入场 (7 sections)
    _staggerControllers = List.generate(7, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: 100 + i * 120), () {
        if (mounted) c.forward();
      });
      return c;
    });

    _fetchDashboard();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    for (final c in _staggerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    try {
      final cached = _cache.get<Map<String, dynamic>>(
        CacheKeys.today(),
        config: CacheConfig.today,
      );
      if (cached != null && mounted) {
        _applyData(cached.data);
        setState(() => _loading = false);
      }
    } catch (_) {}

    try {
      final results = await Future.wait([
        _api.get('/seasons/home/dashboard', queryParameters: {'locale': 'zh-CN'}, level: SpeedLevel.s1),
        _api.get('/solar-terms/current', level: SpeedLevel.s1),
        _api.get('/followup/due', queryParameters: {'user_id': 'user-001', 'limit': 1}, level: SpeedLevel.s0),
      ]);

      if (!mounted) return;

      final dash = results[0].data;
      if (dash is Map) {
        await _cache.set(CacheKeys.today(), Map<String, dynamic>.from(dash), config: CacheConfig.today);
        _applyData(Map<String, dynamic>.from(dash));
      }

      final solar = results[1].data;
      if (solar is Map) {
        // Could enhance solar term info from API
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

    // Fetch personalized recommendations (non-blocking)
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final token = StorageManager.user.getToken();
      final endpoint = token != null && token.isNotEmpty
          ? '/recommend/personalized'
          : '/contents/recommend';
      final res = await _api.get(endpoint, queryParameters: {'limit': 6}, level: SpeedLevel.s1);
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['items'] is List) {
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        if (items.isNotEmpty) {
          setState(() {
            _todayRecs = items.map((item) => TodayRecommendation.fromApi(item, isDark)).toList();
          });
          return;
        }
      }
      if (data is List && data.isNotEmpty) {
        final items = data.cast<Map<String, dynamic>>();
        setState(() {
          _todayRecs = items.map((item) => TodayRecommendation.fromApi(item, isDark)).toList();
        });
      }
    } catch (_) {
      // Keep fallback recommendations
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

  // ── Staggered slide+fade wrapper ──
  Widget _staggerWrap(int index, Widget child) {
    if (index >= _staggerControllers.length) return child;
    final controller = _staggerControllers[index];
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    final fadeAnimation = Tween<double>(
      begin: 0.0, end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Opacity(
        opacity: fadeAnimation.value,
        child: Transform.translate(
          offset: Offset(0, slideAnimation.value.dy * 30),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sc = _currentShiChen;
    final timeDisplay = '${sc.timeRange.replaceAll('-', ':00 - ')}:00';
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    if (_loading) return const HomeSkeleton();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: ShunShiColors.primary,
          backgroundColor: isDark ? ShunShiColors.darkSurface : ShunShiColors.background,
          displacement: 40,
          strokeWidth: 2.5,
          onRefresh: _fetchDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ═══════════════ TopAppBar ═══════════════
              SliverToBoxAdapter(
                child: _staggerWrap(0, _buildTopBar(sc)),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ═══════════════ 时辰大标题 + 节气胶囊 ═══════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _staggerWrap(1, _buildHeroTitle(sc, timeDisplay)),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ═══════════════ Hero 经络意境区 ═══════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _staggerWrap(2, _buildHeroImage(sc)),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ═══════════════ Bento 行动建议 ═══════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _staggerWrap(3, _buildBentoGrid(sc)),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ═══════════════ AI 助手模块 (毛玻璃) ═══════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _staggerWrap(4, _buildAIModule(sc)),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ═══════════════ 今日推荐 横向滚动 ═══════════════
              SliverToBoxAdapter(
                child: _staggerWrap(5, _buildTodayRecommendations(sc)),
              ),

              // ═══════════════ 今日洞察 (如有) ═══════════════
              if (_dailyInsight.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _staggerWrap(5, _buildDailyInsight()),
                  ),
                ),
              ],

              // ═══════════════ 顺时提醒 (如有) ═══════════════
              if (_hasFollowUp) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _staggerWrap(6, _buildFollowUpCard()),
                  ),
                ),
              ],

              // ═══════════════ CTA 按钮 ═══════════════
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _staggerWrap(6, _buildCTA()),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
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
          Row(children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu, size: 20, color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '顺时 ShunShi',
              style: ShunShiTypography.headlineSmall.copyWith(
                fontFamily: ShunShiTypography.serifFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
              ),
            ),
          ]),
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

  // ─── 时辰大标题 + 节气胶囊 (增强版) ───
  Widget _buildHeroTitle(ShiChenData sc, String timeDisplay) {
    final secondaryColor = isDark ? ShunShiColors.darkSecondary : ShunShiColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time range label
        Text(
          timeDisplay,
          style: ShunShiTypography.labelMedium.copyWith(
            color: secondaryColor,
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
              color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
            ),
            children: [
              TextSpan(text: '${sc.name} · '),
              TextSpan(
                text: '${sc.meridian}当令',
                style: TextStyle(color: secondaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── 渐变装饰线 ──
        Container(
          height: 3,
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                ShunShiColors.primary.withValues(alpha: 0.7),
                ShunShiColors.apricot.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── 节气胶囊 (呼吸动画) ──
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            final scale = 1.0 + _breathController.value * 0.03;
            final opacity = 0.85 + _breathController.value * 0.15;
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: GestureDetector(
                  onTap: () => context.push('/solar'),
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: secondaryColor.withValues(alpha: 0.15 + _breathController.value * 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: secondaryColor.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _solarTermInfo,
                        style: ShunShiTypography.caption.copyWith(
                          color: secondaryColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            );
          },
        ),
      ],
    );
  }

  // ─── Hero 经络意境区 (渐变色块+图标+shimmer) ───
  Widget _buildHeroImage(ShiChenData sc) {
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A2E1F).withValues(alpha: 0.95),
                    const Color(0xFF0F1A12).withValues(alpha: 0.98),
                    const Color(0xFF2A3D2E).withValues(alpha: 0.90),
                  ]
                : [
                    const Color(0xFF2A3D2E).withValues(alpha: 0.88),
                    const Color(0xFF1A2E1F).withValues(alpha: 0.95),
                    const Color(0xFF3D5A42).withValues(alpha: 0.82),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // ── 经络意境: 渐变色块 + 图标 ──
            // Top-left meridian icon cluster
            Positioned(
              left: 24, top: 28,
              child: _buildMeridianNode(
                icon: Icons.auto_awesome,
                label: sc.meridian,
                color: ShunShiColors.goldLight.withValues(alpha: 0.7),
                size: 40,
              ),
            ),
            // Center-right flowing gradient block
            Positioned(
              right: 20, top: 40,
              child: Container(
                width: 100, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ShunShiColors.apricot.withValues(alpha: 0.15),
                      ShunShiColors.warm.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Icon(Icons.spa, size: 28, color: ShunShiColors.apricot.withValues(alpha: 0.5)),
              ),
            ),
            // Bottom-left flowing element
            Positioned(
              left: 30, top: 100,
              child: Container(
                width: 70, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      ShunShiColors.primaryLight.withValues(alpha: 0.12),
                      ShunShiColors.calm.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Icon(Icons.water_drop, size: 22, color: ShunShiColors.calm.withValues(alpha: 0.4)),
              ),
            ),
            // Subtle meridian lines (decorative)
            ...List.generate(4, (i) {
              final rng = Random(i * 37 + sc.name.hashCode);
              return Positioned(
                left: rng.nextDouble() * 200 + 20,
                top: rng.nextDouble() * 180 + 20,
                child: Transform.rotate(
                  angle: (rng.nextDouble() - 0.5) * 0.8,
                  child: Container(
                    width: 50 + rng.nextDouble() * 80,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.06 + rng.nextDouble() * 0.04),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // ── Shimmer overlay ──
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final dx = _shimmerController.value * 1.5 - 0.25;
                return Positioned.fill(
                  child: ShaderMask(
                    blendMode: BlendMode.srcOver,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment(dx, -0.5),
                      end: Alignment(dx + 0.3, 0.5),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Container(color: Colors.white),
                  ),
                );
              },
            ),

            // Bottom gradient overlay
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.85),
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
                  color: bg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '养生精要 Wellness Principle',
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
      ),
    );
  }

  Widget _buildMeridianNode({
    required IconData icon,
    required String label,
    required Color color,
    double size = 36,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 16, height: size + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Icon(icon, size: size * 0.55, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: ShunShiTypography.caption.copyWith(
            color: color.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Bento 行动建议 (圆角20 + 微阴影 + press 反馈) ───
  Widget _buildBentoGrid(ShiChenData sc) {
    return Column(
      children: [
        for (int i = 0; i < sc.actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _buildBentoCard(sc.actions[i]),
        ],
      ],
    );
  }

  /// 根据 Bento action 标题推断路由
  String? _routeForAction(BentoAction action) {
    final t = action.title;
    if (t.contains('食') || t.contains('粥') || t.contains('茶') && t.contains('姜')) return '/diet-recommend';
    if (t.contains('运动') || t.contains('散步') || t.contains('晨练') || t.contains('跑') || t.contains('八段锦')) return '/exercise-detail';
    if (t.contains('茶') || t.contains('花茶') || t.contains('普洱') || t.contains('姜枣') || t.contains('陈皮') || t.contains('玫瑰') || t.contains('菊花')) return '/tea';
    if (t.contains('睡') || t.contains('静') || t.contains('冥想') || t.contains('泡脚') || t.contains('阅读') || t.contains('按压')) return null; // wellness — stay
    return null;
  }

  Widget _buildBentoCard(BentoAction action) {
    final route = _routeForAction(action);
    return _PressScale(
      onTap: route != null ? () => context.push(route) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, size: 24, color: isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary),
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
                      color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.description,
                    style: ShunShiTypography.bodySmall.copyWith(
                      height: 1.6,
                      color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI 助手模块 (毛玻璃 + 脉冲光点) ───
  Widget _buildAIModule(ShiChenData sc) {
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return GestureDetector(
      onTap: () => context.push('/chat'),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? ShunShiColors.darkSurface : ShunShiColors.surface).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI avatar with pulse
              SizedBox(
                width: 52, height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ── 脉冲光圈 ──
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseScale = 1.0 + _pulseController.value * 0.3;
                        final pulseOpacity = 0.3 - _pulseController.value * 0.3;
                        return Transform.scale(
                          scale: pulseScale,
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ShunShiColors.primaryLight.withValues(alpha: pulseOpacity),
                            ),
                          ),
                        );
                      },
                    ),
                    // Main avatar
                    Container(
                      width: 52, height: 52,
                      decoration: const BoxDecoration(
                        color: ShunShiColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    // Status dot
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: ShunShiColors.goldLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2.5),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '顺时 AI 助手',
                      style: ShunShiTypography.titleMedium.copyWith(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 16,
                        color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${sc.aiQuote}"',
                      style: ShunShiTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ─── 今日推荐 横向滚动 ───
  Widget _buildTodayRecommendations(ShiChenData sc) {
    final recs = _todayRecs.isNotEmpty ? _todayRecs : _getTodayRecommendations(sc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '今日推荐',
            style: ShunShiTypography.titleMedium.copyWith(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 18,
              color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: recs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final rec = recs[index];
              return _PressScale(
                onTap: rec.route != null ? () => context.push(rec.route!) : null,
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: rec.accentColor.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image or icon ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: rec.imageAsset != null
                              ? Image.asset(rec.imageAsset!, fit: BoxFit.cover)
                              : Container(
                                  decoration: BoxDecoration(
                                    color: rec.accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(rec.icon, size: 18, color: rec.accentColor),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rec.title,
                        style: ShunShiTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.subtitle,
                        style: ShunShiTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rec.accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rec.tag,
                          style: ShunShiTypography.caption.copyWith(
                            fontSize: 10,
                            color: rec.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ShunShiColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日洞察',
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
        borderRadius: BorderRadius.circular(20),
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
                Text('顺时提醒', style: ShunShiTypography.labelMedium.copyWith(
                  color: ShunShiColors.primary, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(
                  _followUp['title']?.toString() ?? _followUp['description']?.toString() ?? '',
                  style: ShunShiTypography.bodySmall.copyWith(
                    color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary, size: 18),
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
        label: const Text('查看完整时辰养生表'),
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

// ═══════════════════════════════════════════════════════════════
// Press Scale Feedback Widget
// ═══════════════════════════════════════════════════════════════

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
