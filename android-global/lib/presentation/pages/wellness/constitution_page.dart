import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../data/network/api_client.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../core/theme/app_localizations.dart';

import 'widgets/constitution_data.dart';
import 'widgets/constitution_widgets.dart';
import 'widgets/constitution_home_widget.dart';
import 'widgets/constitution_quiz_widget.dart';
import 'widgets/constitution_result_widget.dart';

// Models imported from constitution_data.dart

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
  List<ConstitutionType> _types = kConstitutionTypes;
  String _view = 'home'; // home / quiz / result / detail
  ConstitutionDetail? _detail;
  bool _reportUnlocked = false; // Whether full report is unlocked

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
    final isSubscribed = prefs.getBool('is_subscribed') ?? false;
    _reportUnlocked = isSubscribed || (prefs.getBool('constitution_report_unlocked') ?? false);
  }

  Future<void> _unlockReport() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('is_subscribed') ?? false;
    if (!isSubscribed) {
      // WeiSubscription，跳转Subscription页
      if (mounted) context.push('/subscription');
      return;
    }
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
              return ConstitutionType(key: key, name: m['name'] as String? ?? '', emoji: kConstitutionEmoji[key] ?? '📋', description: m['description'] as String? ?? '');
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
          _showSnackBar(' Questionnaire is empty, please try again later');
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
        _showSnackBar('Failed to load questions (${res.statusCode})');
      }
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionTimeout
          ? 'Connection timed out, please check your network'
          : e.type == DioExceptionType.connectionError
              ? 'Cannot connect to server, please check your network settings'
              : 'Network error: ${e.message}';
      _showSnackBar(msg);
    } catch (e) {
      // Fallback to local 12-question data
      if (_questions.isEmpty) {
        setState(() {
          _questions = kBodyTypeQuestions;
          _currentIndex = 0;
          _answers.clear();
          _view = 'quiz';
        });
      }
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
        // 后端Back {"success": true, "data": {...}}
        final Map<String, dynamic> data;
        if (res.data is Map<String, dynamic> && (res.data as Map<String, dynamic>).containsKey('data')) {
          data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        } else if (res.data is Map<String, dynamic>) {
          data = res.data as Map<String, dynamic>;
        } else {
          _showSnackBar('Submit failed: invalid data format from server');
          return;
        }
        final primaryType = data['primary_type'] as String? ?? '';
        final primaryName = data['primary_name'] as String? ?? '';
        final secondaryNames = (data['secondary_types'] as List<dynamic>? ?? []).cast<String>();
        final scoreList = (data['scores'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList();

        // SaveBody Type结果到This 地
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('constitution_type', primaryType);
        await prefs.setString('constitution_name', primaryName);
        await prefs.setString('constitution_secondary', jsonEncode(secondaryNames));
        await prefs.setString('constitution_scores', jsonEncode(scoreList));
        await prefs.setString('constitution_test_date', DateTime.now().toIso8601String());
        await prefs.setString('constitution_result_id', data['result_id'] as String? ?? '');

        setState(() {
          // 解析后端Back的详细建议
          final adviceText = data['advice'] as String? ?? '';
          final adviceList = <HealthAdvice>[];

          // 按 **标 questions:** 拆分段落
          final sectionRegex = RegExp(r'\*\*(.+?)[:\uff1a]\*\*\s*');
          final splits = sectionRegex.allMatches(adviceText);
          final sectionTitles = splits.map((m) => m.group(1)!.trim()).toList();
          final sectionContents = adviceText.split(sectionRegex).where((s) => s.trim().isNotEmpty).toList();

          final sectionMeta = {
            'Characteristics': ('📝', 'Characteristics'),
            'Diet Advice': ('🥗', 'Dietary Care'),
            'Recommended Teas': ('🍵', 'TeaRecommended'),
            'Exercise Advice': ('🏃', 'Exercise Advice'),
            'Precautions': ('⚠️', 'Precautions'),
            'Daily Care': ('🌙', 'Daily Care'),
            'Emotional Care': ('🌿', 'Emotional Care'),
            'Acupressure Care': ('✋', 'Acupressure Care'),
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

          // 如果后端没解析出内容，用This 地常量兜底
          if (adviceList.isEmpty) {
            adviceList.addAll([
              HealthAdvice(category: 'Dietary Care', icon: '🥗', items: [(kConstitutionAdvice[primaryType]?['Diet'] ?? '')]),
              HealthAdvice(category: 'Recommended Teas', icon: '🍵', items: [(kConstitutionAdvice[primaryType]?['Tea'] ?? '')]),
              HealthAdvice(category: 'Exercise Advice', icon: '🏃', items: [(kConstitutionAdvice[primaryType]?['Exercise'] ?? '')]),
            ]);
          }

          // 兼有Body Type
          if (secondaryNames.isNotEmpty) {
            adviceList.add(HealthAdvice(category: 'Secondary Tendency', icon: '⚡', items: secondaryNames));
          }

          _result = ConstitutionResult(
            resultId: data['result_id'] as String? ?? '',
            typeKey: primaryType,
            typeName: primaryName,
            emoji: kConstitutionEmoji[primaryType] ?? '📋',
            description: kConstitutionDesc[primaryType] ?? '',
            characteristics: kConstitutionChars[primaryType] ?? [],
            advice: adviceList,
            scores: scoreList,
            avoidList: (kConstitutionAvoid[primaryType] ?? []).join(', '),
            isPremium: _reportUnlocked,
          );
          _view = 'result';
        });
      } else {
        _showSnackBar('Submit failed, please try again later');
      }
    } catch (e) {
      // Fallback: local scoring
      _localScore();
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Local fallback scoring using kQuestionTypeMap
  void _localScore() {
    final scores = <String, int>{};
    for (final entry in _answers.entries) {
      final type = kQuestionTypeMap[entry.key];
      if (type != null) {
        scores[type] = (scores[type] ?? 0) + entry.value;
      }
    }
    // Find primary type (highest score)
    String primary = 'pinghe';
    int maxScore = 0;
    for (final e in scores.entries) {
      if (e.value > maxScore) { maxScore = e.value; primary = e.key; }
    }
    final typeName = kConstitutionTypes.firstWhere((t) => t.key == primary, orElse: () => kConstitutionTypes.last).name;
    setState(() {
      _result = ConstitutionResult(
        resultId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        typeKey: primary, typeName: typeName, emoji: kConstitutionEmoji[primary] ?? '📋',
        description: kConstitutionDesc[primary] ?? '',
        characteristics: kConstitutionChars[primary] ?? [],
        advice: (kConstitutionAdvice[primary] ?? {}).entries.map((e) => HealthAdvice(category: e.key, icon: '', items: [e.value])).toList(),
        scores: scores.entries.map((e) => {'type': e.key, 'name': kConstitutionTypes.firstWhere((t) => t.key == e.key, orElse: () => kConstitutionTypes.last).name, 'score': e.value}).toList(),
        avoidList: (kConstitutionAvoid[primary] ?? []).join(', '),
      );
      _view = 'result';
    });
    // Save locally
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('constitution_type', primary);
      prefs.setString('constitution_name', typeName);
      prefs.setString('constitution_test_date', DateTime.now().toIso8601String());
    });
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
            name: data['name'] as String? ?? '', emoji: kConstitutionEmoji[key] ?? '📋',
            description: data['description'] as String? ?? '', characteristics: chars,
            advice: [
              HealthAdvice(category: 'Diet Advice', icon: '🥗', items: [(data['diet_advice'] as String? ?? '').split(RegExp(r'[:\uff1a]\s*')).last]),
              HealthAdvice(category: 'Recommended Teas', icon: '🍵', items: [(data['tea_advice'] as String? ?? '').split(RegExp(r'[:\uff1a]\s*')).last]),
              HealthAdvice(category: 'Exercise Advice', icon: '🏃', items: [(data['exercise_advice'] as String? ?? '').split(RegExp(r'[:\uff1a]\s*')).last]),
            ],
            avoidList: avoid.join(', '),
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
    final local = kConstitutionTypes.firstWhere((t) => t.key == key, orElse: () => kConstitutionTypes.last);
    final adv = kConstitutionAdvice[key] ?? {};
    setState(() {
      _detail = ConstitutionDetail(
        name: local.name, emoji: local.emoji, description: local.description,
        characteristics: kConstitutionChars[key] ?? [],
        advice: [
          HealthAdvice(category: 'Diet Advice', icon: '🥗', items: [adv['Diet'] ?? '']),
          HealthAdvice(category: 'Recommended Teas', icon: '🍵', items: [adv['Tea'] ?? '']),
          HealthAdvice(category: 'Exercise Advice', icon: '🏃', items: [adv['Exercise'] ?? '']),
        ],
        avoidList: (kConstitutionAvoid[key] ?? []).join(', '),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_view == 'quiz') {
            if (_currentIndex > 0) {
              setState(() => _currentIndex--);
            } else {
              setState(() => _view = 'home');
            }
          } else if (_view == 'home') {
            context.go('/home');
          } else {
            setState(() => _view = 'home');
          }
        }
      },
      child: Scaffold(
      backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
      appBar: AppBar(
        title: Text(_view == 'home' ? AppLocalizations.of(context).get('constitution_test') : _view == 'quiz' ? '${AppLocalizations.of(context).get('constitution_test')} (${_currentIndex + 1}/${_questions.length})' : _view == 'result' ? AppLocalizations.of(context).get('constitution_result') : AppLocalizations.of(context).get('constitution_title'), style: ShunshiTextStyles.heading),
        leading: IconButton(icon: Icon(Icons.chevron_left, color: ShunshiColors.textPrimary), onPressed: () {
          if (_view == 'quiz') { if (_currentIndex > 0) {
            setState(() => _currentIndex--);
          } else {
            setState(() => _view = 'home');
          } }
          else if (_view == 'home') context.go('/home');
          else setState(() => _view = 'home');
        }),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(key: ValueKey(_view), child: switch (_view) {
                'quiz' => ConstitutionQuizWidget(
                    questions: _questions,
                    currentIndex: _currentIndex,
                    answers: _answers,
                    onAnswer: (i) => setState(() => _answers[_questions[_currentIndex].id] = i),
                    onNext: () => setState(() => _currentIndex++),
                    onPrev: () => setState(() => _currentIndex--),
                    onSubmit: _submitQuiz,
                  ),
                'result' => ConstitutionResultWidget(
                    result: _result!,
                    reportUnlocked: _reportUnlocked,
                    onUnlock: _unlockReport,
                    onRetest: () => setState(() { _view = 'home'; _questions.clear(); _answers.clear(); _result = null; }),
                    onViewDetail: () { _showDetail(_result!.typeName); },
                    onShare: () {},
                  ),
                'detail' => ConstitutionDetailView(detail: _detail!),
                _ => ConstitutionHomeWidget(
                    types: _types,
                    onStartQuiz: _startQuiz,
                    onShowDetail: (type) => _showDetail(type.key),
                  ),
              }),
            ),
      ),
    );
  }

  // ── 1. Home ──


  // ── 2. 问卷 ──


  // ── 3. 结果报告（核Heart付费转化页） ──





  /// Free用户看到的模糊预览（诱导付费）

  /// 付费用户的完整报告

  /// 底部操作栏



  // ── 4. Body TypeDetails ──

}
