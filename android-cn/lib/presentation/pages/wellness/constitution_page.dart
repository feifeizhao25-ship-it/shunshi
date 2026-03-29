import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../data/network/api_client.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';

// ── 数据模型 ──────────────────────────────────────────

class ConstitutionType {
  final String key;
  final String name;
  final String emoji;
  final String description;
  const ConstitutionType({required this.key, required this.name, required this.emoji, required this.description});
}

class QuestionOption {
  final int score;
  final String text;
  const QuestionOption({required this.score, required this.text});
}

class Question {
  final int id;
  final String text;
  final List<QuestionOption> options;
  const Question({required this.id, required this.text, required this.options});
}

class HealthAdvice {
  final String category;
  final String icon;
  final List<String> items;
  const HealthAdvice({required this.category, this.icon = '', required this.items});
}

class ConstitutionResult {
  final String resultId;
  final String typeKey;
  final String typeName;
  final String emoji;
  final String description;
  final List<String> characteristics;
  final List<HealthAdvice> advice;
  final List<Map<String, dynamic>> scores;
  final String avoidList;
  final bool isPremium;
  const ConstitutionResult({
    required this.resultId, required this.typeKey, required this.typeName,
    required this.emoji, required this.description, required this.characteristics,
    required this.advice, required this.scores, this.avoidList = '', this.isPremium = false,
  });
}

class ConstitutionDetail {
  final String name;
  final String emoji;
  final String description;
  final List<String> characteristics;
  final List<HealthAdvice> advice;
  final String avoidList;
  const ConstitutionDetail({required this.name, required this.emoji, required this.description, required this.characteristics, required this.advice, required this.avoidList});
}

// ── 本地常量 ──────────────────────────────────────────

const List<ConstitutionType> _kConstitutionTypes = [
  ConstitutionType(key: 'qixu', name: '气虚质', emoji: '😰', description: '元气不足，易疲乏气短'),
  ConstitutionType(key: 'yangxu', name: '阳虚质', emoji: '🥶', description: '阳气不足，畏寒怕冷'),
  ConstitutionType(key: 'yinxu', name: '阴虚质', emoji: '🔥', description: '阴液亏少，口燥咽干'),
  ConstitutionType(key: 'tanshi', name: '痰湿质', emoji: '😪', description: '痰湿凝聚，体形肥胖'),
  ConstitutionType(key: 'shire', name: '湿热质', emoji: '🤢', description: '湿热内蕴，面垢油光'),
  ConstitutionType(key: 'xueyu', name: '血瘀质', emoji: '😣', description: '血行不畅，肤色晦暗'),
  ConstitutionType(key: 'qiyu', name: '气郁质', emoji: '😔', description: '气机郁滞，神情抑郁'),
  ConstitutionType(key: 'tebing', name: '特禀质', emoji: '🤧', description: '先天失常，易过敏'),
  ConstitutionType(key: 'pinghe', name: '平和质', emoji: '😊', description: '阴阳调和，体态适中'),
];

const Map<String, String> _kEmojiMap = {
  'pinghe': '😊', 'qixu': '😰', 'yangxu': '🥶', 'yinxu': '🔥',
  'tanshi': '😪', 'shire': '🤢', 'xueyu': '😣', 'qiyu': '😔', 'tebing': '🤧',
};

const Map<String, String> _kDescMap = {
  'pinghe': '阴阳气血调和，体态适中，面色润泽，精力充沛，睡眠良好',
  'qixu': '元气不足，易疲乏，气短懒言，易出汗，易感冒',
  'yangxu': '阳气不足，手脚发凉，畏寒怕冷，精神不振',
  'yinxu': '体内阴液亏少，口燥咽干，手足心热，盗汗',
  'tanshi': '痰湿凝聚，形体肥胖，腹部肥满松软，口黏腻',
  'shire': '湿热内蕴，面垢油光，口苦口干，身重困倦',
  'xueyu': '血行不畅，肤色晦暗，容易出现瘀斑',
  'qiyu': '气机郁滞，神情抑郁，忧虑脆弱',
  'tebing': '先天禀赋不足或过敏体质，易过敏',
};

const Map<String, List<String>> _kCharsMap = {
  'pinghe': ['体形匀称健壮', '面色润泽红润', '精力充沛', '睡眠良好', '食欲正常', '二便调畅'],
  'qixu': ['容易疲乏', '气短懒言', '容易出汗', '容易感冒', '声音低弱', '舌淡红，舌体胖大'],
  'yangxu': ['手足不温', '畏寒怕冷', '精神不振', '面色柔白', '喜热饮食', '舌淡胖嫩'],
  'yinxu': ['口燥咽干', '手足心热', '鼻微干', '喜冷饮', '大便干燥', '面色潮红'],
  'tanshi': ['体形肥胖', '面部油脂较多', '多汗且黏', '口黏腻', '身重不爽', '嗜食肥甘'],
  'shire': ['面垢油光', '易生痤疮', '口苦口干', '身重困倦', '大便黏滞不畅', '小便短黄'],
  'xueyu': ['肤色晦暗', '色素沉着', '容易出现瘀斑', '口唇暗淡', '眼眶暗黑', '舌暗有瘀点'],
  'qiyu': ['神情抑郁', '情感脆弱', '烦闷不乐', '多愁善感', '胸胁胀满', '善太息'],
  'tebing': ['过敏体质', '易患哮喘', '容易打喷嚏', '鼻塞流涕', '皮肤易起荨麻疹'],
};

const Map<String, Map<String, String>> _kAdviceMap = {
  'pinghe': {'饮食': '饮食有节，不偏食偏嗜，粗细搭配，荤素均衡', '茶饮': '四季均可饮用绿茶、菊花茶等平和茶饮', '运动': '适度运动，散步、太极拳、游泳均可'},
  'qixu': {'饮食': '多食益气健脾食物：黄芪、人参、山药、大枣、小米、糯米、扁豆', '茶饮': '黄芪红枣茶、人参茶、党参茶', '运动': '舒缓运动为主：散步、太极拳、八段锦，避免剧烈运动'},
  'yangxu': {'饮食': '多食温阳散寒食物：羊肉、生姜、桂圆、韭菜、核桃、栗子、红枣', '茶饮': '姜枣茶、桂圆红茶、肉桂茶', '运动': '多晒太阳，适合户外运动，太极拳、艾灸足三里'},
  'yinxu': {'饮食': '多食滋阴润燥食物：银耳、百合、雪梨、枸杞、黑芝麻、鸭肉、甲鱼', '茶饮': '百合银耳茶、枸杞菊花茶、麦冬茶', '运动': '中小强度运动，游泳、瑜伽、慢跑，避免大汗'},
  'tanshi': {'饮食': '少食肥甘厚腻，多食健脾利湿食物：薏米、赤小豆、冬瓜、荷叶、陈皮', '茶饮': '荷叶茶、薏米红豆茶、陈皮茶、山楂茶', '运动': '加强有氧运动，快走、慢跑、游泳，控制体重'},
  'shire': {'饮食': '多食清热利湿食物：绿豆、苦瓜、冬瓜、黄瓜、薏米、莲藕', '茶饮': '金银花茶、菊花茶、荷叶茶、绿豆汤', '运动': '中等强度有氧运动，游泳最佳，适合夏季户外活动'},
  'xueyu': {'饮食': '多食活血化瘀食物：山楂、红花、玫瑰花、黑豆、醋、黑木耳', '茶饮': '玫瑰花茶、山楂茶、红花茶、三七茶', '运动': '适当运动促进气血运行，太极拳、瑜伽、舞蹈'},
  'qiyu': {'饮食': '多食疏肝理气食物：玫瑰花、佛手、柑橘、萝卜、荞麦、金针菇', '茶饮': '玫瑰花茶、茉莉花茶、佛手茶、合欢花茶', '运动': '多参加户外运动和社交活动，跑步、登山、唱歌、舞蹈'},
  'tebing': {'饮食': '饮食清淡，避免过敏源。多食益气固表食物：黄芪、大枣、山药、灵芝', '茶饮': '黄芪红枣茶、灵芝茶、防风茶', '运动': '适度运动增强体质，游泳、散步、太极拳'},
};

const Map<String, List<String>> _kAvoidMap = {
  'pinghe': [], 'qixu': ['过度劳累', '大汗淋漓', '生冷食物', '熬夜', '剧烈运动'],
  'yangxu': ['生冷食物', '寒凉环境', '过度吹空调', '冰饮', '寒性水果'],
  'yinxu': ['辛辣食物', '煎炸食物', '熬夜', '过度运动', '羊肉等温热食物'],
  'tanshi': ['肥甘厚腻', '甜食', '酒类', '久坐不动', '生冷食物'],
  'shire': ['辛辣食物', '油腻食物', '酒类', '煎炸食物', '熬夜'],
  'xueyu': ['久坐不动', '寒凉环境', '情绪压抑', '过度安逸'],
  'qiyu': ['长期压抑情绪', '过度思虑', '久坐不动', '独处寡言'],
  'tebing': ['已知过敏食物', '花粉环境', '冷空气', '新装修环境', '宠物毛发'],
};

// ── 页面 ──────────────────────────────────────────────

class ConstitutionPage extends StatefulWidget {
  const ConstitutionPage({super.key});

  @override
  State<ConstitutionPage> createState() => _ConstitutionPageState();
}

class _ConstitutionPageState extends State<ConstitutionPage> {
  final ApiClient _api = ApiClient();
  bool _loading = false;
  List<Question> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  ConstitutionResult? _result;
  List<ConstitutionType> _types = _kConstitutionTypes;
  String _view = 'home'; // home / quiz / result / detail
  ConstitutionDetail? _detail;
  bool _reportUnlocked = false; // 是否已解锁完整报告

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _checkPremium();
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) {
      userId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', userId);
    }
    return userId;
  }

  Future<void> _checkPremium() async {
    final prefs = await SharedPreferences.getInstance();
    _reportUnlocked = prefs.getBool('constitution_report_unlocked') ?? false;
  }

  Future<void> _unlockReport() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('constitution_report_unlocked', true);
    if (mounted) setState(() => _reportUnlocked = true);
  }

  Future<void> _loadTypes() async {
    try {
      final res = await _api.get('/api/v1/constitution/types');
      if (res.statusCode == 200 && res.data is List) {
        final list = res.data as List;
        if (list.isNotEmpty) {
          setState(() {
            _types = list.map((e) {
              final m = e as Map<String, dynamic>;
              final key = m['type'] as String? ?? '';
              return ConstitutionType(key: key, name: m['name'] as String? ?? '', emoji: _kEmojiMap[key] ?? '📋', description: m['description'] as String? ?? '');
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/api/v1/constitution/questions').timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 && res.data is List) {
        final list = res.data as List;
        if (list.isEmpty) {
          _showSnackBar('题目为空，请稍后重试');
          return;
        }
        setState(() {
          _questions = list.map((e) {
            final m = e as Map<String, dynamic>;
            final opts = (m['options'] as List<dynamic>? ?? []).cast<String>();
            final scores = [5, 3, 1];
            return Question(
              id: m['id'] as int? ?? 0,
              text: m['question'] as String? ?? m['text'] as String? ?? '',
              options: opts.asMap().entries.map((entry) => QuestionOption(score: entry.key < scores.length ? scores[entry.key] : 1, text: entry.value)).toList(),
            );
          }).toList();
          _currentIndex = 0;
          _answers.clear();
          _view = 'quiz';
        });
      } else {
        _showSnackBar('获取题目失败 (${res.statusCode})');
      }
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionTimeout
          ? '连接超时，请检查网络'
          : e.type == DioExceptionType.connectionError
              ? '无法连接服务器，请检查网络设置'
              : '网络异常: ${e.message}';
      _showSnackBar(msg);
    } catch (e) {
      _showSnackBar('加载失败: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _loading = true);
    try {
      final userId = await _getUserId();
      final answersData = _answers.entries.map((e) => {'question_id': e.key, 'option_index': e.value}).toList();
      final res = await _api.post('/api/v1/constitution/submit', data: {'user_id': userId, 'answers': answersData});
      if (res.statusCode == 200 && res.data != null) {
        // 后端返回 {"success": true, "data": {...}}
        final Map<String, dynamic> data;
        if (res.data is Map<String, dynamic> && (res.data as Map<String, dynamic>).containsKey('data')) {
          data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        } else if (res.data is Map<String, dynamic>) {
          data = res.data as Map<String, dynamic>;
        } else {
          _showSnackBar('提交失败：返回数据格式异常');
          return;
        }
        final primaryType = data['primary_type'] as String? ?? '';
        final primaryName = data['primary_name'] as String? ?? '';
        final secondaryNames = (data['secondary_types'] as List<dynamic>? ?? []).cast<String>();
        final scoreList = (data['scores'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList();

        // 保存体质结果到本地
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('constitution_type', primaryType);
        await prefs.setString('constitution_name', primaryName);
        await prefs.setString('constitution_secondary', jsonEncode(secondaryNames));
        await prefs.setString('constitution_scores', jsonEncode(scoreList));
        await prefs.setString('constitution_test_date', DateTime.now().toIso8601String());
        await prefs.setString('constitution_result_id', data['result_id'] as String? ?? '');

        setState(() {
          // 解析后端返回的详细建议
          final adviceText = data['advice'] as String? ?? '';
          final adviceList = <HealthAdvice>[];

          // 按 **标题:** 拆分段落
          final sectionRegex = RegExp(r'\*\*(.+?)[:：]\*\*\s*');
          final splits = sectionRegex.allMatches(adviceText);
          final sectionTitles = splits.map((m) => m.group(1)!.trim()).toList();
          final sectionContents = adviceText.split(sectionRegex).where((s) => s.trim().isNotEmpty).toList();

          final sectionMeta = {
            '体质特点': ('📝', '体质特点'),
            '饮食建议': ('🥗', '饮食调养'),
            '茶饮推荐': ('🍵', '茶饮推荐'),
            '运动建议': ('🏃', '运动建议'),
            '注意事项': ('⚠️', '注意事项'),
            '起居建议': ('🌙', '起居建议'),
            '情志调摄': ('🌿', '情志调摄'),
            '穴位保健': ('✋', '穴位保健'),
          };

          for (var i = 0; i < sectionTitles.length && i < sectionContents.length; i++) {
            final title = sectionTitles[i];
            final content = sectionContents[i].trim();
            if (content.isEmpty) continue;
            final meta = sectionMeta[title] ?? ('📋', title);
            adviceList.add(HealthAdvice(
              category: meta.$2,
              icon: meta.$1,
              items: [content],
            ));
          }

          // 如果后端没解析出内容，用本地常量兜底
          if (adviceList.isEmpty) {
            adviceList.addAll([
              HealthAdvice(category: '饮食调养', icon: '🥗', items: [(_kAdviceMap[primaryType]?['饮食'] ?? '')]),
              HealthAdvice(category: '茶饮推荐', icon: '🍵', items: [(_kAdviceMap[primaryType]?['茶饮'] ?? '')]),
              HealthAdvice(category: '运动建议', icon: '🏃', items: [(_kAdviceMap[primaryType]?['运动'] ?? '')]),
            ]);
          }

          // 兼有体质
          if (secondaryNames.isNotEmpty) {
            adviceList.add(HealthAdvice(category: '兼有倾向', icon: '⚡', items: secondaryNames));
          }

          _result = ConstitutionResult(
            resultId: data['result_id'] as String? ?? '',
            typeKey: primaryType,
            typeName: primaryName,
            emoji: _kEmojiMap[primaryType] ?? '📋',
            description: _kDescMap[primaryType] ?? '',
            characteristics: _kCharsMap[primaryType] ?? [],
            advice: adviceList,
            scores: scoreList,
            avoidList: (_kAvoidMap[primaryType] ?? []).join('、'),
            isPremium: _reportUnlocked,
          );
          _view = 'result';
        });
      } else {
        _showSnackBar('提交失败，请稍后重试');
      }
    } catch (e) {
      _showSnackBar('提交失败，请检查网络');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDetail(String key) async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/api/v1/constitution/types/$key');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final chars = (data['characteristics'] as List<dynamic>? ?? []).cast<String>();
        final avoid = (data['avoid_list'] as List<dynamic>? ?? []).cast<String>();
        setState(() {
          _detail = ConstitutionDetail(
            name: data['name'] as String? ?? '', emoji: _kEmojiMap[key] ?? '📋',
            description: data['description'] as String? ?? '', characteristics: chars,
            advice: [
              HealthAdvice(category: '饮食建议', icon: '🥗', items: [(data['diet_advice'] as String? ?? '').split('：').last]),
              HealthAdvice(category: '茶饮推荐', icon: '🍵', items: [(data['tea_advice'] as String? ?? '').split('：').last]),
              HealthAdvice(category: '运动建议', icon: '🏃', items: [(data['exercise_advice'] as String? ?? '').split('：').last]),
            ],
            avoidList: avoid.join('、'),
          );
          _view = 'detail';
        });
      } else {
        _showDetailLocal(key);
      }
    } catch (_) {
      _showDetailLocal(key);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showDetailLocal(String key) {
    final local = _kConstitutionTypes.firstWhere((t) => t.key == key, orElse: () => _kConstitutionTypes.last);
    final adv = _kAdviceMap[key] ?? {};
    setState(() {
      _detail = ConstitutionDetail(
        name: local.name, emoji: local.emoji, description: local.description,
        characteristics: _kCharsMap[key] ?? [],
        advice: [
          HealthAdvice(category: '饮食建议', icon: '🥗', items: [adv['饮食'] ?? '']),
          HealthAdvice(category: '茶饮推荐', icon: '🍵', items: [adv['茶饮'] ?? '']),
          HealthAdvice(category: '运动建议', icon: '🏃', items: [adv['运动'] ?? '']),
        ],
        avoidList: (_kAvoidMap[key] ?? []).join('、'),
      );
      _view = 'detail';
    });
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_view == 'quiz') {
            if (_currentIndex > 0) setState(() => _currentIndex--);
            else setState(() => _view = 'home');
          } else if (_view == 'home') {
            context.go('/home');
          } else {
            setState(() => _view = 'home');
          }
        }
      },
      child: Scaffold(
      backgroundColor: ShunshiColors.background,
      appBar: AppBar(
        title: Text(_view == 'home' ? '体质测试' : _view == 'quiz' ? '体质测试 (${_currentIndex + 1}/${_questions.length})' : _view == 'result' ? '测试结果' : '体质详情', style: ShunshiTextStyles.heading),
        backgroundColor: ShunshiColors.surface, foregroundColor: ShunshiColors.textPrimary, elevation: 0,
        leading: IconButton(icon: Icon(Icons.chevron_left, color: ShunshiColors.textPrimary), onPressed: () {
          if (_view == 'quiz') { if (_currentIndex > 0) setState(() => _currentIndex--); else setState(() => _view = 'home'); }
          else if (_view == 'home') context.go('/home');
          else setState(() => _view = 'home');
        }),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunshiColors.primary))
          : AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: KeyedSubtree(key: ValueKey(_view), child: switch (_view) { 'quiz' => _buildQuiz(), 'result' => _buildResult(), 'detail' => _buildDetail(), _ => _buildHome(), })),
      ),
    );
  }

  // ── 1. 首页 ──

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('了解你的体质', style: ShunshiTextStyles.greeting),
        const SizedBox(height: 8),
        Text('中医体质辨识，找到最适合你的养生之道', style: ShunshiTextStyles.bodySecondary),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: _startQuiz,
          style: ElevatedButton.styleFrom(backgroundColor: ShunshiColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('开始测试', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 32),
        Text('九种体质', style: ShunshiTextStyles.heading),
        const SizedBox(height: 16),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _types.length, itemBuilder: (context, index) {
          final type = _types[index];
          return GestureDetector(
            onTap: () => _showDetail(type.key),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: ShunshiColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ShunshiColors.divider)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.15), shape: BoxShape.circle), child: Center(child: Text(type.emoji, style: const TextStyle(fontSize: 26)))),
              const SizedBox(height: 8),
              Text(type.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary)),
              const SizedBox(height: 4),
              Text(type.description, style: ShunshiTextStyles.labelSmall, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          );
        }),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── 2. 问卷 ──

  Widget _buildQuiz() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    return Column(
      children: [
        // 进度条
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('第 ${_currentIndex + 1} 题 / ${_questions.length}', style: ShunshiTextStyles.caption),
                  Text('${(progress * 100).toInt()}%', style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: ShunshiColors.divider, valueColor: const AlwaysStoppedAnimation(ShunshiColors.primary)),
              ),
            ],
          ),
        ),
        // 题目
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(question.id),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(question.text, style: ShunshiTextStyles.heading),
                    const SizedBox(height: 24),
                    ...question.options.asMap().entries.map((entry) {
                      final isSelected = _answers[question.id] == entry.key;
                      return _buildOptionCard(entry.key, entry.value, question.id, isSelected);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 底部按钮
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                if (_currentIndex > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(foregroundColor: ShunshiColors.textSecondary, side: const BorderSide(color: ShunshiColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('上一题', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _answers.containsKey(question.id) && _currentIndex < _questions.length - 1
                        ? () => setState(() => _currentIndex++)
                        : _answers.length == _questions.length ? _submitQuiz : null,
                    style: ElevatedButton.styleFrom(backgroundColor: ShunshiColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: ShunshiColors.divider, disabledForegroundColor: ShunshiColors.textHint, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(_currentIndex == _questions.length - 1 && _answers.length == _questions.length ? '提交答卷' : '下一题', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(int index, QuestionOption opt, int questionId, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _answers[questionId] = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? ShunshiColors.primaryLight.withValues(alpha: 0.2) : ShunshiColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? ShunshiColors.primary : ShunshiColors.divider, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(color: isSelected ? ShunshiColors.primary : null, shape: BoxShape.circle, border: isSelected ? null : Border.all(color: ShunshiColors.textHint)),
                child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(opt.text, style: TextStyle(fontSize: 15, color: isSelected ? ShunshiColors.primaryDark : ShunshiColors.textPrimary, fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400))),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3. 结果报告（核心付费转化页） ──

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();
    final r = _result!;
    final isFree = !_reportUnlocked;

    return Stack(children: [
      ListView(padding: EdgeInsets.only(bottom: isFree ? 220 : 80), children: [
        // ── 顶部体质卡片 ──
        _buildResultHero(r),
        const SizedBox(height: 20),

        // ── 免费部分：体质概述 + 分数条 ──
        _buildSection('体质概述', '📋', [
          Text(r.description, style: const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.7)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: r.characteristics.map((c) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Text(c, style: const TextStyle(fontSize: 12, color: ShunshiColors.primaryDark, fontWeight: FontWeight.w500)))).toList()),
        ]),
        _buildScoreBars(r),
        const SizedBox(height: 20),

        // ── 付费部分 / 已解锁部分 ──
        if (isFree) ...[
          // 模糊遮罩预览
          ..._buildBlurredSections(r),
        ] else ...[
          ..._buildPremiumSections(r),
        ],

        const SizedBox(height: 100),
      ]),

      // ── 底部付费墙 / 操作栏 ──
      Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar(r)),
    ]);
  }

  Widget _buildResultHero(ConstitutionResult r) {
    return Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ShunshiColors.primary, ShunshiColors.primaryDark]), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
      child: Column(children: [
        Text(r.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text('你的体质是', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        Text(r.typeName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text('测试时间: ${DateTime.now().toString().substring(0, 16)}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }

  Widget _buildSection(String title, String icon, List<Widget> children) {
    return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(icon, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _buildScoreBars(ConstitutionResult r) {
    return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Text('📊', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('体质分数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))]),
        const SizedBox(height: 14),
        ...r.scores.map((s) {
          final name = s['name'] as String? ?? '';
          final score = (s['score'] as num?)?.toDouble() ?? 0;
          final level = s['level'] as String? ?? 'normal';
          final maxScore = 60.0;
          final ratio = (score / maxScore).clamp(0.0, 1.0);
          final isPrimary = name == r.typeName;
          final barColor = isPrimary ? ShunshiColors.primary : (ratio > 0.5 ? ShunshiColors.earth : ShunshiColors.primaryLight);
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
            SizedBox(width: 60, child: Text(name, style: TextStyle(fontSize: 12, color: isPrimary ? ShunshiColors.primaryDark : ShunshiColors.textSecondary, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w400))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: ShunshiColors.divider, valueColor: AlwaysStoppedAnimation(barColor)))),
            const SizedBox(width: 8),
            SizedBox(width: 28, child: Text(score.toStringAsFixed(0), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPrimary ? ShunshiColors.primaryDark : ShunshiColors.textPrimary))),
            const SizedBox(width: 4),
            if (level == 'obvious') const Text('偏颇', style: TextStyle(fontSize: 10, color: ShunshiColors.earth)) else if (level == 'tendency') const Text('倾向', style: TextStyle(fontSize: 10, color: Color(0xFFD4956A))),
          ]));
        }),
      ]),
    );
  }

  /// 免费用户看到的模糊预览（诱导付费）
  List<Widget> _buildBlurredSections(ConstitutionResult r) {
    return r.advice.map((adv) => Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(adv.icon, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(adv.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))]),
          const SizedBox(height: 14),
          ...adv.items.take(2).map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(item, style: const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.6)))),
        ]),
        Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: Container(color: Colors.white.withValues(alpha: 0.3)))),
      ])),
    )).toList();
  }

  /// 付费用户的完整报告
  List<Widget> _buildPremiumSections(ConstitutionResult r) {
    return [
      ...r.advice.map((adv) => _buildSection(adv.category, adv.icon, [
        ...adv.items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 8), decoration: const BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.7))),
        ]))),
      ])),
      if (r.avoidList.isNotEmpty) Container(margin: const EdgeInsets.fromLTRB(20, 12, 20, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Text('⚠️', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Text('注意事项', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF92400E)))]),
          const SizedBox(height: 10),
          Text(r.avoidList, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.7)),
        ])),
    ];
  }

  /// 底部操作栏
  Widget _buildBottomBar(ConstitutionResult r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!_reportUnlocked) ...[
          // 付费墙提示
          Container(width: double.infinity, padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFFFF7ED), const Color(0xFFFFF1E0)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5A84B).withValues(alpha: 0.3))),
            child: Row(children: [
              const Text('👑', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('解锁完整体质报告', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                SizedBox(height: 2),
                Text('饮食·茶饮·运动·穴位·四季调理方案', style: TextStyle(fontSize: 11, color: Color(0xFFB07937))),
              ])),
              Icon(Icons.chevron_right, color: const Color(0xFFD4956A).withValues(alpha: 0.6)),
            ]),
          ),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () { _unlockReport(); setState(() {}); },
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('解锁报告', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A84B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ]),
        ] else ...[
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { setState(() { _view = 'home'; _questions.clear(); _answers.clear(); _result = null; }); },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新测试', style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(foregroundColor: ShunshiColors.primary, side: const BorderSide(color: ShunshiColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _shareResult(r),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('分享结果', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: ShunshiColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 46, child: OutlinedButton.icon(
            onPressed: () => _downloadReport(r),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('下载报告', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(foregroundColor: ShunshiColors.textSecondary, side: const BorderSide(color: ShunshiColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ])),
    );
  }

  Future<void> _shareResult(ConstitutionResult r) async {
    final text = '【顺时·中医体质报告】\n\n'
        '我的体质类型：${r.typeName} ${r.emoji}\n'
        '体质概述：${r.description}\n\n'
        '体质特点：\n${r.characteristics.map((c) => '  · $c').join('\n')}\n\n'
        '—— 顺时App AI养生顾问';
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('报告已复制到剪贴板');
  }

  Future<void> _downloadReport(ConstitutionResult r) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('╔══════════════════════════════════════╗');
      buffer.writeln('║        顺时·中医体质评估报告         ║');
      buffer.writeln('╚══════════════════════════════════════╝');
      buffer.writeln();
      buffer.writeln('报告编号：${r.resultId}');
      buffer.writeln('测试时间：${DateTime.now().toString().substring(0, 19)}');
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('  你的体质类型');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('  ${r.emoji}  ${r.typeName}');
      buffer.writeln();
      buffer.writeln('  ${r.description}');
      buffer.writeln();
      buffer.writeln('  体质特点：');
      for (final c in r.characteristics) { buffer.writeln('    · $c'); }
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('  体质分数分析');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      for (final s in r.scores) {
        final name = s['name'] as String? ?? '';
        final score = (s['score'] as num?)?.toDouble() ?? 0;
        final level = s['level'] as String? ?? '';
        final levelText = level == 'obvious' ? ' [偏颇]' : level == 'tendency' ? ' [倾向]' : '';
        final barLen = (score / 60 * 20).round();
        final bar = '█' * barLen + '░' * (20 - barLen);
        buffer.writeln('  $name  $bar  ${score.toStringAsFixed(0)}分$levelText');
      }
      buffer.writeln();
      for (final adv in r.advice) {
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln('  ${adv.icon} ${adv.category}');
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln();
        for (final item in adv.items) { buffer.writeln('  $item'); }
        buffer.writeln();
      }
      if (r.avoidList.isNotEmpty) {
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln('  ⚠️ 注意事项');
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln();
        buffer.writeln('  $r.avoidList');
        buffer.writeln();
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('  本报告由「顺时」AI养生顾问生成');
      buffer.writeln('  仅供参考，不构成医疗建议');
      buffer.writeln('  如有健康问题请咨询专业中医师');
      buffer.writeln();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/顺时体质报告_${r.typeName}.txt');
      await file.writeAsString(buffer.toString());

      if (mounted) _showSnackBar('报告已保存：${file.path}');
    } catch (e) {
      if (mounted) _showSnackBar('保存失败');
    }
  }

  // ── 4. 体质详情 ──

  Widget _buildDetail() {
    if (_detail == null) return const SizedBox.shrink();
    final d = _detail!;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 32)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.name, style: ShunshiTextStyles.greeting),
          const SizedBox(height: 4),
          Text(d.description, style: ShunshiTextStyles.bodySecondary, maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
      const SizedBox(height: 24),
      if (d.characteristics.isNotEmpty) ...[_buildDetailSection('体质特点', d.characteristics), const SizedBox(height: 20)],
      ...d.advice.expand((adv) => [_buildDetailSection('${adv.icon} ${adv.category}', adv.items), const SizedBox(height: 20)]),
      if (d.avoidList.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ShunshiColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: ShunshiColors.warning.withValues(alpha: 0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: ShunshiColors.earth), const SizedBox(width: 10),
          Expanded(child: Text('注意事项: ${d.avoidList}', style: ShunshiTextStyles.bodySecondary.copyWith(color: ShunshiColors.textPrimary))),
        ])),
      const SizedBox(height: 32),
    ]));
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary)),
      const SizedBox(height: 10),
      ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 8), decoration: const BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(item, style: ShunshiTextStyles.bodySecondary)),
      ]))),
    ]);
  }
}
