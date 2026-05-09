/// 体质辨识测试页 V3 — 接 API
/// GET /questions → 25题, POST /submit → 体质结果, GET /types → 9种体质详情
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ConstitutionTestV2 extends StatefulWidget {
  const ConstitutionTestV2({super.key});

  @override
  State<ConstitutionTestV2> createState() => _ConstitutionTestV2State();
}

class _ConstitutionTestV2State extends State<ConstitutionTestV2> {
  static const _baseUrl = 'http://116.62.32.43:4000';
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
      final res = await _dio.get('/api/v1/constitution/questions');
      if (res.data is List) {
        _questions = (res.data as List).cast<Map<String, dynamic>>();
      } else if (res.data is Map && res.data['data'] is List) {
        _questions = (res.data['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    // Fallback: hardcoded questions if API fails
    if (_questions.isEmpty) {
      _questions = _buildFallbackQuestions();
    }
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _buildFallbackQuestions() {
    final texts = [
      '您精力充沛吗？', '您容易疲乏吗？', '您容易气短（呼吸短促）吗？',
      '您容易心慌吗？', '您容易头晕或站起时眩晕吗？', '您容易失眠吗？',
      '您感到手脚冰凉吗？', '您怕冷吗（衣服比别人穿得多）？', '您感觉身体沉重或不轻松吗？',
      '您吃（喝）凉的东西会感到不舒服吗？', '您感到口干舌燥吗？', '您感到口苦或嘴里有异味吗？',
      '您面部或鼻部有油腻感或者油亮发光吗？', '您腹痛吗？', '您大便黏滞不爽（容易粘马桶）吗？',
      '您大便干燥吗？', '您小便时尿道有发热感、尿色浓（深）吗？', '您手脚心发热吗？',
      '您的皮肤在不知不觉中会出现青紫瘀斑吗？', '您两颧部有红斑或肤色暗沉吗？', '您眼睛干涩吗？',
      '您感到郁闷、不高兴吗？', '您容易感冒吗？', '您没有感冒也会打喷嚏吗？',
      '您起荨麻疹（风疹块、风疙瘩）吗？',
    ];
    return [for (int i = 0; i < texts.length; i++)
      {'id': i + 1, 'question': texts[i], 'options': ['是，经常这样', '有时是这样', '不，很少这样']}
    ];
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      // Get token first
      final authRes = await _dio.post('/api/v1/auth/guest-login', data: {});
      final token = authRes.data['data']['token'];

      // Map answers: option index → score (0=是→3, 1=有时→2, 2=否→1)
      final scores = <String, int>{};
      _answers.forEach((qId, optIdx) {
        scores[qId.toString()] = [3, 2, 1][optIdx.clamp(0, 2)];
      });

      final res = await _dio.post('/api/v1/constitution/assess',
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
    final typeNames = ['平和质', '气虚质', '阳虚质', '阴虚质', '痰湿质', '湿热质', '血瘀质', '气郁质', '特禀质'];
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    if (_loading) return Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: ShunShiColors.primary)));
    if (_result != null) return _buildResult();
    if (_questions.isEmpty) return Scaffold(backgroundColor: bg, body: Center(child: Text('暂无题目', style: TextStyle(color: ShunShiColors.textTertiary))));

    final q = _questions[_current];
    final options = (q['options'] as List?)?.cast<String>() ?? ['是', '有时是', '否'];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: Column(children: [
        // Progress
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: [
            GestureDetector(onTap: _current > 0 ? () => setState(() => _current--) : null,
              child: Container(width: 36, height: 36, decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.arrow_back, size: 18, color: _current > 0 ? ShunShiColors.textPrimary : ShunShiColors.textTertiary))),
            const Spacer(),
            Text('体质辨识', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
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
    final typeName = _result?['primary_type']?.toString() ?? '平和质';
    final scores = _result?['scores'] as Map<String, dynamic>? ?? {};
    final bg = Theme.of(context).brightness == Brightness.dark ? ShunShiColors.darkBackground : ShunShiColors.background;

    // 养生建议 by type
    final advice = _getAdvice(typeName);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Center(child: Column(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
              borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.self_improvement, color: Colors.white, size: 36)),
            const SizedBox(height: 16),
            Text('您的体质类型', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            const SizedBox(height: 4),
            Text(typeName, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.primary)),
          ])),
          const SizedBox(height: 24),

          // Score chart
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('体质得分', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 16),
              ...scores.entries.map((e) {
                final val = (e.value is int) ? (e.value as int) : ((e.value as num?)?.toInt() ?? 0);
                final maxVal = scores.values.fold(0, (m, v) => (v is int ? v : ((v as num?)?.toInt() ?? 0)) > m ? (v is int ? v : ((v as num?)?.toInt() ?? 0)) : m).clamp(1, 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(width: 60, child: Text(e.key, style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary))),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: (val / maxVal).clamp(0.0, 1.0),
                        backgroundColor: ShunShiColors.surfaceContainerLow, color: e.key == typeName ? ShunShiColors.primary : ShunShiColors.textTertiary.withOpacity(0.3), minHeight: 8))),
                    const SizedBox(width: 8),
                    Text('$val', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),

          // Advice cards
          ...advice.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: a['color'] as Color, borderRadius: BorderRadius.circular(10)),
                  child: Icon(a['icon'] as IconData, size: 18, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(a['desc'] as String, style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary, height: 1.5)),
                ])),
              ]),
            ),
          )),

          // Buttons
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() {_result = null; _answers.clear(); _current = 0;}),
              style: OutlinedButton.styleFrom(side: BorderSide(color: ShunShiColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: Size(0, 48)),
              child: Text('重新测试', style: TextStyle(color: ShunShiColors.primary)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: Size(0, 48)),
              child: Text('完成', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          ]),
        ]),
      )),
    );
  }

  List<Map<String, dynamic>> _getAdvice(String typeName) {
    const adviceMap = <String, List<Map<String, dynamic>>>{
      '平和质': [
        {'title': '饮食调养', 'desc': '饮食有节，不偏食，五谷杂粮均衡。顺应四时，春养肝夏养心秋养肺冬养肾。', 'icon': Icons.restaurant, 'color': Color(0xFF4CAF50)},
        {'title': '运动调养', 'desc': '适度运动，太极、散步即可。保持规律作息，不熬夜。', 'icon': Icons.self_improvement, 'color': Color(0xFF2196F3)},
      ],
      '气虚质': [
        {'title': '饮食调养', 'desc': '补气为主：黄芪、山药、大枣、小米粥。忌生冷寒凉、过度劳累。', 'icon': Icons.restaurant, 'color': Color(0xFFFF9800)},
        {'title': '运动调养', 'desc': '柔和运动：太极、八段锦，避免大汗。气虚不宜剧烈运动。', 'icon': Icons.self_improvement, 'color': Color(0xFF2196F3)},
        {'title': '起居调养', 'desc': '保证充足睡眠，避免过度劳累。午间小憩有益补气。', 'icon': Icons.bedtime, 'color': Color(0xFF9C27B0)},
      ],
      '阳虚质': [
        {'title': '饮食调养', 'desc': '温补阳气：生姜、羊肉、韭菜、桂圆。忌生冷寒凉。', 'icon': Icons.restaurant, 'color': Color(0xFFF44336)},
        {'title': '运动调养', 'desc': '上午运动为佳，晒太阳，避免受寒。三伏天可冬病夏治。', 'icon': Icons.wb_sunny, 'color': Color(0xFFFF9800)},
      ],
      '阴虚质': [
        {'title': '饮食调养', 'desc': '滋阴润燥：银耳、百合、枸杞、鸭肉。忌辛辣烧烤。', 'icon': Icons.restaurant, 'color': Color(0xFF009688)},
        {'title': '运动调养', 'desc': '不宜大汗，游泳、瑜伽为宜。秋季重点养阴。', 'icon': Icons.pool, 'color': Color(0xFF2196F3)},
      ],
      '痰湿质': [
        {'title': '饮食调养', 'desc': '健脾化痰：薏米、冬瓜、陈皮茶，少甜腻。忌肥甘厚味。', 'icon': Icons.restaurant, 'color': Color(0xFF795548)},
        {'title': '运动调养', 'desc': '有氧运动为主，跑步、快走。梅雨季节注意祛湿。', 'icon': Icons.directions_run, 'color': Color(0xFF4CAF50)},
      ],
      '湿热质': [
        {'title': '饮食调养', 'desc': '清热祛湿：绿豆、薏米、苦瓜、菊花茶。忌辛辣油腻。', 'icon': Icons.restaurant, 'color': Color(0xFFFF5722)},
        {'title': '运动调养', 'desc': '游泳、中强度运动排汗。夏季重点清热，避免潮湿环境。', 'icon': Icons.pool, 'color': Color(0xFF2196F3)},
      ],
      '血瘀质': [
        {'title': '饮食调养', 'desc': '活血化瘀：山楂、黑木耳、玫瑰花茶。忌寒凉凝滞。', 'icon': Icons.restaurant, 'color': Color(0xFFE91E63)},
        {'title': '运动调养', 'desc': '规律运动促进血液循环，春季疏肝活血，避免久坐。', 'icon': Icons.directions_walk, 'color': Color(0xFF4CAF50)},
      ],
      '气郁质': [
        {'title': '饮食调养', 'desc': '疏肝解郁：玫瑰花、佛手、柑橘类。忌郁闷生气。', 'icon': Icons.local_florist, 'color': Color(0xFFE91E63)},
        {'title': '运动调养', 'desc': '户外运动、团体活动、唱歌。春季重点疏肝，保持心情舒畅。', 'icon': Icons.hiking, 'color': Color(0xFF4CAF50)},
      ],
      '特禀质': [
        {'title': '饮食调养', 'desc': '清淡饮食，避免已知过敏原。增强脾胃功能。', 'icon': Icons.restaurant, 'color': Color(0xFF607D8B)},
        {'title': '运动调养', 'desc': '适度运动增强免疫力，换季时注意防护。', 'icon': Icons.self_improvement, 'color': Color(0xFF2196F3)},
      ],
    };
    return adviceMap[typeName] ?? adviceMap['平和质']!;
  }
}
