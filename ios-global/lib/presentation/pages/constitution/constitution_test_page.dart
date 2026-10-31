import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

/// 体质测试页 — 20 题 5 选项问卷 + 结果页
class ConstitutionTestFlowPage extends StatefulWidget {
  const ConstitutionTestFlowPage({super.key});

  @override
  State<ConstitutionTestFlowPage> createState() => _ConstitutionTestFlowPageState();
}

class _ConstitutionTestFlowPageState extends State<ConstitutionTestFlowPage> {
  int _current = 0;
  final List<int> _answers = List.filled(20, -1);
  bool _showResult = false;
  bool _submitting = false;
  final _pageController = PageController();

  static const _types = ['平和', '气虚', '阳虚', '阴虚', '痰湿', '湿热', '血瘀', '气郁', '特禀'];

  static const _questions = [
    _Q('你容易感到疲劳吗？', '气虚'),
    _Q('你容易手脚发凉吗？', '阳虚'),
    _Q('你容易口干咽燥吗？', '阴虚'),
    _Q('你容易出汗吗？', '气虚'),
    _Q('你体型偏胖吗？', '痰湿'),
    _Q('你容易长痘吗？', '湿热'),
    _Q('你面色偏暗或有斑点吗？', '血瘀'),
    _Q('你容易情绪低落吗？', '气郁'),
    _Q('你容易过敏吗？', '特禀'),
    _Q('你睡眠质量好吗？', '平和', reverse: true),
    _Q('你食欲正常吗？', '平和', reverse: true),
    _Q('你容易感冒吗？', '气虚'),
    _Q('你怕热吗？', '阴虚'),
    _Q('你大便偏稀吗？', '阳虚'),
    _Q('你口中有粘腻感吗？', '痰湿'),
    _Q('你小便颜色偏黄吗？', '湿热'),
    _Q('你皮肤容易有青紫斑吗？', '血瘀'),
    _Q('你容易紧张焦虑吗？', '气郁'),
    _Q('你对药物比较敏感吗？', '特禀'),
    _Q('你精力充沛吗？', '平和', reverse: true),
  ];

  static const _optionLabels = ['从不', '很少', '有时', '经常', '总是'];

  Map<String, int> _calculateScores() {
    final scores = <String, int>{for (final t in _types) t: 0};
    for (var i = 0; i < _answers.length; i++) {
      final a = _answers[i];
      if (a < 0) continue;
      final q = _questions[i];
      var score = a + 1; // 1-5
      if (q.reverse) score = 6 - score; // reverse: 5→1, 4→2, etc.
      scores[q.type] = scores[q.type]! + score;
    }
    return scores;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final scores = _calculateScores();
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final primary = sorted.isNotEmpty ? sorted[0].key : '平和';
    final secondary = sorted.length > 1 ? sorted[1].key : '平和';

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final dio = Dio(BaseOptions(baseUrl: 'https://api.seasonsapp.com'));
      await dio.post('/api/v1/constitution/submit', data: {
        'user_id': userId,
        'primary_type': primary,
        'secondary_type': secondary,
        'scores': scores,
      });
    } catch (_) {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('constitution_result', '$primary|$secondary');
      await prefs.setString('constitution_scores', scores.entries.map((e) => '${e.key}:${e.value}').join(','));
    }

    setState(() {
      _submitting = false;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResult();
    return _buildQuiz();
  }

  Widget _buildQuiz() {
    final progress = (_current + 1) / _questions.length;
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_current > 0) {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              setState(() => _current--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text('体质测试 ${_current + 1}/20',
            style: const TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: ShunShiColors.divider,
                valueColor: const AlwaysStoppedAnimation(ShunShiColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 20,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                final q = _questions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.text,
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600,
                            fontFamily: ShunShiTypography.serifFamily,
                            color: ShunShiColors.textPrimary, height: 1.5,
                          )),
                      const SizedBox(height: 32),
                      ...List.generate(5, (i) {
                        final selected = _answers[index] == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _answers[index] = i),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: selected
                                    ? ShunShiColors.primary.withValues(alpha: 0.08)
                                    : ShunShiColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? ShunShiColors.primary : ShunShiColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected ? ShunShiColors.primary : Colors.transparent,
                                    border: Border.all(color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary),
                                  ),
                                  child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 12),
                                Text(_optionLabels[i],
                                    style: TextStyle(
                                      fontSize: 15, fontFamily: ShunShiTypography.sansFamily,
                                      color: selected ? ShunShiColors.primary : ShunShiColors.textPrimary,
                                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                                    )),
                                const Spacer(),
                                Text('${i + 1}分',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary,
                                    )),
                              ]),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _answers[_current] < 0 ? null : () {
                  if (_current < 19) {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    setState(() => _current++);
                  } else {
                    _submit();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  disabledBackgroundColor: ShunShiColors.textDisabled,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_current < 19 ? '下一题' : '查看结果',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final scores = _calculateScores();
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final primary = sorted.isNotEmpty ? sorted[0].key : '平和';
    final secondary = sorted.length > 1 ? sorted[1].key : null;
    final maxScore = sorted.isNotEmpty ? sorted[0].value.toDouble() : 1.0;

    final descriptions = {
      '平和': '阴阳气血调和，体态适中，面色润泽，精力充沛。这是最健康的体质类型。',
      '气虚': '元气不足，疲乏气短，容易感冒，面色偏白。需补气健脾。',
      '阳虚': '阳气不足，手足不温，怕冷喜暖。需温阳散寒。',
      '阴虚': '阴液亏少，口燥咽干，手足心热。需滋阴降火。',
      '痰湿': '痰湿凝聚，形体肥胖，腹部松软。需化痰祛湿。',
      '湿热': '湿热内蕴，面垢油光，口苦口干。需清热利湿。',
      '血瘀': '血行不畅，肤色晦暗，容易出现瘀斑。需活血化瘀。',
      '气郁': '气机郁滞，情绪低落，胸胁胀痛。需疏肝解郁。',
      '特禀': '先天禀赋不足，容易过敏。需益气固表。',
    };

    final dietAdvice = {
      '平和': '饮食均衡，五谷杂粮、蔬果搭配，不宜偏食。',
      '气虚': '宜食山药、黄芪、红枣、小米粥。忌生冷寒凉。',
      '阳虚': '宜食羊肉、生姜、桂圆、核桃。忌寒凉冰冷。',
      '阴虚': '宜食百合、银耳、枸杞、梨。忌辛辣燥热。',
      '痰湿': '宜食薏米、冬瓜、荷叶、陈皮。忌甜腻厚味。',
      '湿热': '宜食绿豆、苦瓜、薏米、莲子。忌辛辣油腻。',
      '血瘀': '宜食山楂、黑木耳、玫瑰花茶。忌寒凉凝滞。',
      '气郁': '宜食玫瑰花、佛手、萝卜、柑橘。忌收敛酸涩。',
      '特禀': '宜食清淡均衡，多食益气固表食物。忌致敏食物。',
    };

    final exerciseAdvice = {
      '平和': '各类运动皆宜，保持规律锻炼。',
      '气虚': '适宜散步、太极拳、八段锦。避免剧烈运动。',
      '阳虚': '适宜慢跑、日光浴、艾灸后运动。忌冷水运动。',
      '阴虚': '适宜游泳、瑜伽、冥想。避免大汗淋漓。',
      '痰湿': '适宜快走、骑车、跳舞。加强有氧运动。',
      '湿热': '适宜游泳、中长跑、球类运动。',
      '血瘀': '适宜太极、舞蹈、按摩推拿。',
      '气郁': '适宜跑步、登山、团队运动。多参与社交活动。',
      '特禀': '适宜柔和运动，游泳需注意水质。',
    };

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('体质测试结果',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ShunShiColors.primary, Color(0xFF2D5A3D)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                const Icon(Icons.spa, size: 48, color: Colors.white70),
                const SizedBox(height: 12),
                Text('$primary质',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                        color: Colors.white, fontFamily: ShunShiTypography.serifFamily)),
                const SizedBox(height: 8),
                const Text('您的主要体质类型', style: TextStyle(fontSize: 13, color: Colors.white60)),
                if (secondary != null) ...[
                  const SizedBox(height: 16),
                  Text('兼有 $secondary质倾向',
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ]),
            ),
            const SizedBox(height: 24),

            _sectionTitle('体质分布'),
            const SizedBox(height: 12),
            ...sorted.map((e) {
              final ratio = e.value / maxScore;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(width: 50, child: Text('${e.key}质', style: const TextStyle(fontSize: 12,
                      color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily))),
                  const SizedBox(width: 8),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: ShunShiColors.divider,
                      valueColor: AlwaysStoppedAnimation(
                        e.key == primary ? ShunShiColors.primary : ShunShiColors.primaryLight,
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  SizedBox(width: 36, child: Text('${e.value}',
                      style: const TextStyle(fontSize: 11, color: ShunShiColors.textTertiary))),
                ]),
              );
            }),
            const SizedBox(height: 24),

            _sectionTitle('体质特征'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ShunShiColors.borderGhost),
              ),
              child: Text(descriptions[primary] ?? '',
                  style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.7)),
            ),
            const SizedBox(height: 24),

            _sectionTitle('调养建议'),
            const SizedBox(height: 12),
            _adviceCard('饮食调养', dietAdvice[primary] ?? '', Icons.restaurant, ShunShiColors.primary),
            const SizedBox(height: 12),
            _adviceCard('运动调养', exerciseAdvice[primary] ?? '', Icons.self_improvement, ShunShiColors.secondary),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制分享链接'), duration: Duration(seconds: 1))),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('分享结果'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _current = 0;
                  _answers.fillRange(0, 20, -1);
                  _showResult = false;
                  _pageController.jumpToPage(0);
                }),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ShunShiColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('重新测试'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary));

  Widget _adviceCard(String title, String desc, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ShunShiColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ShunShiColors.borderGhost),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
            color: color, fontFamily: ShunShiTypography.serifFamily)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
      ])),
    ]),
  );
}

class _Q {
  final String text;
  final String type;
  final bool reverse;
  const _Q(this.text, this.type, {this.reverse = false});
}
