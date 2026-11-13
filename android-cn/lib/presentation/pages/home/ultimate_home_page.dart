/// 首页（今日页）— 升级版 UI v2
/// 设计: 水墨宣纸风格 + 毛玻璃 AI 模块 + Staggered Animation
/// 结构: TopBar → 时辰大标题 → Hero养生图 → Bento行动建议 → AI助手 → 今日推荐 → CTA
library;

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import 'package:go_router/go_router.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/today_voice_bar.dart';
import 'widgets/personal_home_binding.dart';
import '../../widgets/personal_home_section.dart';
import '../../account/account_surface.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/cache_service.dart';
import '../../../core/time/domestic_clock.dart';
import 'elder_home_text.dart';
import 'home_clock.dart';
import 'home_recommend.dart';
import '../../widgets/personal_home_strings_zh.dart';

// ═══════════════════════════════════════════════════════════════
// 十二时辰数据模型（本地计算）
// ═══════════════════════════════════════════════════════════════

class ShiChenData {
  final String name;
  final String timeRange;
  final String meridian;
  final String principle;       // 这一时辰做什么，如 "该睡觉了"
  final String principleShort;  // 标题短句，如 "早点睡"
  final String wellnessPrinciple; // 卡片上的日常提醒，如 "把灯调暗，放下手机"
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
  final hour = domesticNow().hour;
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

// 十二个时辰只写休息和吃饭，孕期、哺乳期看到的也是这同一段话。
// 不写药效，不写经络或脏腑功能，不出现茶饮、草药名或剂量。
const _shiChenList = <ShiChenData>[
  ShiChenData(
    name: '子时', timeRange: '23-1', meridian: '深夜',
    principle: '该睡觉了', principleShort: '早点睡',
    wellnessPrinciple: '把灯调暗，放下手机',
    aiQuote: '这个点适合睡觉。把灯调暗，手机放远一点，好好睡一觉。',
    icon: Icons.dark_mode,
    actions: [
      BentoAction(icon: Icons.nightlight_round, title: '准备睡觉', description: '把灯调暗，躺下休息。'),
      BentoAction(icon: Icons.phone_disabled, title: '放下手机', description: '不再看屏幕，让自己慢慢睡着。'),
    ],
  ),
  ShiChenData(
    name: '丑时', timeRange: '1-3', meridian: '凌晨',
    principle: '继续睡觉', principleShort: '接着睡',
    wellnessPrinciple: '夜还很长，接着睡',
    aiQuote: '夜还很长。继续睡，明天再处理事情。',
    icon: Icons.night_shelter,
    actions: [
      BentoAction(icon: Icons.bedtime, title: '继续睡觉', description: '这个点还早，接着睡。'),
      BentoAction(icon: Icons.phone_disabled, title: '别看手机', description: '屏幕亮着容易醒，把手机扣过去。'),
    ],
  ),
  ShiChenData(
    name: '寅时', timeRange: '3-5', meridian: '黎明',
    principle: '再睡一会儿', principleShort: '再睡会',
    wellnessPrinciple: '天还没亮，可以再躺一会儿',
    aiQuote: '天还没亮。醒了也没关系，再躺一会儿，不必马上起床。',
    icon: Icons.cloud,
    actions: [
      BentoAction(icon: Icons.hotel, title: '接着躺着', description: '天没亮就再睡一会儿。'),
      BentoAction(icon: Icons.airline_seat_flat, title: '慢一点起', description: '要起床的话，先坐一会儿再下床。'),
    ],
  ),
  ShiChenData(
    name: '卯时', timeRange: '5-7', meridian: '清晨',
    principle: '起床喝水', principleShort: '喝温水',
    wellnessPrinciple: '起床后先喝一杯温水，再活动一下',
    aiQuote: '清晨起床后喝一杯温水，做几分钟舒展，给新的一天一个轻松的开始。',
    icon: Icons.light_mode,
    actions: [
      BentoAction(icon: Icons.water_drop, title: '喝杯温水', description: '起床后先喝一杯温水。'),
      BentoAction(icon: Icons.directions_walk, title: '起来走走', description: '在屋里走几步，伸个懒腰。'),
    ],
  ),
  ShiChenData(
    name: '辰时', timeRange: '7-9', meridian: '早上',
    principle: '吃早餐', principleShort: '吃早餐',
    wellnessPrinciple: '吃一顿温热、好消化的早餐',
    aiQuote: '这个点适合吃早餐。吃一顿温热、好消化的早餐，够上午用就好。',
    icon: Icons.breakfast_dining,
    actions: [
      BentoAction(icon: Icons.rice_bowl, title: '热粥面条', description: '可以吃热粥或热面条，坐下来吃完。'),
      BentoAction(icon: Icons.restaurant, title: '先吃再出门', description: '上午要出门的话，先把早餐吃上。'),
    ],
  ),
  ShiChenData(
    name: '巳时', timeRange: '9-11', meridian: '上午',
    principle: '慢慢吃午饭', principleShort: '慢慢吃',
    wellnessPrinciple: '午饭细嚼慢咽，吃完走一走',
    aiQuote: '上午适合把要紧的事做一做。午饭时慢慢吃，别吃太快。',
    icon: Icons.psychology,
    actions: [
      BentoAction(icon: Icons.work, title: '做手头事', description: '上午把要紧的事做一做。'),
      BentoAction(icon: Icons.directions_walk, title: '午饭慢吃', description: '细嚼慢咽，吃完出去走十分钟。'),
    ],
  ),
  ShiChenData(
    name: '午时', timeRange: '11-13', meridian: '中午',
    principle: '午饭后歇会儿', principleShort: '歇一会',
    wellnessPrinciple: '午饭后闭眼歇一会儿',
    aiQuote: '午饭后可以闭眼歇一会儿，下午会舒服一些。',
    icon: Icons.wb_sunny,
    actions: [
      BentoAction(icon: Icons.hotel, title: '闭眼歇歇', description: '午饭后把手机放下，闭眼歇一会儿。'),
      BentoAction(icon: Icons.self_improvement, title: '坐着休息', description: '找个地方坐一会儿，不必一直忙。'),
    ],
  ),
  ShiChenData(
    name: '未时', timeRange: '13-15', meridian: '午后',
    principle: '饭后走走', principleShort: '走一走',
    wellnessPrinciple: '午饭后走一走，小口喝点水',
    aiQuote: '午饭过后，出去走十分钟，回来小口喝点水。',
    icon: Icons.filter_alt,
    actions: [
      BentoAction(icon: Icons.directions_walk, title: '午后散步', description: '午饭后出去走十分钟。'),
      BentoAction(icon: Icons.water_drop, title: '补充水分', description: '午后记得小口多喝水。'),
    ],
  ),
  ShiChenData(
    name: '申时', timeRange: '15-17', meridian: '下午',
    principle: '起来活动', principleShort: '活动下',
    wellnessPrinciple: '起来走一走，喝点温水',
    aiQuote: '下午容易犯困，起身活动几分钟、喝点温水，精神会好一些。',
    icon: Icons.wb_cloudy,
    actions: [
      BentoAction(icon: Icons.directions_walk, title: '起来走走', description: '下午适合起来走一走。'),
      BentoAction(icon: Icons.water_drop, title: '喝点温水', description: '喝点温水，少吃太咸的。'),
    ],
  ),
  ShiChenData(
    name: '酉时', timeRange: '17-19', meridian: '傍晚',
    principle: '晚饭清淡', principleShort: '清淡饭',
    wellnessPrinciple: '晚饭清淡一点，别吃得太晚',
    aiQuote: '傍晚喝点温水，晚饭清淡一些，别吃得太晚。',
    icon: Icons.auto_awesome,
    actions: [
      BentoAction(icon: Icons.water_drop, title: '喝点温水', description: '晚饭前喝点温水。'),
      BentoAction(icon: Icons.restaurant, title: '晚饭清淡', description: '晚饭少油少盐，吃完可以坐一会儿。'),
    ],
  ),
  ShiChenData(
    name: '戌时', timeRange: '19-21', meridian: '晚上',
    principle: '放松一下', principleShort: '放松下',
    wellnessPrinciple: '听听音乐，和家里人说说话',
    aiQuote: '晚饭后适合歇下来。听听音乐，或者和家里人说说话。',
    icon: Icons.music_note,
    actions: [
      BentoAction(icon: Icons.music_note, title: '听听音乐', description: '放点喜欢的音乐，把一天放下。'),
      BentoAction(icon: Icons.visibility_off, title: '少看屏幕', description: '少刷手机，让眼睛歇一会儿。'),
    ],
  ),
  ShiChenData(
    name: '亥时', timeRange: '21-23', meridian: '夜间',
    principle: '准备睡觉', principleShort: '准备睡',
    wellnessPrinciple: '温水泡脚，然后放下手机',
    aiQuote: '睡前用温水泡泡脚，看一会儿书，然后放下手机准备睡。',
    icon: Icons.nights_stay,
    actions: [
      BentoAction(icon: Icons.spa, title: '温水泡脚', description: '睡前用温水泡泡脚，然后放下手机。'),
      BentoAction(icon: Icons.menu_book, title: '看看书', description: '放下手机，看一会儿书再睡。'),
    ],
  ),
];

String shiChenTimeDisplay(ShiChenData sc) => '${sc.timeRange.replaceAll('-', ':00 - ')}:00';

/// 大标题写时辰名和短句，不写经络。
String shiChenHeadline(ShiChenData sc) => '${sc.name} · ${sc.principleShort}';

String shiChenSpoken(ShiChenData sc, {required String timeDisplay, required String solarTerm}) =>
    '$timeDisplay。${sc.name}，${sc.principleShort}。$solarTerm。${sc.wellnessPrinciple}';

/// 首页时辰卡片上会念出来、写出来的句子。测试用它确认没有药效说法。
List<String> visibleHomeTimeOfDayCopy() {
  return [
    for (final sc in _shiChenList) ...[
      sc.name,
      sc.meridian,
      shiChenHeadline(sc),
      shiChenTimeDisplay(sc),
      sc.principle,
      sc.principleShort,
      sc.wellnessPrinciple,
      sc.aiQuote,
      for (final action in sc.actions) ...[action.title, action.description],
    ],
  ];
}

const kHomeNotifyLabel = '通知';
const kHomeBrand = '顺时';
const kHomeProfileLabel = '我的';
const kHomeWellnessHeading = '养生精要';
const kHomeAssistantTitle = '顺时 AI 助手';
const kHomeRecommendHeading = '今日推荐';
const kHomeInsightHeading = '今日洞察';
const kHomeReminderHeading = '顺时提醒';
const kHomeCtaLabel = '查看完整时辰养生表';

const kHomeChromeCopy = <String>[
  kHomeNotifyLabel,
  kHomeBrand,
  kHomeProfileLabel,
  kHomeWellnessHeading,
  kHomeAssistantTitle,
  kHomeRecommendHeading,
  kHomeInsightHeading,
  kHomeReminderHeading,
  kHomeCtaLabel,
];

List<String> visibleHomeSolarTermLines() {
  final lines = <String>{};
  for (var month = 1; month <= 12; month++) {
    for (var day = 1; day <= 28; day++) {
      lines.add(solarTermSeasonLine(DateTime(2026, month, day)));
    }
  }
  return lines.toList();
}

/// 首页上写死的字：时辰卡片、栏目标题、语音按钮、节气胶囊、今日推荐兜底。
List<String> visibleHomeCopy() {
  final solar = visibleHomeSolarTermLines();
  return [
    ...visibleHomeTimeOfDayCopy(),
    ...kHomeChromeCopy,
    ...kTodayVoiceStaticCopy,
    kHomeLoadingExplain,
    ...visiblePersonalHomeStaticCopy(),
    ...solar,
    for (final item in plainHomeSuggestions) ...[
      item.title,
      item.subtitle,
      item.tag == '饮食' ? '食物' : '作息',
    ],
    for (final sc in _shiChenList)
      for (final term in solar)
        shiChenSpoken(sc, timeDisplay: shiChenTimeDisplay(sc), solarTerm: term),
  ];
}

// ═══════════════════════════════════════════════════════════════
// 节气名称映射（根据月份大致推算）
// ═══════════════════════════════════════════════════════════════

String _getCurrentSolarTermInfo([DateTime? day]) => solarTermSeasonLine(day ?? homeClockDayFromApp());

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

List<TodayRecommendation> plainTodayRecommendations(DateTime day, {String? lifeStage}) {
  final season = seasonKeyOn(day);
  return homeSuggestionsFor(season: season, lifeStage: lifeStage).map((item) {
    final food = item.tag == '饮食';
    return TodayRecommendation(
      icon: food ? Icons.rice_bowl : Icons.nightlight_round,
      title: item.title,
      subtitle: item.subtitle,
      tag: food ? '食物' : '作息',
      accentColor: food ? ShunShiColors.apricot : ShunShiColors.calm,
    );
  }).toList();
}

// ═══════════════════════════════════════════════════════════════
// 首页 Widget
// ═══════════════════════════════════════════════════════════════

/// 时辰标题下的节气胶囊。圆点和文字放在同一个 [Row] 里，所以这里的 [Flexible]
/// 是合法的：它能让过长的节气名省略，而不是溢出。
///
/// [Flexible] 不能直接放进 [Container]。那样子组件拿到的是 [BoxParentData]，
/// 调试模式会吞掉错误（iOS 调试截图看起来正常），profile / release（含 Web）
/// 会在 `Flexible.applyParentData` 抛出
/// `BoxParentData is not a subtype of FlexParentData`，今日页主体变成灰块。
class SolarTermPill extends StatelessWidget {
  const SolarTermPill({
    super.key,
    required this.label,
    required this.color,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: borderColor == null ? null : Border.all(color: borderColor!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ShunShiTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool _elderMode = false;
  String? _lifeStage;
  DateTime? _boardDay;
  late final Future<void> _homePrefsReady;

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
    _boardDay = homeClockDayFromApp();
    _solarTermInfo = _getCurrentSolarTermInfo(_boardDay);
    _homePrefsReady = _loadHomePrefs();

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

  DateTime get _cardDay => _boardDay ?? homeClockDayFromApp();

  Future<void> _loadHomePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final stage = prefs.getString('life_stage') ?? prefs.getString('user_life_stage') ?? '';
    setState(() {
      _elderMode = prefs.getBool('elder_mode') ?? false;
      _lifeStage = stage.isEmpty ? null : stage;
    });
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
      final dashRes = await _api.get('/seasons/home/dashboard', queryParameters: {'locale': 'zh-CN'}, level: SpeedLevel.s1);

      if (!mounted) return;

      final dash = dashRes.data;
      if (dash is Map) {
        await _cache.set(CacheKeys.today(), Map<String, dynamic>.from(dash), config: CacheConfig.today);
        _applyData(Map<String, dynamic>.from(dash));
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
      await _homePrefsReady;
      final res = await _api.get('/contents/recommend', queryParameters: {'limit': 6}, level: SpeedLevel.s1);
      if (!mounted) return;
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] as Map : raw;
      if (data is Map && data['items'] is List) {
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        final kept = items.where((item) => keepHomePayload(item, season: seasonKeyOn(_cardDay), lifeStage: _lifeStage)).toList();
        if (kept.isNotEmpty) {
          setState(() {
            _todayRecs = kept.map((item) => TodayRecommendation.fromApi(item, isDark)).toList();
          });
          return;
        }
      }
      if (data is List && data.isNotEmpty) {
        final items = data.cast<Map<String, dynamic>>().where((item) => keepHomePayload(item, season: seasonKeyOn(_cardDay), lifeStage: _lifeStage)).toList();
        if (items.isNotEmpty) {
          setState(() {
            _todayRecs = items.map((item) => TodayRecommendation.fromApi(item, isDark)).toList();
          });
        }
      }
    } catch (_) {
      // Keep fallback recommendations
    }
  }

  void _applyData(Map dash) {
    final rawDate = dash['date']?.toString();
    final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (parsed != null) {
      _boardDay = DateTime(parsed.year, parsed.month, parsed.day);
      _solarTermInfo = _getCurrentSolarTermInfo(_boardDay);
    }
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
    final timeDisplay = shiChenTimeDisplay(sc);
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    if (_loading) {
      return ElderHomeScope(enabled: _elderMode, child: const HomeSkeleton());
    }

    return ElderHomeScope(
      enabled: _elderMode,
      child: Scaffold(
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
              // ═══════════════ 今天为你准备的 ═══════════════
              SliverToBoxAdapter(child: PersonalHomeSection(
                api: PersonalHomeBinding.api(),
                strings: PersonalHomeBinding.strings,
                onOpen: (card) => PersonalHomeBinding.open(context, card),
                onLogin: () => context.push('/login'),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

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
                child: _staggerWrap(5, _buildTodayRecommendations()),
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
            Semantics(
              button: true,
              label: kHomeNotifyLabel,
              child: GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExcludeSemantics(child: Icon(Icons.notifications_none, size: 20, color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary)),
              ),
            ),
            ),
            const SizedBox(width: 12),
            Text(
              kHomeBrand,
              style: ShunShiTypography.headlineSmall.copyWith(
                fontFamily: ShunShiTypography.serifFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
              ),
            ),
          ]),
          Semantics(
            button: true,
            label: kHomeProfileLabel,
            child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ShunShiColors.borderGhost, width: 1.5),
              ),
              child: const CircleAvatar(
                backgroundColor: ShunShiColors.surfaceContainerLow,
                child: ExcludeSemantics(child: Icon(Icons.person, size: 20, color: ShunShiColors.secondary)),
              ),
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
                text: sc.principleShort,
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
                  child: SolarTermPill(
                    label: _solarTermInfo,
                    color: secondaryColor,
                    borderColor: secondaryColor.withValues(alpha: 0.15 + _breathController.value * 0.1),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TodayVoiceBar(
          spokenText: shiChenSpoken(sc, timeDisplay: timeDisplay, solarTerm: _solarTermInfo),
          onTranscript: (text) => context.go('/chat?draft=${Uri.encodeQueryComponent(text)}'),
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
                label: sc.principleShort,
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
                      kHomeWellnessHeading,
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
                      kHomeAssistantTitle,
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
  Widget _buildTodayRecommendations() {
    final recs = _todayRecs.isNotEmpty ? _todayRecs : plainTodayRecommendations(_cardDay, lifeStage: _lifeStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            kHomeRecommendHeading,
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
            kHomeInsightHeading,
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
                Text(kHomeReminderHeading, style: ShunShiTypography.labelMedium.copyWith(
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
        label: const Text(kHomeCtaLabel),
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
