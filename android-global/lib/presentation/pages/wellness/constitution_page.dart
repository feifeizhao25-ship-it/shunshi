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
import '../../../core/theme/app_localizations.dart';

import 'widgets/constitution_data.dart';
import 'widgets/constitution_widgets.dart';
import 'widgets/constitution_home_widget.dart';
import 'widgets/constitution_quiz_widget.dart';
import 'widgets/constitution_result_widget.dart';
import '../../../core/network/api_singleton.dart';

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
          final sectionRegex = RegExp(r'\*\*(.+?)[:：]\*\*\s*');
          final splits = sectionRegex.allMatches(adviceText);
          final sectionTitles = splits.map((m) => m.group(1)!.trim()).toList();
          final sectionContents = adviceText.split(sectionRegex).where((s) => s.trim().isNotEmpty).toList();

          final sectionMeta = {
            'Characteristics': ('📝', 'Characteristics'),
            'Diet Advice': ('🥗', 'Dietary Care'),
            'TeaRecommended': ('🍵', 'TeaRecommended'),
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
              HealthAdvice(category: 'TeaRecommended', icon: '🍵', items: [(kConstitutionAdvice[primaryType]?['Tea'] ?? '')]),
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
              HealthAdvice(category: 'Diet Advice', icon: '🥗', items: [(data['diet_advice'] as String? ?? '').split(': ').last]),
              HealthAdvice(category: 'TeaRecommended', icon: '🍵', items: [(data['tea_advice'] as String? ?? '').split('：').last]),
              HealthAdvice(category: 'Exercise Advice', icon: '🏃', items: [(data['exercise_advice'] as String? ?? '').split('：').last]),
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
          HealthAdvice(category: 'TeaRecommended', icon: '🍵', items: [adv['Tea'] ?? '']),
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

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context).get('constitution_your_type'), style: ShunshiTextStyles.greeting),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context).get('constitution_test'), style: ShunshiTextStyles.bodySecondary),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: _startQuiz,
          style: ElevatedButton.styleFrom(backgroundColor: ShunshiColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(AppLocalizations.of(context).get('constitution_start_test'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 32),
        Text(AppLocalizations.of(context).get('constitution_title'), style: ShunshiTextStyles.heading),
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
                  Text('Question ${_currentIndex + 1} / ${_questions.length}', style: ShunshiTextStyles.caption),
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
        //  questions目
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
                      return QuizOptionCard(index: entry.key, option: entry.value, questionId: question.id, isSelected: isSelected, onTap: (i) => setState(() => _answers[question.id] = i));
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
                      child: const Text('Previous', style: TextStyle(fontSize: 15)),
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
                    child: Text(_currentIndex == _questions.length - 1 && _answers.length == _questions.length ? 'Submit Answers' : 'Next', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. 结果报告（核Heart付费转化页） ──

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();
    final r = _result!;
    final isFree = !_reportUnlocked;

    return Stack(children: [
      ListView(padding: EdgeInsets.only(bottom: isFree ? 220 : 80), children: [
        // ── 顶部Body Type卡片 ──
        _buildResultHero(r),
        const SizedBox(height: 20),

        // ── Free部分：Body Type概述 + 分数条 ──
        _buildSection('Overview', '📋', [
          Text(r.description, style: const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.7)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: r.characteristics.map((c) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Text(c, style: const TextStyle(fontSize: 12, color: ShunshiColors.primaryDark, fontWeight: FontWeight.w500)))).toList()),
        ]),
        _buildScoreBars(r),
        const SizedBox(height: 20),

        // ── 付费部分 / 已Unlock部分 ──
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
        Text('Your Body Type is', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        Text(r.typeName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text('Test Date: ${DateTime.now().toString().substring(0, 16)}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }

  Widget _buildSection(String title, String icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(icon, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _buildScoreBars(ConstitutionResult r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Text('📊', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('Body Type Scores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))]),
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
            if (level == 'obvious') const Text('Deviation', style: TextStyle(fontSize: 10, color: ShunshiColors.earth)) else if (level == 'tendency') const Text('Tendency', style: TextStyle(fontSize: 10, color: Color(0xFFD4956A))),
          ]));
        }),
      ]),
    );
  }

  /// Free用户看到的模糊预览（诱导付费）
  List<Widget> _buildBlurredSections(ConstitutionResult r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return r.advice.map((adv) => Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16)),
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
          const Row(children: [Text('⚠️', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Text('Precautions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF92400E)))]),
          const SizedBox(height: 10),
          Text(r.avoidList, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.7)),
        ])),
    ];
  }

  /// 底部操作栏
  Widget _buildBottomBar(ConstitutionResult r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!_reportUnlocked) ...[
          // 付费墙提示
          Container(width: double.infinity, padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFFFF7ED), const Color(0xFFFFF1E0)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5A84B).withValues(alpha: 0.3))),
            child: Row(children: [
              const Text('👑', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Unlock Full Body Type Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                SizedBox(height: 2),
                Text('Diet · Tea · Exercise · Acupressure · Four Seasons Plan', style: TextStyle(fontSize: 11, color: Color(0xFFB07937))),
              ])),
              Icon(Icons.chevron_right, color: const Color(0xFFD4956A).withValues(alpha: 0.6)),
            ]),
          ),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () { _unlockReport(); setState(() {}); },
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('Unlock Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A84B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ]),
        ] else ...[
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { setState(() { _view = 'home'; _questions.clear(); _answers.clear(); _result = null; }); },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retest', style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(foregroundColor: ShunshiColors.primary, side: const BorderSide(color: ShunshiColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _shareResult(r),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: ShunshiColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 46, child: OutlinedButton.icon(
            onPressed: () => _downloadReport(r),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download Report', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(foregroundColor: ShunshiColors.textSecondary, side: const BorderSide(color: ShunshiColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ])),
    );
  }

  Future<void> _shareResult(ConstitutionResult r) async {
    final text = '[SEASONS TCM Body Type Report]\n\n'
        'Body Type: ${r.typeName} ${r.emoji}\n'
        'Overview: ${r.description}\n\n'
        'Characteristics:\n${r.characteristics.map((c) => '  · $c').join('\n')}\n\n'
        '—— SEASONS AI Wellness Advisor';
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Report copied to clipboard');
  }

  Future<void> _downloadReport(ConstitutionResult r) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('╔══════════════════════════════════════╗');
      buffer.writeln('║      SEASONS TCM Body Type Report         ║');
      buffer.writeln('╚══════════════════════════════════════╝');
      buffer.writeln();
      buffer.writeln('Report ID: ${r.resultId}');
      buffer.writeln('Test Date：${DateTime.now().toString().substring(0, 19)}');
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('  Your Body Type');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('  ${r.emoji}  ${r.typeName}');
      buffer.writeln();
      buffer.writeln('  ${r.description}');
      buffer.writeln();
      buffer.writeln('  Characteristics:');
      for (final c in r.characteristics) { buffer.writeln('    · $c'); }
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('  Score Analysis');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      for (final s in r.scores) {
        final name = s['name'] as String? ?? '';
        final score = (s['score'] as num?)?.toDouble() ?? 0;
        final level = s['level'] as String? ?? '';
        final levelText = level == 'obvious' ? ' [Deviation]' : level == 'tendency' ? ' [Tendency]' : '';
        final barLen = (score / 60 * 20).round();
        final bar = '█' * barLen + '░' * (20 - barLen);
        buffer.writeln('  $name  $bar  ${score.toStringAsFixed(0)}pts $levelText');
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
        buffer.writeln('  ⚠️ Precautions');
        buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        buffer.writeln();
        buffer.writeln('  $r.avoidList');
        buffer.writeln();
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
      buffer.writeln('  This report was generated by SEASONS AI Wellness Advisor');
      buffer.writeln('  For reference only, not medical advice');
      buffer.writeln('  For health questions please consult a licensed TCM practitioner');
      buffer.writeln();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/SEASONS_BodyType_Report_${r.typeName}.txt');
      await file.writeAsString(buffer.toString());

      if (mounted) _showSnackBar('Report saved: ${file.path}');
    } catch (e) {
      if (mounted) _showSnackBar('Save failed');
    }
  }

  // ── 4. Body TypeDetails ──

  Widget _buildDetailView() {
    if (_detail == null) return const SizedBox.shrink();
    return ConstitutionDetailView(detail: _detail!);
  }
}
