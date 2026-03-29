// 顺时「今日」页面 — 国内版
// 根据 life_stage 动态展示不同模块
// 默认展示"压力阶段"布局（最通用）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../core/core.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/wellness_assets.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/today_plan_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/network/api_client.dart';

// ── 体质常量（与 constitution_page 同步） ──
const _kEmojiMap = {
  'pinghe': '😊', 'qixu': '😰', 'yangxu': '🥶', 'yinxu': '🔥',
  'tanshi': '😪', 'shire': '🤢', 'xueyu': '😣', 'qiyu': '😔', 'tebing': '🤧',
};
const _kDescMap = {
  'pinghe': '阴阳气血调和，面色润泽，精力充沛',
  'qixu': '元气不足，易疲乏，气短懒言，易出汗',
  'yangxu': '阳气不足，手脚发凉，畏寒怕冷',
  'yinxu': '体内阴液亏少，口燥咽干，手足心热',
  'tanshi': '痰湿凝聚，形体肥胖，腹部肥满松软',
  'shire': '湿热内蕴，面垢油光，口苦口干',
  'xueyu': '血行不畅，肤色晦暗，易出现瘀斑',
  'qiyu': '气机郁滞，神情抑郁，忧虑脆弱',
  'tebing': '先天禀赋不足或过敏体质，易过敏',
};

/// 今日页面
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = true;
  LifeStage? _lifeStage; // 动态加载，首次为 null
  String _userName = ''; // 从 SharedPreferences 读取

  /// 根据年龄范围字符串转换为生命周期阶段
  static LifeStage _lifeStageFromAgeRange(String? ageRange) {
    if (ageRange == null) return LifeStage.pressure; // 默认
    if (ageRange == '20-30岁') return LifeStage.exploration; // 18-25 探索期
    if (ageRange == '30-40岁') return LifeStage.pressure; // 25-40 压力期
    if (ageRange == '40-50岁') return LifeStage.health; // 40-50 健康期
    if (ageRange == '50-60岁') return LifeStage.health; // 50-60 健康期
    if (ageRange == '60岁以上') return LifeStage.companionship; // 60+ 陪伴期
    return LifeStage.pressure;
  }

  // 今日数据（API 获取，失败用 mock）
  String _insightText = '';
  String _insightTitle = '';
  String _insightIcon = '💡';
  String _solarTermName = '春分';
  String _solarTermEmoji = '🌱';
  String _solarTermDesc = '阴阳平衡，昼夜相等';
  List<String> _solarTermSuggestions = ['适当运动', '调理脾胃'];

  // 今日计划（早/中/晚）
  final List<_PlanSlot> _morningPlan = [];
  final List<_PlanSlot> _afternoonPlan = [];
  final List<_PlanSlot> _eveningPlan = [];

  // 本周趋势
  double _sleepProgress = 0.0;
  double _exerciseProgress = 0.0;
  double _moodProgress = 0.0;

  // 养生名言
  String _wisdomText = '';
  String _wisdomSource = '';
  String _wisdomCategory = '';
  bool _isPlayingTts = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 人群养生推荐
  Map<String, dynamic> _crowdRecommendation = {};
  bool _crowdLoading = false;

  // 心情记录
  String? _selectedMood;

  // 健康阶段：体质关注
  String _constitutionText = '气虚体质，注意补气养肺';
  bool _hasConstitutionResult = false; // 是否已完成体质测试
  String _constitutionType = ''; // 体质类型 key (qixu/yinxu/...)
  String _constitutionName = ''; // 体质名称
  String _constitutionTestDate = ''; // 测试日期

  // 健康阶段：节气食疗
  final List<_FoodRecommend> _foodRecommendations = [];

  // 健康阶段：穴位调理
  final List<_AcupointItem> _acupointItems = [];

  // 陪伴阶段：家庭关怀
  String _familyCareText = '今天天气不错，可以陪家人散散步';

  // 个性化推荐数据
  Map<String, List<_RecommendItem>> _recommendations = {};
  bool _recommendLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLifeStage();
    _loadConstitutionResult();
    _loadData();
    _loadRecommendations();
    // 延迟启动离线同步
    Future.delayed(const Duration(seconds: 2), () {
      offlineSyncService.startAutoSync();
    });
  }

  /// 从 SharedPreferences 加载用户生命周期阶段
  Future<void> _loadLifeStage() async {
    final prefs = await SharedPreferences.getInstance();
    final ageRange = prefs.getString('user_stage');
    setState(() {
      _lifeStage = _lifeStageFromAgeRange(ageRange);
    });
  }

  Future<void> _loadData() async {
    // 获取用户ID和半球
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'demo_user';
    final hemisphere = prefs.getString('hemisphere') ?? 'north';

    try {
      // 首先尝试从 home dashboard API 获取数据
      final dashboardDio = Dio(BaseOptions(
        headers: {'ngrok-skip-browser-warning': 'true'},
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final dashboardResp = await dashboardDio.get(
        '/api/v1/seasons/home/dashboard',
        queryParameters: {
          'user_id': userId,
          'hemisphere': hemisphere,
        },
      );

      if (dashboardResp.statusCode == 200 && mounted) {
        final data = dashboardResp.data;
        setState(() {
          // 更新问候语
          if (data['greeting'] != null) {
            _userName = data['greeting'] ?? _userName;
          }
          // 更新每日洞察
          if (data['daily_insight'] != null) {
            _insightTitle = '今日洞察';
            _insightText = data['daily_insight']['text'] ?? '';
            _insightIcon = '💡';
          }
          // 更新节气卡片
          if (data['season_card'] != null) {
            _solarTermName = data['season_card']['name'] ?? _solarTermName;
            _solarTermEmoji = data['season_card']['emoji'] ?? _solarTermEmoji;
          }
          // 更新建议列表
          if (data['suggestions'] != null) {
            final suggestions = data['suggestions'] as List;
            _morningPlan.clear();
            _afternoonPlan.clear();
            _eveningPlan.clear();
            for (final s in suggestions) {
              final slot = _PlanSlot(
                icon: _getIconForCategory(s['category'] ?? ''),
                title: s['text'] ?? '',
                subtitle: '',
              );
              _morningPlan.add(slot);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Home dashboard API call failed: $e');
    }

    try {
      // 尝试从 API 获取今日计划
      final dio = Dio(BaseOptions(headers: {'ngrok-skip-browser-warning': 'true'},
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final service = TodayPlanService(dio);
      final plan = await service.getTodayPlan();

      if (!mounted) return;
      setState(() {
        if (plan.insights.isNotEmpty) {
          _insightTitle = plan.insights.first.title;
          _insightText = plan.insights.first.content;
          _insightIcon = plan.insights.first.icon;
        }
        if (plan.solarTerm != null) {
          _solarTermName = plan.solarTerm!.name;
          _solarTermEmoji = plan.solarTerm!.emoji;
          _solarTermDesc = plan.solarTerm!.description;
          _solarTermSuggestions = plan.solarTerm!.suggestions;
        }
        _initPlanSlots(plan);
        _isLoading = false;
      });
      // 加载每日养生名言
      _loadDailyWisdom();
      // 加载人群养生推荐
      _loadCrowdRecommendation();
    } catch (_) {
      if (!mounted) return;
      _loadMockData();
    }
  }

  String _getIconForCategory(String category) {
    switch (category) {
      case 'movement': return '🧘';
      case 'food': return '🍵';
      case 'rest': return '😴';
      case 'mental': return '🧠';
      default: return '💡';
    }
  }

  /// 从本地读取体质测试结果
  Future<void> _loadConstitutionResult() async {
    final prefs = await SharedPreferences.getInstance();
    // 读取用户名
    final userName = prefs.getString('user_name') ?? '';
    if (userName.isNotEmpty && mounted) {
      setState(() => _userName = userName);
    }
    final type = prefs.getString('constitution_type') ?? '';
    final name = prefs.getString('constitution_name') ?? '';
    final testDate = prefs.getString('constitution_test_date') ?? '';
    if (type.isNotEmpty && name.isNotEmpty) {
      setState(() {
        _hasConstitutionResult = true;
        _constitutionType = type;
        _constitutionName = name;
        _constitutionTestDate = testDate;
        _constitutionText = '$name，注意调养';
      });
    }
  }

  /// 检查是否需要重新测试（超过30天）
  bool _shouldRetestConstitution() {
    if (_constitutionTestDate.isEmpty) return false;
    final lastTest = DateTime.tryParse(_constitutionTestDate);
    if (lastTest == null) return false;
    return DateTime.now().difference(lastTest).inDays > 30;
  }

  Future<void> _loadDailyWisdom() async {
    try {
      final dio = Dio(BaseOptions(headers: {'ngrok-skip-browser-warning': 'true'}, 
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final resp = await dio.get('/api/v1/wisdom/daily', queryParameters: {
        'constitution': _constitutionType.isNotEmpty ? _constitutionType : 'pinghe',
      });
      if (resp.statusCode == 200 && mounted) {
        final data = resp.data['data'];
        setState(() {
          _wisdomText = data['text'] ?? '';
          _wisdomSource = data['source'] ?? '';
          _wisdomCategory = data['category'] ?? 'general';
        });
      }
    } catch (_) {
      // 名言加载失败不影响页面
    }
  }

  Future<void> _playWisdomTts() async {
    if (_wisdomText.isEmpty || _isPlayingTts) return;
    setState(() => _isPlayingTts = true);
    try {
      final dio = Dio(BaseOptions(headers: {'ngrok-skip-browser-warning': 'true'}, 
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));
      final resp = await dio.post('/api/v1/speech/tts', data: {
        'text': _wisdomText,
        'model': 'cosyvoice2',
        'voice': 'alex',
      }, options: Options(responseType: ResponseType.bytes));
      if (resp.statusCode == 200 && mounted) {
        final bytes = resp.data as List<int>;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/wisdom_tts.mp3');
        await file.writeAsBytes(bytes);
        await _audioPlayer.play(DeviceFileSource(file.path));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingTts = false);
        });
      }
    } catch (e) {
      debugPrint('TTS error: $e');
      if (mounted) setState(() => _isPlayingTts = false);
    }
  }

  Future<void> _loadCrowdRecommendation() async {
    setState(() => _crowdLoading = true);
    try {
      final dio = Dio(BaseOptions(headers: {'ngrok-skip-browser-warning': 'true'}, 
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final resp = await dio.get('/api/v1/crowd/recommend', queryParameters: {
        'age': 30,
        'occupation': '程序员',
        'constitution': _constitutionType.isNotEmpty ? _constitutionType : 'pinghe',
        'tags': '压力,久坐',
      });
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _crowdRecommendation = resp.data['data'];
          _crowdLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _crowdLoading = false);
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _recommendLoading = true);
    try {
      final dio = Dio(BaseOptions(headers: {'ngrok-skip-browser-warning': 'true'}, 
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final resp = await dio.post('/api/v1/recommend/today-digest', data: {
        'constitution_type': _constitutionType.isNotEmpty ? _constitutionType : 'pinghe',
        'solar_term': _getCurrentSolarTerm(),
        'season': _getCurrentSeason(),
      });
      if (resp.statusCode == 200 && mounted) {
        final recs = resp.data['recommendations'] as Map<String, dynamic>?;
        if (recs != null) {
          final Map<String, List<_RecommendItem>> parsed = {};
          const categoryMap = {
            'food_therapy': '食疗',
            'tea': '茶饮',
            'exercise': '运动',
            'acupressure': '穴位',
            'sleep_tip': '睡眠',
          };
          const emojiMap = {
            'food_therapy': '🥣',
            'tea': '🍵',
            'exercise': '🧘',
            'acupressure': '✋',
            'sleep_tip': '😴',
          };
          recs.forEach((key, value) {
            final items = (value as List).map((e) => _RecommendItem.fromJson(e as Map<String, dynamic>)).toList();
            parsed[key] = items;
          });
          setState(() {
            _recommendations = parsed;
            _recommendLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _recommendLoading = false);
    }
  }

  void _loadMockData() {
    setState(() {
      _insightTitle = '今日洞察';
      _insightText = '最近你下午容易疲惫，今天适合让身体慢一点。\n建议午后小憩15分钟，喝一杯温热的红枣茶。';
      _insightIcon = '💡';

      _solarTermName = _getCurrentSolarTerm();
      _solarTermEmoji = '🍃';
      _solarTermDesc = '万物复苏，宜舒展养肝';
      _solarTermSuggestions = ['舒展身体', '养肝护肝', '早睡早起'];

      _morningPlan.addAll([
        _PlanSlot(icon: '🌅', title: '晨起一杯温水', subtitle: '唤醒身体'),
        _PlanSlot(icon: '🧘', title: '5分钟拉伸', subtitle: '舒展肩颈'),
      ]);
      _afternoonPlan.addAll([
        _PlanSlot(icon: '☀️', title: '午后晒太阳10分钟', subtitle: '补充阳气'),
        _PlanSlot(icon: '🍵', title: '一杯红枣桂圆茶', subtitle: '补气血'),
      ]);
      _eveningPlan.addAll([
        _PlanSlot(icon: '🌙', title: '23:00前入睡', subtitle: '养肝护肝'),
        _PlanSlot(icon: '🌬️', title: '睡前呼吸练习', subtitle: '助眠放松'),
      ]);

      _sleepProgress = 0.72;
      _exerciseProgress = 0.45;
      _moodProgress = 0.68;

      _constitutionText = '气虚体质，注意补气养肺';
      _foodRecommendations.addAll([
        _FoodRecommend(name: '山药小米粥', benefit: '补脾胃、益肺气'),
        _FoodRecommend(name: '黄芪炖鸡汤', benefit: '补气固表'),
        _FoodRecommend(name: '枸杞菊花茶', benefit: '养肝明目'),
      ]);
      _acupointItems.addAll([
        _AcupointItem(name: '足三里', desc: '补脾胃、增强免疫'),
        _AcupointItem(name: '合谷穴', desc: '缓解头痛、安神'),
        _AcupointItem(name: '太冲穴', desc: '疏肝理气、降压'),
      ]);

      _familyCareText = '今天天气不错，记得提醒家人出门散步。\n晚餐可以做一道清淡的山药排骨汤。';

      _isLoading = false;
    });
  }

  void _initPlanSlots(TodayPlan plan) {
    for (final task in plan.tasks) {
      final slot = _PlanSlot(
        icon: _getCategoryIcon(task.category),
        title: task.title,
        subtitle: task.description ?? '',
      );
      switch (task.timeSlot) {
        case 'morning':
          _morningPlan.add(slot);
        case 'afternoon':
          _afternoonPlan.add(slot);
        case 'evening':
          _eveningPlan.add(slot);
        default:
          // fallback: 按 category 语义分配
          switch (task.category) {
            case 'diet':
              if (task.title.contains('早餐') || task.title.contains('晨') || task.title.contains('温'))
                _morningPlan.add(slot);
              else
                _eveningPlan.add(slot);
            case 'exercise':
              _morningPlan.add(slot);
            case 'rest':
              _afternoonPlan.add(slot);
            case 'mental':
              _eveningPlan.add(slot);
            default:
              if (_morningPlan.length <= _afternoonPlan.length &&
                  _morningPlan.length <= _eveningPlan.length) {
                _morningPlan.add(slot);
              } else if (_afternoonPlan.length <= _eveningPlan.length) {
                _afternoonPlan.add(slot);
              } else {
                _eveningPlan.add(slot);
              }
          }
      }
    }

    if (_morningPlan.isEmpty && _afternoonPlan.isEmpty && _eveningPlan.isEmpty) {
      _morningPlan.addAll([
        _PlanSlot(icon: '🌅', title: '晨起一杯温水', subtitle: '唤醒身体'),
        _PlanSlot(icon: '🧘', title: '5分钟拉伸', subtitle: '舒展肩颈'),
      ]);
      _afternoonPlan.addAll([
        _PlanSlot(icon: '☀️', title: '午后晒太阳10分钟', subtitle: '补充阳气'),
        _PlanSlot(icon: '🍵', title: '一杯红枣桂圆茶', subtitle: '补气血'),
      ]);
      _eveningPlan.addAll([
        _PlanSlot(icon: '🌙', title: '23:00前入睡', subtitle: '养肝护肝'),
        _PlanSlot(icon: '🌬️', title: '睡前呼吸练习', subtitle: '助眠放松'),
      ]);
    }

    _sleepProgress = 0.72;
    _exerciseProgress = 0.45;
    _moodProgress = 0.68;
  }

  String _getCategoryIcon(String? category) {
    switch (category) {
      case 'morning':
        return '🌅';
      case 'afternoon':
        return '☀️';
      case 'evening':
        return '🌙';
      case 'health':
        return '💚';
      case 'exercise':
        return '🧘';
      case 'food':
        return '🍵';
      default:
        return '📋';
    }
  }

  /// 简单节气映射
  String _getCurrentSolarTerm() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    if ((month == 3 && day >= 20) || (month == 4 && day < 4)) return '春分';
    if ((month == 4 && day >= 4) && (month == 4 && day < 20)) return '清明';
    if ((month == 4 && day >= 20) || (month == 5 && day < 6)) return '谷雨';
    if ((month == 5 && day >= 6) && (month == 5 && day < 21)) return '立夏';
    if ((month == 5 && day >= 21) || (month == 6 && day < 6)) return '小满';
    if ((month == 6 && day >= 6) && (month == 6 && day < 21)) return '芒种';
    if ((month == 6 && day >= 21) || (month == 7 && day < 7)) return '夏至';
    if ((month == 7 && day >= 7) && (month == 7 && day < 23)) return '小暑';
    if ((month == 7 && day >= 23) || (month == 8 && day < 7)) return '大暑';
    if ((month == 8 && day >= 7) && (month == 8 && day < 23)) return '立秋';
    if ((month == 8 && day >= 23) || (month == 9 && day < 8)) return '处暑';
    if ((month == 9 && day >= 8) && (month == 9 && day < 23)) return '白露';
    if ((month == 9 && day >= 23) || (month == 10 && day < 8)) return '秋分';
    if ((month == 10 && day >= 8) && (month == 10 && day < 24)) return '寒露';
    if ((month == 10 && day >= 24) || (month == 11 && day < 7)) return '霜降';
    if ((month == 11 && day >= 7) && (month == 11 && day < 22)) return '立冬';
    if ((month == 11 && day >= 22) || (month == 12 && day < 7)) return '小雪';
    if ((month == 12 && day >= 7) && (month == 12 && day < 22)) return '大雪';
    if ((month == 12 && day >= 22) || (month == 1 && day < 6)) return '冬至';
    if ((month == 1 && day >= 6) && (month == 1 && day < 20)) return '小寒';
    if ((month == 1 && day >= 20) || (month == 2 && day < 4)) return '大寒';
    if ((month == 2 && day >= 4) && (month == 2 && day < 19)) return '立春';
    if ((month == 2 && day >= 19) || (month == 3 && day < 6)) return '雨水';
    if ((month == 3 && day >= 6) && (month == 3 && day < 21)) return '惊蛰';
    return '春分';
  }

  String _getCurrentSeason() {
    final term = _getCurrentSolarTerm();
    const springTerms = ['立春', '雨水', '惊蛰', '春分', '清明', '谷雨'];
    const summerTerms = ['立夏', '小满', '芒种', '夏至', '小暑', '大暑'];
    const autumnTerms = ['立秋', '处暑', '白露', '秋分', '寒露', '霜降'];
    if (springTerms.contains(term)) return 'spring';
    if (summerTerms.contains(term)) return 'summer';
    if (autumnTerms.contains(term)) return 'autumn';
    return 'winter';
  }

  String _typeEmoji(String type) {
    const map = {
      'food_therapy': '🥣', 'recipe': '🥣',
      'tea': '🍵',
      'exercise': '🧘',
      'acupoint': '✋', 'acupressure': '🤲',
      'sleep_tip': '😴',
      'emotion': '🌬️',
      'tips': '💡',
    };
    return map[type] ?? '🍃';
  }

  /// 根据当前时间返回问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早安';
    if (hour < 18) return '午安';
    return '晚安';
  }

  /// 格式化日期
  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ShunShiColors.primary,
                ),
              )
            : RefreshIndicator(
                color: ShunShiColors.primary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // ── 顶部问候卡片 ──
                      _buildTopCard(),
                      const SizedBox(height: 12),

                      // ── 每日养生格言 ──
                      _buildInsightCard(),
                      const SizedBox(height: 12),

                      // ── 人群养生推荐（个性化） ──
                      _buildCrowdCard(),
                      const SizedBox(height: 12),

                      // ── 体质测试/结果（全局显示） ──
                      _buildConstitutionCard(),
                      const SizedBox(height: 12),

                      // ── 根据 life_stage 展示不同内容 ──
                      ..._buildStageContent(),

                      const SizedBox(height: 12),

                      // ── AI 聊天入口 ──
                      _buildAIEntry(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 顶部问候卡片（渐变绿色背景）
  // ═══════════════════════════════════════════

  Widget _buildTopCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B9E7E), // 鼠尾草绿
            Color(0xFF6B8C6A), // 深绿
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B9E7E).withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userName.isNotEmpty ? '${_getGreeting()}，$_userName' : _getGreeting(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getFormattedDate(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          // 节气标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _solarTermEmoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_solarTermName · $_solarTermDesc',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 根据 life_stage 动态构建内容
  // ═══════════════════════════════════════════

  List<Widget> _buildStageContent() {
    final stage = _lifeStage ?? LifeStage.pressure;
    switch (stage) {
      case LifeStage.exploration:
        return _buildExplorationContent();
      case LifeStage.pressure:
        return _buildPressureContent();
      case LifeStage.health:
        return _buildHealthContent();
      case LifeStage.companionship:
        return _buildCompanionshipContent();
    }
  }

  // ───────── 探索阶段 (18-25) ─────────

  List<Widget> _buildExplorationContent() {
    return [
      _buildRhythmCard(),
      const SizedBox(height: 12),
      _buildThreeThingsCard(),
      const SizedBox(height: 12),
      _buildMoodCard(),
    ];
  }

  // ───────── 压力阶段 (25-40) — 默认 ─────────

  List<Widget> _buildPressureContent() {
    return [
      _buildWellnessCard(),
      const SizedBox(height: 12),
      _buildTodayPlanCard(),
      const SizedBox(height: 12),
      _buildWeeklyTrendCard(),
    ];
  }

  // ───────── 健康阶段 (40-60) ─────────

  List<Widget> _buildHealthContent() {
    return [
      _buildWellnessCard(),
      const SizedBox(height: 12),
      _buildFoodRecommendCard(),
      const SizedBox(height: 12),
      _buildAcupointCard(),
      const SizedBox(height: 12),
      _buildTodayPlanCard(),
      const SizedBox(height: 12),
      _buildWeeklyTrendCard(),
    ];
  }

  // ───────── 陪伴阶段 (60+) ─────────

  List<Widget> _buildCompanionshipContent() {
    return [
      _buildTodayPlanCard(),
      const SizedBox(height: 12),
      _buildVoiceInputCard(),
      const SizedBox(height: 12),
      _buildFamilyCareCard(),
    ];
  }

  // ═══════════════════════════════════════════
  // 通用卡片容器
  // ═══════════════════════════════════════════

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShunShiShadows.sm,
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════
  // 养生名言卡片 + 今日洞察
  // ═══════════════════════════════════════════

  Widget _buildInsightCard() {
    final hasWisdom = _wisdomText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: hasWisdom
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F7F0),
                  Color(0xFFF5F0E8),
                  Color(0xFFEEF2F7),
                ],
              )
            : null,
        color: hasWisdom ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShunShiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text(hasWisdom ? '📜' : _insightIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                hasWisdom ? '每日养生格言' : (_insightTitle.isNotEmpty ? _insightTitle : '今日洞察'),
                style: ShunShiTypography.titleMedium,
              ),
              const Spacer(),
              if (hasWisdom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _wisdomSource.isNotEmpty ? _wisdomSource.split('·').last.replaceAll('《', '').replaceAll('》', '').replaceAll('》', '') : '养生',
                    style: ShunShiTypography.caption.copyWith(
                      color: ShunShiColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              if (hasWisdom) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isPlayingTts ? null : _playWisdomTts,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isPlayingTts
                          ? ShunShiColors.primary.withValues(alpha: 0.15)
                          : ShunShiColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _isPlayingTts
                        ? SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ShunShiColors.primary,
                            ),
                          )
                        : Icon(Icons.volume_up, size: 14, color: ShunShiColors.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // 名言正文
          if (hasWisdom) ...[
            // 左侧装饰竖线 + 名言
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: ShunShiColors.primary.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 引号装饰
                  Text(
                    '"',
                    style: TextStyle(
                      fontSize: 40,
                      height: 0.6,
                      color: ShunShiColors.primary.withValues(alpha: 0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 名言文字
                  Text(
                    _wisdomText,
                    style: ShunShiTypography.bodyMedium.copyWith(
                      color: ShunShiColors.textPrimary,
                      height: 1.8,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 出处
                  if (_wisdomSource.isNotEmpty)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '—— $_wisdomSource',
                        style: ShunShiTypography.caption.copyWith(
                          color: ShunShiColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            // 原来的洞察内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _insightText.isNotEmpty
                    ? _insightText
                    : '今天适合慢下来，给自己泡一杯茶。注意休息，保持心情愉快。',
                style: ShunShiTypography.bodyMedium.copyWith(
                  color: ShunShiColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 人群养生推荐（个性化）
  // ═══════════════════════════════════════════

  Widget _buildCrowdCard() {
    final hasData = _crowdRecommendation.isNotEmpty && _crowdRecommendation['primary'] != null;

    // 加载中
    if (_crowdLoading) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🎯', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('为你定制', style: ShunShiTypography.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      );
    }

    if (!hasData) return const SizedBox.shrink();

    final primary = _crowdRecommendation['primary'] as Map<String, dynamic>;
    final profile = _crowdRecommendation['user_profile'] as Map<String, dynamic>? ?? {};
    final ageGroup = profile['age_group'] as Map<String, dynamic>? ?? {};
    final recs = primary['recommendations'] as Map<String, dynamic>? ?? {};
    final keyPoints = primary['key_points'] as List? ?? [];
    final symptoms = primary['symptoms'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShunShiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text(primary['icon'] ?? '🎯', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  primary['title'] ?? '为你定制',
                  style: ShunShiTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ageGroup.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ageGroup['icon'] ?? ''} ${ageGroup['label'] ?? ''}',
                    style: ShunShiTypography.caption.copyWith(
                      color: ShunShiColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 摘要
          if (primary['summary'] != null)
            Text(
              primary['summary'],
              style: ShunShiTypography.bodySmall.copyWith(
                color: ShunShiColors.textSecondary,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 12),

          // 常见症状标签
          if (symptoms.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: symptoms.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFE65100)),
                ),
              )).toList(),
            ),
          const SizedBox(height: 14),

          // 推荐方案 — 食疗
          if (recs['diet'] != null && (recs['diet'] as List).isNotEmpty) ...[
            _buildCrowdSection('🍽️ 饮食调理', recs['diet'] as List),
            const SizedBox(height: 10),
          ],

          // 推荐方案 — 运动
          if (recs['exercise'] != null && (recs['exercise'] as List).isNotEmpty) ...[
            _buildCrowdSection('🏃 运动建议', recs['exercise'] as List),
            const SizedBox(height: 10),
          ],

          // 推荐方案 — 睡眠
          if (recs['sleep'] != null && (recs['sleep'] as List).isNotEmpty) ...[
            _buildCrowdSection('😴 睡眠调理', recs['sleep'] as List),
            const SizedBox(height: 10),
          ],

          // 要点提醒
          if (keyPoints.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 重点提醒', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
                  const SizedBox(height: 6),
                  ...keyPoints.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: Color(0xFF616161), height: 1.5))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // 查看更多
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '更多养生方案 ›',
              style: ShunShiTypography.caption.copyWith(
                color: ShunShiColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 人群推荐子模块
  Widget _buildCrowdSection(String title, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
        const SizedBox(height: 6),
        ...items.map((item) {
          final i = item as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(i['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF212121))),
                          const SizedBox(width: 8),
                          if (i['frequency'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(i['frequency'], style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                            ),
                        ],
                      ),
                      if (i['desc'] != null)
                        Text(i['desc'], style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), height: 1.4)),
                    ],
                  ),
                ),
                if (i['difficulty'] != null)
                  Text(i['difficulty'], style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD))),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 今日节律（探索阶段）
  // ═══════════════════════════════════════════

  Widget _buildRhythmCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('今日节律', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeSlotRow(
            time: '07:00',
            label: '起床',
            icon: '🌅',
            color: ShunShiColors.gold,
          ),
          const SizedBox(height: 8),
          _buildTimeSlotRow(
            time: '12:00',
            label: '午休',
            icon: '😴',
            color: ShunShiColors.primaryLight,
          ),
          const SizedBox(height: 8),
          _buildTimeSlotRow(
            time: '23:00',
            label: '入睡',
            icon: '🌙',
            color: ShunShiColors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow({
    required String time,
    required String label,
    required String icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: ShunShiTypography.bodyMedium),
        ),
        Text(
          time,
          style: ShunShiTypography.labelMedium.copyWith(
            color: ShunShiColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 今日三件事（探索阶段）
  // ═══════════════════════════════════════════

  Widget _buildThreeThingsCard() {
    const things = [
      '早餐喝点温热的',
      '午后晒10分钟太阳',
      '晚上早点放下手机',
    ];
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('今日三件事', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...things.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ShunShiColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: ShunShiTypography.labelMedium.copyWith(
                          color: ShunShiColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text, style: ShunShiTypography.bodyMedium),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 心情记录（探索阶段）
  // ═══════════════════════════════════════════

  Widget _buildMoodCard() {
    const moods = [
      (emoji: '😊', label: '很好', value: 'good'),
      (emoji: '😐', label: '一般', value: 'okay'),
      (emoji: '😔', label: '低落', value: 'sad'),
      (emoji: '😢', label: '难过', value: 'bad'),
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💛', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('今天心情怎么样？', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moods.map((mood) {
              final isSelected = _selectedMood == mood.value;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMood = mood.value);
                  // TODO: 发送心情数据到后端
                },
                child: Container(
                  width: 64,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ShunShiColors.primary.withValues(alpha: 0.1)
                        : ShunShiColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: ShunShiColors.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: ShunShiTypography.caption.copyWith(
                          color: isSelected
                              ? ShunShiColors.primary
                              : ShunShiColors.textTertiary,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 今日养生（压力/健康阶段共用）
  // ═══════════════════════════════════════════

  Widget _buildWellnessCard() {
    return GestureDetector(
      onTap: () {
        // 跳转到当前节气详情
        final term = _solarTermName.isNotEmpty ? _solarTermName : _getCurrentSolarTerm();
        context.go('/solar-term-detail/$term');
      },
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_solarTermEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('$_solarTermName · 今日养生', style: ShunShiTypography.titleMedium),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: ShunShiColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _solarTermDesc,
              style: ShunShiTypography.bodySmall.copyWith(color: ShunShiColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ['饮食调理', '茶饮养生', '运动导引', '穴位保健', '睡眠起居'].map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tag, style: ShunShiTypography.caption.copyWith(color: ShunShiColors.primary, fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 养生分类入口卡片（饮食/茶饮/运动/穴位/睡眠）
  // ═══════════════════════════════════════════

  Widget _buildWellnessCategoryCards() {
    final categories = [
      ('food_therapy', '🥣', '食疗养生', '药食同源', const Color(0xFFE8A87C)),
      ('tea', '🍵', '茶饮推荐', '养生茶饮', const Color(0xFFA8D8B9)),
      ('exercise', '🧘', '运动导引', '舒筋活络', const Color(0xFF87CEEB)),
      ('acupoint', '✋', '穴位保健', '经络调理', const Color(0xFFDDA0DD)),
      ('sleep_tip', '😴', '睡眠调理', '安神助眠', const Color(0xFFB0C4DE)),
      ('emotion', '🌿', '情志调摄', '身心和谐', const Color(0xFF98D8C8)),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: categories.map((cat) {
        final type = cat.$1;
        return GestureDetector(
          onTap: () => context.go('/wellness-category/$type'),
          child: Container(
            decoration: BoxDecoration(
              color: ShunShiColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cat.$5.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cat.$5.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(cat.$2, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 8),
                Text(cat.$3, style: ShunShiTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                const SizedBox(height: 2),
                Text(cat.$4, style: ShunShiTypography.caption.copyWith(fontSize: 10, color: ShunShiColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════
  // 今日计划（早/中/晚）
  // ═══════════════════════════════════════════

  Widget _buildTodayPlanCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📅', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('今日计划', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (_morningPlan.isNotEmpty) ...[
            _buildPlanSlotGroup(
              label: '早晨',
              emoji: '🌅',
              slots: _morningPlan,
              accentColor: ShunShiColors.gold,
            ),
            const SizedBox(height: 16),
          ],
          if (_afternoonPlan.isNotEmpty) ...[
            _buildPlanSlotGroup(
              label: '午后',
              emoji: '☀️',
              slots: _afternoonPlan,
              accentColor: ShunShiColors.primaryLight,
            ),
            const SizedBox(height: 16),
          ],
          if (_eveningPlan.isNotEmpty)
            _buildPlanSlotGroup(
              label: '晚间',
              emoji: '🌙',
              slots: _eveningPlan,
              accentColor: ShunShiColors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildPlanSlotGroup({
    required String label,
    required String emoji,
    required List<_PlanSlot> slots,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ShunShiTypography.labelMedium.copyWith(
                  color: ShunShiColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              ...slots.map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(slot.title, style: ShunShiTypography.bodyMedium),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 本周趋势（压力阶段）
  // ═══════════════════════════════════════════

  Widget _buildWeeklyTrendCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('本周趋势', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendBar(
            label: '睡眠',
            emoji: '😴',
            progress: _sleepProgress,
            color: ShunShiColors.blue,
          ),
          const SizedBox(height: 14),
          _buildTrendBar(
            label: '运动',
            emoji: '🏃',
            progress: _exerciseProgress,
            color: ShunShiColors.primary,
          ),
          const SizedBox(height: 14),
          _buildTrendBar(
            label: '情绪',
            emoji: '😊',
            progress: _moodProgress,
            color: ShunShiColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar({
    required String label,
    required String emoji,
    required double progress,
    required Color color,
  }) {
    final percentage = (progress * 100).round();
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(label, style: ShunShiTypography.labelMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: ShunShiColors.surfaceVariant,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: ShunShiTypography.caption.copyWith(
              color: ShunShiColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 体质关注（健康阶段）
  // ═══════════════════════════════════════════

  Widget _buildConstitutionCard() {
    // 未测试 → 引导卡片
    if (!_hasConstitutionResult) {
      return GestureDetector(
        onTap: () => context.go('/constitution'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E7), Color(0xFFFFF0D4)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: ShunShiShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🔍', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('了解你的体质', style: ShunShiTypography.titleMedium.copyWith(
                          color: const Color(0xFFE65100),
                        )),
                        const SizedBox(height: 4),
                        Text('完成测试获取个性化养生方案', style: ShunShiTypography.bodySmall.copyWith(
                          color: const Color(0xFFFF8F00),
                        )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('去测试', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 三个亮点
              Row(
                children: [
                  _buildHighlight('📋', '60题科学评估'),
                  const SizedBox(width: 16),
                  _buildHighlight('🎯', '精准体质辨识'),
                  const SizedBox(width: 16),
                  _buildHighlight('🥗', '个性化饮食方案'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 已测试 → 显示结果
    final needRetest = _shouldRetestConstitution();
    return GestureDetector(
      onTap: () => context.go('/constitution'),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_kEmojiMap[_constitutionType] ?? '🫀', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('我的体质', style: ShunShiTypography.titleMedium),
                const Spacer(),
                if (needRetest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('可重测', style: TextStyle(color: Color(0xFFFF9800), fontSize: 11, fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShunShiColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_constitutionName, style: ShunShiTypography.caption.copyWith(
                      color: ShunShiColors.primary, fontSize: 11, fontWeight: FontWeight.w600,
                    )),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ShunShiColors.accentLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(_kEmojiMap[_constitutionType] ?? '💊', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_constitutionName, style: ShunShiTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          _kDescMap[_constitutionType] ?? '关注日常调养',
                          style: ShunShiTypography.bodySmall.copyWith(color: ShunShiColors.textSecondary),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (needRetest) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('体质可能已变化，建议重新测试', style: ShunShiTypography.bodySmall.copyWith(
                        color: const Color(0xFFE65100),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlight(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(text, style: ShunShiTypography.caption.copyWith(color: const Color(0xFF8D6E63))),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 节气食疗推荐（健康阶段）
  // ═══════════════════════════════════════════

  Widget _buildFoodRecommendCard() {
    final foods = _foodRecommendations.isNotEmpty
        ? _foodRecommendations
        : [
            const _FoodRecommend(name: '山药小米粥', benefit: '补脾胃、益肺气'),
            const _FoodRecommend(name: '黄芪炖鸡汤', benefit: '补气固表'),
            const _FoodRecommend(name: '枸杞菊花茶', benefit: '养肝明目'),
          ];

    return GestureDetector(
      onTap: () => context.go('/solar-term-detail/${Uri.encodeComponent(_solarTermName)}?season=$_getCurrentSeason()'),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
            children: [
              Text('🍲', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('节气食疗推荐', style: ShunShiTypography.titleMedium),
              Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ...foods.asMap().entries.map((entry) {
            final index = entry.key;
            final food = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🥣', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name, style: ShunShiTypography.titleMedium),
                          const SizedBox(height: 2),
                          Text(food.benefit, style: ShunShiTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 穴位调理（健康阶段）
  // ═══════════════════════════════════════════

  Widget _buildAcupointCard() {
    final points = _acupointItems.isNotEmpty
        ? _acupointItems
        : [
            const _AcupointItem(name: '足三里', desc: '补脾胃、增强免疫'),
            const _AcupointItem(name: '合谷穴', desc: '缓解头痛、安神'),
            const _AcupointItem(name: '太冲穴', desc: '疏肝理气、降压'),
          ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤲', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('穴位调理', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...points.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 10 : 0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ShunShiColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    point.name,
                    style: ShunShiTypography.titleMedium.copyWith(
                      color: ShunShiColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '— ${point.desc}',
                      style: ShunShiTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 语音输入大按钮（陪伴阶段）
  // ═══════════════════════════════════════════

  Widget _buildVoiceInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: ShunShiColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ShunShiColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.go('/chat'),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShunShiColors.primary,
                    ShunShiColors.primaryDark,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ShunShiColors.primary.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '按住说话',
            style: ShunShiTypography.titleMedium.copyWith(
              color: ShunShiColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 家庭关怀（陪伴阶段）
  // ═══════════════════════════════════════════

  Widget _buildFamilyCareCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('家庭关怀', style: ShunShiTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ShunShiColors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _familyCareText,
              style: ShunShiTypography.bodyMedium.copyWith(
                color: ShunShiColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 个性化推荐区域
  // ═══════════════════════════════════════════

  Widget _buildPersonalizedRecommendations() {
    // 加载中或无数据时不显示，避免转圈
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    const categoryMeta = {
      'food_therapy': ('🥣', '食疗推荐'),
      'tea': ('🍵', '茶饮推荐'),
      'exercise': ('🧘', '运动推荐'),
      'acupressure': ('✋', '穴位推荐'),
      'sleep_tip': ('😴', '睡眠建议'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('今日推荐', style: ShunShiTypography.titleMedium),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/library'),
                child: Row(
                  children: [
                    Text('查看更多', style: ShunShiTypography.caption.copyWith(color: ShunShiColors.primary)),
                    Icon(Icons.arrow_forward_ios, size: 12, color: ShunShiColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 各分类横向滚动
        ..._recommendations.entries.where((e) => e.value.isNotEmpty).map((entry) {
          final meta = categoryMeta[entry.key] ?? ('📋', '推荐');
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Row(
                    children: [
                      Text(meta.$1, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(meta.$2, style: ShunShiTypography.bodyMedium),
                    ],
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.value.length > 3 ? 3 : entry.value.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _buildRecommendCard(entry.value[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendCard(_RecommendItem item) {
    return GestureDetector(
      onTap: () => context.go('/content/${item.id}'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片
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
                      colors: [ShunShiColors.primary.withValues(alpha: 0.3), ShunShiColors.primary.withValues(alpha: 0.05)],
                    ),
                  ),
                  child: Center(child: Text(_typeEmoji(item.type ?? ''), style: const TextStyle(fontSize: 28))),
                ),
              ),
            ),
            // 文字区域
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildMatchBadge(item.matchScore),
                  const SizedBox(height: 4),
                  if (item.duration != null || item.difficulty != null)
                    Text(
                      '${item.duration ?? ''}${item.duration != null && item.difficulty != null ? ' · ' : ''}${item.difficulty ?? ''}',
                      style: ShunShiTypography.caption.copyWith(color: ShunShiColors.textTertiary),
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
    final color = score >= 85
        ? const Color(0xFF4CAF50)
        : score >= 65
            ? const Color(0xFFFF9800)
            : const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label ${score.toStringAsFixed(0)}%',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // AI 聊天入口
  // ═══════════════════════════════════════════

  Widget _buildAIEntry() {
    return _buildCard(
      child: GestureDetector(
        onTap: () => context.go('/chat'),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('💬', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                '和顺时聊聊',
                style: ShunShiTypography.bodyLarge,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: ShunShiColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Data Models (local)
// ═══════════════════════════════════════════

class _PlanSlot {
  final String icon;
  final String title;
  final String subtitle;

  const _PlanSlot({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _FoodRecommend {
  final String name;
  final String benefit;

  const _FoodRecommend({required this.name, required this.benefit});
}

class _AcupointItem {
  final String name;
  final String desc;

  const _AcupointItem({required this.name, required this.desc});
}

class _RecommendItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? type;
  final double? matchScore;
  final String? duration;
  final String? difficulty;
  final List<String> tags;

  const _RecommendItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.type,
    this.matchScore,
    this.duration,
    this.difficulty,
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
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}