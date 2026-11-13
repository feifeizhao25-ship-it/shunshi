/// 首页（今日页）— 严格对齐 UI参考图 _1
/// 设计: 水墨宣纸风格 + 毛玻璃 AI 模块
/// 结构: TopBar → 时辰大标题 → Hero养生图 → Bento行动建议 → AI助手 → CTA
library;

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import 'package:go_router/go_router.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/today_voice_bar.dart';
import 'widgets/personal_home_binding.dart';
import '../../widgets/personal_home_section.dart';
import '../../account/account_surface.dart';
import '../../../data/services/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/style_theming.dart';
import '../../../data/network/session.dart';
import '../../../core/time/domestic_clock.dart';
import 'elder_home_text.dart';
import 'home_clock.dart';
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

/// 首页卡片和「完整时辰养生表」共用这一份十二时辰，避免两处文案各写各的。
List<ShiChenData> homeShiChenTable() => _shiChenList;

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

const kHomeBrand = '顺时';
const kHomeWellnessHeading = '养生精要';
const kHomeAssistantTitle = '顺时 AI 助手';
const kHomeInsightHeading = '今日洞察';
const kHomeReminderHeading = '顺时提醒';
const kHomeCtaLabel = '查看完整时辰养生表';

const kHomeChromeCopy = <String>[
  kHomeBrand,
  kHomeWellnessHeading,
  kHomeAssistantTitle,
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

/// 首页上写死的字：时辰卡片、栏目标题、语音按钮、节气胶囊。
List<String> visibleHomeCopy() {
  final solar = visibleHomeSolarTermLines();
  return [
    ...visibleHomeTimeOfDayCopy(),
    ...kHomeChromeCopy,
    ...kTodayVoiceStaticCopy,
    kHomeLoadingExplain,
    ...visiblePersonalHomeStaticCopy(),
    ...solar,
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
// 首页 Widget
// ═══════════════════════════════════════════════════════════════

/// 时辰标题下的节气胶囊。文字在父级 Column 的有限宽度里省略。
///
/// 不要把 [Flexible] 放进这个 [Container]。[Flexible] 只能做 [Row]/[Column]/[Flex]
/// 的子节点。包在 [Container] 里时，子组件拿到的是 [BoxParentData]。调试模式会把
/// 这个不匹配吞掉，所以 iOS 调试截图仍然正常；profile / release（含 Web）会在
/// `Flexible.applyParentData` 里把它强转成 [FlexParentData]，抛出
/// `BoxParentData is not a subtype of FlexParentData`，今日页主体变成灰块。
class SolarTermPill extends StatelessWidget {
  const SolarTermPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

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
        ),
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
    );
  }
}

class UltimateHomePage extends StatefulWidget {
  const UltimateHomePage({super.key});

  @override
  State<UltimateHomePage> createState() => _UltimateHomePageState();
}

class _UltimateHomePageState extends State<UltimateHomePage> {
  static const _baseUrl = AppConfig.apiBaseUrl;
  final _dio = withSessionAuth(Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  )));

  late ShiChenData _currentShiChen;
  String _solarTermInfo = '';
  String _dailyInsight = '';
  // ignore: unused_field
  List<Map<String, dynamic>> _apiSuggestions = [];
  bool _loading = true;
  bool _elderMode = false;
  DateTime? _boardDay;

  Map<String, dynamic> _followUp = {};
  bool _hasFollowUp = false;

  @override
  void initState() {
    super.initState();
    _currentShiChen = getCurrentShiChen();
    _boardDay = homeClockDayFromApp();
    _solarTermInfo = _getCurrentSolarTermInfo(_boardDay);
    _loadHomePrefs();
    _fetchDashboard();
  }

  /// 到期随访只查「我自己」的：`/followup/check-due`（用户接口）。
  /// 以前调的 `/followup/due` 是管理员接口（列出所有人的任务），普通用户一律 403，
  /// 而且 Future.wait 里任何一个请求失败，整个首页数据都会被丢掉——所以这里吞掉失败，只当「没有到期随访」。
  Future<Response<dynamic>> _dueFollowups() async {
    try {
      return await _dio.get('/api/v1/followup/check-due', queryParameters: {...userIdParam()});
    } catch (_) {
      return Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/followup/check-due'),
        data: const {'due_followups': []},
      );
    }
  }

  Future<void> _loadHomePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _elderMode = prefs.getBool('elder_mode') ?? false);
  }

  Future<void> _fetchDashboard() async {
    // Try offline cache first
    try {
      final cached = await OfflineCache.getCachedDashboard();
      if (cached != null && mounted) {
        _applyData(Map<String, dynamic>.from(cached));
        setState(() => _loading = false);
      }
    } catch (_) {}

    try {
      final results = await Future.wait([
        _dio.get('/api/v1/seasons/home/dashboard?locale=zh-CN'),
        _dio.get('/api/v1/solar-terms/current'),
        _dueFollowups(),
      ]);

      if (!mounted) return;

      final dash = results[0].data;
      if (dash is Map) {
        await OfflineCache.cacheDashboard(Map<String, dynamic>.from(dash));
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

  @override
  Widget build(BuildContext context) {
    final sc = _currentShiChen;
    final timeDisplay = shiChenTimeDisplay(sc);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : AppColors.background(context);

    if (_loading) {
      return ElderHomeScope(enabled: _elderMode, child: const HomeSkeleton());
    }

    return ElderHomeScope(
      enabled: _elderMode,
      child: Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ═══════════════ TopAppBar ═══════════════
            SliverToBoxAdapter(
              child: _buildTopBar(sc),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ═══════════════ 时辰大标题 + 节气胶囊 ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildHeroTitle(sc, timeDisplay),
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
                child: _buildHeroImage(sc),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ═══════════════ Bento 行动建议 (2列) ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildBentoGrid(sc),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ═══════════════ AI 助手模块 (毛玻璃) ═══════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildAIModule(sc),
              ),
            ),

            // ═══════════════ 今日洞察 (如有) ═══════════════
            if (_dailyInsight.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildDailyInsight(),
                ),
              ),
            ],

            // ═══════════════ 顺时提醒 (如有) ═══════════════
            if (_hasFollowUp) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildFollowUpCard(),
                ),
              ),
            ],

            // ═══════════════ CTA 按钮 ═══════════════
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCTA(),
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
          // Left: Menu + Brand
          Row(children: [
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notifications_none, size: 20, color: AppColors.textPrimary(context)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              kHomeBrand,
              style: ShunShiTypography.headlineSmall.copyWith(
                fontFamily: ShunShiTypography.serifFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ).themed(context),
            ),
          ]),
          // Right: Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGhost(context), width: 1.5),
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceContainerLow(context),
                child: Icon(Icons.person, size: 20, color: AppColors.secondary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 时辰大标题 + 节气胶囊 ───
  Widget _buildHeroTitle(ShiChenData sc, String timeDisplay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time range label
        Text(
          timeDisplay,
          style: ShunShiTypography.labelMedium.copyWith(
            color: AppColors.secondary(context),
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
            ).themed(context),
            children: [
              TextSpan(text: '${sc.name} · '),
              TextSpan(
                text: sc.principleShort,
                style: TextStyle(color: AppColors.secondary(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SolarTermPill(
          label: _solarTermInfo,
          color: AppColors.secondary(context),
        ),
        const SizedBox(height: 12),
        TodayVoiceBar(
          spokenText: shiChenSpoken(sc, timeDisplay: timeDisplay, solarTerm: _solarTermInfo),
          onTranscript: (text) => context.go('/chat?draft=${Uri.encodeQueryComponent(text)}'),
        ),
      ],
    );
  }

  // ─── Hero 水墨意境区 ───
  Widget _buildHeroImage(ShiChenData sc) {
    final bg = Theme.of(context).brightness == Brightness.dark ? ShunShiColors.darkBackground : AppColors.background(context);
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A).withValues(alpha: 0.85),
            const Color(0xFF1A1A1A).withValues(alpha: 0.95),
            const Color(0xFF3D3D3D).withValues(alpha: 0.80),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative ink strokes (elongated ellipses)
          ...List.generate(6, (i) {
            final rng = Random(i * 37 + sc.name.hashCode);
            return Positioned(
              left: rng.nextDouble() * 260,
              top: rng.nextDouble() * 220,
              child: Transform.rotate(
                angle: (rng.nextDouble() - 0.5) * 1.2,
                child: Container(
                  width: 60 + rng.nextDouble() * 100,
                  height: 12 + rng.nextDouble() * 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Colors.white.withValues(alpha: 0.03 + rng.nextDouble() * 0.05),
                  ),
                ),
              ),
            );
          }),
          // Bottom gradient overlay
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A1A).withValues(alpha: 0),
                    const Color(0xFF1A1A1A).withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          // Wellness principle card — 养生精要
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
                      color: AppColors.secondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sc.wellnessPrinciple,
                    style: ShunShiTypography.serifTitle.copyWith(
                      fontSize: 18,
                      color: AppColors.primary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bento 行动建议 (垂直列表) ───
  Widget _buildBentoGrid(ShiChenData sc) {
    return Column(
      children: sc.actions.map((action) => _buildBentoCard(action)).toList()
        ..insert(1, const SizedBox(height: 16)),
    );
  }

  Widget _buildBentoCard(BentoAction action) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShunShiShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, size: 24, color: AppColors.primary(context)),
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
                  ).themed(context),
                ),
                const SizedBox(height: 6),
                Text(
                  action.description,
                  style: ShunShiTypography.bodySmall.copyWith(
                    height: 1.6,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI 助手模块 ───
  Widget _buildAIModule(ShiChenData sc) {
    final bg = Theme.of(context).brightness == Brightness.dark ? ShunShiColors.darkBackground : AppColors.background(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGhost(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          SizedBox(
            width: 52, height: 52,
            child: Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                // Pulse indicator
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
          // AI text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kHomeAssistantTitle,
                  style: ShunShiTypography.titleMedium.copyWith(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 16,
                  ).themed(context),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${sc.aiQuote}"',
                  style: ShunShiTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary(context),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            AppColors.primary(context),
            ShunShiColors.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
        color: AppColors.primary(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary(context).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_active, color: AppColors.primary(context), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kHomeReminderHeading, style: ShunShiTypography.labelMedium.copyWith(
                  color: AppColors.primary(context), fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(
                  _followUp['title']?.toString() ?? _followUp['description']?.toString() ?? '',
                  style: ShunShiTypography.bodySmall.themed(context),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 18),
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
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

}
