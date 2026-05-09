import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import 'widgets/greeting_section.dart';
import 'widgets/today_action_card.dart';
import 'widgets/secondary_card.dart';
import 'widgets/mood_section.dart';
import 'widgets/premium_teaser.dart';
import 'widgets/action_guide_overlay.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_skeleton.dart';

/// 顺时首页 V3 — 复刻"懂生活的人在帮你安排一天"
///
/// 结构（严格）：
/// 1. 问候 — 动态，时辰感知
/// 2. 主焦点卡片 — 一张大的，今天最重要的事
/// 3. 次要卡片 — 最多2个
/// 4. 快速心情 — 一排emoji
/// 5. Bottom Nav — 首页/聊天/记录/我的
///
/// 3秒知道干嘛，5秒知道今天做什么，10秒完成一个行动。
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _dio = Dio(BaseOptions(
    baseUrl: 'http://116.62.32.43:4000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 8),
  ));

  bool _isLoading = true;
  String _userName = '';
  String _currentTerm = '清明';
  String _shiChen = '';
  String _shiChenOrgan = '';
  String _constitution = '';
  String _primaryReason = '';
  String _secondary1Title = '';
  String _secondary1Sub = '';
  String _secondary2Title = '';
  String _secondary2Sub = '';
  String _selectedMood = '';
  bool _reflecting = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _currentShiChen {
    final hour = DateTime.now().hour;
    const order = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
    const starts = [23,1,3,5,7,9,11,13,15,17,19,21];
    const organs = ['胆经','肝经','肺经','大肠经','胃经','脾经','心经','小肠经','膀胱经','肾经','心包经','三焦经'];
    for (int i = starts.length - 1; i >= 0; i--) {
      if (hour >= starts[i] || (starts[i] == 23 && hour >= 23)) {
        _shiChen = order[i];
        _shiChenOrgan = organs[i];
        return order[i];
      }
    }
    return '子';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了，注意休息';
    if (h < 9) return '早安，新的一天';
    if (h < 12) return '上午好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    if (h < 22) return '晚上好';
    return '夜深了，注意休息';
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? '朋友';
    _isSubscribed = prefs.getBool('is_subscribed') ?? false;
    _constitution = prefs.getString('constitution_type') ?? '';

    final onboarded = prefs.getBool('onboarding_completed');
    if (onboarded != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/onboarding-wellness');
      });
      return;
    }

    _currentShiChen;

    if (mounted) setState(() => _isLoading = true);

    try {
      final res = await _dio.get('/api/v1/solar-terms/current');
      if (res.data?['data'] != null) {
        _currentTerm = res.data['data']['name'] ?? '清明';
      }
    } catch (_) {}

    try {
      final res = await _dio.get('/api/v1/seasons/home/dashboard');
      final d = res.data;
      if (d != null) {
        final suggestions = List<Map<String, dynamic>>.from(d['gentle_suggestions'] ?? []);
        if (suggestions.isNotEmpty) {
          _primaryReason = suggestions[0]['reason'] ?? suggestions[0]['description'] ?? '';
        }
        if (suggestions.length > 1) {
          _secondary1Title = suggestions[1]['title'] ?? '';
          _secondary1Sub = '${suggestions[1]['duration_min'] ?? 5}分钟';
        }
        if (suggestions.length > 2) {
          _secondary2Title = suggestions[2]['title'] ?? '';
          _secondary2Sub = '${suggestions[2]['duration_min'] ?? 5}分钟';
        }
      }
    } catch (_) {}

    if (_primaryReason.isEmpty) {
      _primaryReason = _getDefaultReason();
    }
    if (_secondary1Title.isEmpty) {
      _secondary1Title = '记录今天的状态';
      _secondary1Sub = '1分钟';
    }
    if (_secondary2Title.isEmpty) {
      _secondary2Title = '节气养生指南';
      _secondary2Sub = '3分钟';
    }

    if (mounted) setState(() => _isLoading = false);
    if (mounted) {
      final p = await SharedPreferences.getInstance();
      await p.setInt('last_load', DateTime.now().millisecondsSinceEpoch);
    }
  }

  String _getDefaultReason() {
    final h = DateTime.now().hour;
    if (h < 9) return '卯时大肠经旺，温水助排便。辰时胃经旺，适合吃早餐。';
    if (h < 14) return '午时心经当令，心血最旺。小憩可养心安神。';
    if (h < 18) return '申时膀胱经旺，身体排毒高峰，多喝水帮助代谢。';
    if (h < 22) return '戌时心包经旺，放松心情，释放一天的压力。';
    return '亥时三焦经旺，身体进入修复模式，早睡养阴。';
  }

  /// 根据时间判断当前行动引导断点
  String _getCurrentStep() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) return 'morning_wake';
    if (h >= 9 && h < 12) return 'morning_breakfast';
    if (h >= 12 && h < 14) return 'noon_rest';
    if (h >= 14 && h < 18) return 'afternoon';
    if (h >= 18 && h < 22) return 'evening_wind_down';
    return 'night_sleep';
  }

  String _getStepRoute() {
    final step = _getCurrentStep();
    switch (step) {
      case 'morning_wake': return '/daily-checkin';
      case 'morning_breakfast': return '/wellness';
      case 'noon_rest': return '/chat';
      case 'afternoon': return '/daily-checkin';
      case 'evening_wind_down': return '/chat';
      case 'night_sleep': return '/daily-checkin';
      default: return '/daily-checkin';
    }
  }

  Future<void> _quickReflect(String mood) async {
    if (_reflecting) return;
    setState(() { _selectedMood = mood; _reflecting = true; });
    try {
      await _dio.post('/api/v1/intl/reflection', data: {'mood': mood, 'energy': 3});
    } catch (_) {}
    if (mounted) setState(() { _selectedMood = ''; _reflecting = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: _isLoading
          ? const HomeSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: ShunShiColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      GreetingSection(
                        greeting: _greeting,
                        userName: _userName,
                        shiChen: _shiChen,
                        shiChenOrgan: _shiChenOrgan,
                        constitution: _constitution,
                      ),
                      const SizedBox(height: 20),
                      TodayActionCard(
                        currentTerm: _currentTerm,
                        shiChen: _shiChen,
                        primaryReason: _primaryReason,
                      ),
                      const SizedBox(height: 16),
                      SecondaryCard(
                        title: _secondary1Title,
                        subtitle: _secondary1Sub,
                        icon: Icons.edit_note_rounded,
                        onTap: () => context.push('/daily-checkin'),
                      ),
                      const SizedBox(height: 8),
                      SecondaryCard(
                        title: _secondary2Title,
                        subtitle: _secondary2Sub,
                        icon: Icons.eco_rounded,
                        onTap: () => context.push('/solar-term-detail/$_currentTerm'),
                      ),
                      const SizedBox(height: 8),
                      ActionGuideOverlay(
                        step: _getCurrentStep(),
                        onAction: () => context.push(_getStepRoute()),
                      ),
                      const SizedBox(height: 8),
                      MoodSection(
                        selectedMood: _selectedMood,
                        onMoodSelected: _quickReflect,
                        reflecting: _reflecting,
                      ),
                      const SizedBox(height: 24),
                      if (!_isSubscribed) const PremiumTeaser(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const HomeBottomNav(),
    );
  }
}
