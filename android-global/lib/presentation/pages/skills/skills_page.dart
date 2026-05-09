import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_localizations.dart';

/// Wellness Skills Page — Rule #5: All AI through structured skills.
/// Each skill is deterministic, testable, and returns structured JSON.
class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  final _dio = Dio(BaseOptions(
    baseUrl: 'http://116.62.32.43:4000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 8),
  ));

  List<Map<String, dynamic>> _skills = [];
  bool _loading = true;
  Map<String, dynamic>? _activeResult;
  String? _activeSkill;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final res = await _dio.get('/api/v1/skills');
      if (mounted) {
        setState(() {
        _skills = List<Map<String, dynamic>>.from(res.data['skills'] ?? []);
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _executeSkill(String skillId) async {
    setState(() { _activeSkill = skillId; _activeResult = null; });
    try {
      final res = await _dio.post('/api/v1/skills/execute', data: {
        'message': 'I need help with $skillId',
      });
      if (mounted) {
        setState(() {
        _activeResult = Map<String, dynamic>.from(res.data);
        _activeSkill = null;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _activeSkill = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : Colors.white;
    final text = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1A1A2E);
    final sub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final card = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).t('skills_wellness_skills'), style: TextStyle(color: text, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: sub),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF533AFD)))
        : _activeResult != null
          ? _buildResult(text, sub, card, isDark)
          : _buildSkillList(text, sub, card, isDark),
    );
  }

  Widget _buildSkillList(Color text, Color sub, Color card, bool isDark) {
    final icons = {
      'sleep_optimization': Icons.bedtime_outlined,
      'focus_improvement': Icons.center_focus_strong,
      'stress_relief': Icons.spa_outlined,
      'nutrition_guidance': Icons.restaurant_outlined,
      'mental_reset': Icons.refresh_outlined,
    };
    final colors = {
      'sleep_optimization': const Color(0xFF5C6BC0),
      'focus_improvement': const Color(0xFF7CB342),
      'stress_relief': const Color(0xFFD4613C),
      'nutrition_guidance': const Color(0xFFFFA726),
      'mental_reset': const Color(0xFF533AFD),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a practice',
            style: TextStyle(fontSize: 16, color: sub, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Each skill provides evidence-based, structured guidance.',
            style: TextStyle(fontSize: 13, color: sub.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          ..._skills.map((s) {
            final id = s['id'] ?? '';
            final color = colors[id] ?? const Color(0xFF533AFD);
            final icon = icons[id] ?? Icons.lightbulb_outline;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _executeSkill(id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: text,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s['description'] ?? '',
                                style: TextStyle(color: sub, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: sub, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResult(Color text, Color sub, Color card, bool isDark) {
    final result = _activeResult!;
    final actions = List<Map<String, dynamic>>.from(result['actions'] ?? []);
    final steps = List<Map<String, dynamic>>.from(result['steps'] ?? []);
    final confidence = result['confidence'] ?? 'medium';
    final confColor = confidence == 'high'
      ? const Color(0xFF22C55E)
      : confidence == 'low' ? const Color(0xFF6B7280) : const Color(0xFFF59E0B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => setState(() => _activeResult = null),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(AppLocalizations.of(context).t('skills_back_to_skills')),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF533AFD)),
          ),
          const SizedBox(height: 16),

          // Title + confidence
          Row(
            children: [
              Expanded(
                child: Text(
                  result['title'] ?? '',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: confColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  confidence.toUpperCase(),
                  style: TextStyle(color: confColor, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Insight
          Text(
            result['insight'] ?? '',
            style: TextStyle(fontSize: 15, color: text, height: 1.6),
          ),
          const SizedBox(height: 24),

          // Actions
          if (actions.isNotEmpty) ...[
            Text(AppLocalizations.of(context).t('skills_what_you_could_do'), style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: sub)),
            const SizedBox(height: 10),
            ...actions.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(a['title'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.w600, color: text, fontSize: 14))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C4A7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${a['duration_min'] ?? 3} min',
                          style: const TextStyle(color: Color(0xFF00C4A7), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (a['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(a['description'], style: TextStyle(color: sub, fontSize: 12, height: 1.4)),
                  ],
                  if (a['why'] != null && a['why'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF533AFD).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 12)),
                          Expanded(child: Text(a['why'],
                            style: TextStyle(color: sub, fontSize: 11, fontStyle: FontStyle.italic))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )),
          ],

          // Steps
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).t('skills_how_to_start'), style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: sub)),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF533AFD).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${e.key + 1}',
                      style: const TextStyle(color: Color(0xFF533AFD), fontSize: 10, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value['instruction'] ?? '',
                          style: TextStyle(color: text, fontSize: 13)),
                        if (e.value['detail'] != null && e.value['detail'].toString().isNotEmpty)
                          Text(e.value['detail'],
                            style: TextStyle(color: sub, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Disclaimer
          if (result['disclaimer'] != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['disclaimer'],
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
