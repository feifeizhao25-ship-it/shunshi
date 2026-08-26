/// 体质辨识测试页 V3 — 接 API
/// GET /questions → 25题, POST /submit → 体质结果, GET /types → 9种体质详情
library;

import 'package:dio/dio.dart';
import '../../../data/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ConstitutionTestV2 extends StatefulWidget {
  const ConstitutionTestV2({super.key});

  @override
  State<ConstitutionTestV2> createState() => _ConstitutionTestV2State();
}

class _ConstitutionTestV2State extends State<ConstitutionTestV2> {
  static const _baseUrl = 'https://api.seasonsapp.com';
  final _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 8)));

  List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _answers = {}; // question_id → answer_index
  int _current = 0;
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final res = await _dio.get('/questions');
      if (res.data is List) {
        _questions = (res.data as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      // Use saved token, fallback to guest login
      String? token = StorageManager.user.getToken();
      if (token == null) {
        final authRes = await _dio.post('/api/v1/auth/guest-login', data: {});
        final d = authRes.data;
        token = d is Map ? (d['data'] ?? d)['token'] : null;
      }

      // Map answers: option index → score (0=是→3, 1=有时→2, 2=否→1)
      final scores = <String, int>{};
      _answers.forEach((qId, optIdx) {
        scores[qId.toString()] = [3, 2, 1][optIdx.clamp(0, 2)];
      });

      final res = await _dio.post('/submit',
        data: {'answers': scores},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data is Map && res.data['data'] is Map) {
        _result = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (e) {
      // Fallback: calculate locally from answers
      _result = _calculateLocal();
    }

    setState(() => _submitting = false);
  }

  Map<String, dynamic> _calculateLocal() {
    // Simple local scoring: count answer patterns
    final typeNames = ['Balanced', 'Qi Deficiency', 'Yang Deficiency', 'Yin Deficiency', 'Phlegm-Dampness', 'Damp-Heat', 'Blood Stasis', 'Qi Stagnation', 'Special Diathesis'];
    final scores = List.filled(9, 0);
    _answers.forEach((qId, optIdx) {
      final score = [3, 2, 1][optIdx.clamp(0, 2)];
      final typeIdx = ((qId - 1) % 9);
      scores[typeIdx] += score;
    });
    final maxIdx = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    return {
      'primary_type': typeNames[maxIdx],
      'scores': {for (int i = 0; i < 9; i++) typeNames[i]: scores[i]},
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: ShunShiColors.background, body: Center(child: CircularProgressIndicator(color: ShunShiColors.primary)));
    if (_result != null) return _buildResult();
    if (_questions.isEmpty) return Scaffold(backgroundColor: ShunShiColors.background, body: Center(child: Text('No questions available', style: TextStyle(color: ShunShiColors.textTertiary))));

    final q = _questions[_current];
    final options = (q['options'] as List?)?.cast<String>() ?? ['Yes', 'Sometimes', 'No'];

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(child: Column(children: [
        // Progress
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: [
            GestureDetector(onTap: _current > 0 ? () => setState(() => _current--) : null,
              child: Container(width: 36, height: 36, decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.arrow_back, size: 18, color: _current > 0 ? ShunShiColors.textPrimary : ShunShiColors.textTertiary))),
            const Spacer(),
            Text('Constitution Analysis', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
            const Spacer(),
            Text('${_current + 1}/${_questions.length}', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
          ]),
        ),
        // Progress bar
        Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: (_current + 1) / _questions.length,
              backgroundColor: ShunShiColors.surface, color: ShunShiColors.primary, minHeight: 4)),
        ),
        const Spacer(),
        // Question
        Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(q['question'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary, height: 1.4),
            textAlign: TextAlign.center),
        ),
        const SizedBox(height: 40),
        // Options
        ...options.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: GestureDetector(
            onTap: () {
              setState(() => _answers[q['id'] as int] = e.key);
              // Auto advance after short delay
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_current < _questions.length - 1) {
                  setState(() => _current++);
                } else {
                  _submit();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _answers[q['id']] == e.key ? ShunShiColors.primary.withOpacity(0.08) : ShunShiColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _answers[q['id']] == e.key ? ShunShiColors.primary : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _answers[q['id']] == e.key ? ShunShiColors.primary : Colors.transparent,
                  border: Border.all(color: _answers[q['id']] == e.key ? ShunShiColors.primary : ShunShiColors.borderGhost),
                ), child: _answers[q['id']] == e.key ? Icon(Icons.check, size: 14, color: Colors.white) : null),
                const SizedBox(width: 12),
                Text(e.value, style: TextStyle(fontSize: 15, color: _answers[q['id']] == e.key ? ShunShiColors.primary : ShunShiColors.textPrimary)),
              ]),
            ),
          ),
        )),
        const Spacer(flex: 2),
      ])),
    );
  }

  Widget _buildResult() {
    final typeName = _result?['primary_type']?.toString() ?? 'Balanced';
    final scores = _result?['scores'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Column(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
              borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.self_improvement, color: Colors.white, size: 36)),
            const SizedBox(height: 16),
            Text('Your Constitution Type', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            const SizedBox(height: 4),
            Text(typeName, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.primary)),
          ])),
          const SizedBox(height: 24),
          // Score chart
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Constitution Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 16),
              ...scores.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(width: 60, child: Text(e.key, style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary))),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: (e.value as int) / 15,
                      backgroundColor: ShunShiColors.surfaceContainerLow, color: e.key == typeName ? ShunShiColors.primary : ShunShiColors.textTertiary.withOpacity(0.3), minHeight: 8))),
                  const SizedBox(width: 8),
                  Text('${e.value}', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 20),
          // Recommendations
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
            borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_awesome, color: Color(0xFFE4C285), size: 18),
                const SizedBox(width: 8),
                Text('Wellness Tips', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
              const SizedBox(height: 10),
              Text('Based on your $typeName profile, focus on diet and daily routine. Consult the AI wellness assistant for personalized guidance.',
                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() {_result = null; _answers.clear(); _current = 0;}),
              style: OutlinedButton.styleFrom(side: BorderSide(color: ShunShiColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: Size(0, 48)),
              child: Text('Retake', style: TextStyle(color: ShunShiColors.primary)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: Size(0, 48)),
              child: Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          ]),
        ]),
      )),
    );
  }
}
