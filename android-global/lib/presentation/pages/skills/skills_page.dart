import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_singleton.dart';
import '../../widgets/seasons_visual.dart';

/// Daily practices: short, guided suggestions the backend generates from a curated list.
///
/// `GET /api/v1/skills/practices` answers `{skills: [{id, skill_id, name, description,
/// category, is_premium}]}` in English for this edition; a practice is run with
/// `POST /api/v1/skills/execute` using its `skill_id`, and the reply text is `final_response`.
class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key, this.client});

  /// Test hook; the app uses its configured API client.
  final Dio? client;

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  late final Dio _dio = widget.client ?? apiClient.dio;

  List<Map<String, dynamic>> _skills = [];
  bool _loading = true;
  String? _error;
  String? _runningId;
  Map<String, dynamic>? _active;
  String? _resultText;
  bool _partial = false;

  static const _photos = <String, String>{
    'sleep_optimization': 'assets/images/wellness/sleep_pillow_moon.jpg',
    'focus_improvement': 'assets/images/wellness/emotion_meditation_bowl.jpg',
    'stress_relief': 'assets/images/wellness/exercise_yoga_nature.jpg',
    'nutrition_guidance': 'assets/images/wellness/food_spring_salad.jpg',
    'mental_reset': 'assets/images/wellness/emotion_meditation.jpg',
    'breathing': 'assets/images/wellness/exercise_sleep_relax.jpg',
    'gratitude': 'assets/images/wellness/emotion_journal_writing.jpg',
    'morning_routine': 'assets/images/wellness/exercise_morning_stretch.jpg',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get('/api/v1/skills/practices');
      final body = res.data;
      if (body is! Map || body['skills'] is! List) throw const FormatException('unexpected skills payload');
      final list = (body['skills'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => (m['skill_id'] ?? '').toString().isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() => _skills = list);
    } catch (_) {
      if (mounted) setState(() => _error = "We couldn't load your practices. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Map<String, dynamic> skill) async {
    if (_runningId != null) return;
    final name = (skill['name'] ?? 'this practice').toString();
    setState(() {
      _runningId = skill['id']?.toString();
      _error = null;
    });
    try {
      final res = await _dio.post('/api/v1/skills/execute', data: {
        'message': 'Please give me today\'s guidance for: $name.',
        'skill_ids': [skill['skill_id']],
      });
      final data = res.data;
      final text = data is Map ? (data['final_response'] ?? '').toString().trim() : '';
      if (text.isEmpty) throw const FormatException('empty reply');
      if (!mounted) return;
      setState(() {
        _active = skill;
        _resultText = text;
        _partial = data is Map && data['status'] == 'partial';
      });
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (mounted) {
        setState(() => _error = code == 401
            ? 'Please sign in to use this practice.'
            : code == 403
                ? 'This practice needs an active membership.'
                : "We couldn't create a suggestion right now. Please try again in a moment.");
      }
    } catch (_) {
      if (mounted) setState(() => _error = "We couldn't create a suggestion right now. Please try again in a moment.");
    } finally {
      if (mounted) setState(() => _runningId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1A1A2E);
    final sub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final card = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF9FAFB);
    final line = isDark ? const Color(0xFF2D2D44) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: Text('Daily practices', style: TextStyle(color: text, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: sub),
          onPressed: () {
            if (_active != null) {
              setState(() {
                _active = null;
                _resultText = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF144227)))
          : _active != null
              ? _result(text, sub, card, line)
              : _list(text, sub, card, line),
    );
  }

  Widget _list(Color text, Color sub, Color card, Color line) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        SgHeroBanner(
          asset: 'assets/images/sg_season_${sgSeasonFor(null)}.webp',
          title: 'Small practices, one at a time',
          subtitle: 'Pick one for a short, guided suggestion for today.',
          height: 150,
        ),
        const SizedBox(height: 18),
        if (_error != null) _notice(_error!, card, line, text, retry: _skills.isEmpty),
        if (_skills.isEmpty && _error == null)
          const SgEmptyState(
            asset: 'assets/images/sg_empty.webp',
            title: 'No practices yet',
            message: 'Check back soon. New guided practices will appear here.',
          ),
        ..._skills.map((s) {
          final id = (s['id'] ?? '').toString();
          final busy = _runningId == id;
          final photo = _photos[id] ?? 'assets/images/wellness/wellness_seasonal.jpg';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: card,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: Key('practice_$id'),
                borderRadius: BorderRadius.circular(18),
                onTap: busy ? null : () => _run(s),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
                  child: Row(children: [
                    SgThumb(asset: photo, size: 68),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((s['name'] ?? '').toString(),
                            style: TextStyle(fontWeight: FontWeight.w700, color: text, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text((s['description'] ?? '').toString(),
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 12.5, height: 1.35)),
                        if (s['is_premium'] == true) ...[
                          const SizedBox(height: 6),
                          const SgBadgeLabel('Members'),
                        ],
                      ]),
                    ),
                    const SizedBox(width: 6),
                    busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF144227)))
                        : Icon(Icons.chevron_right, color: sub),
                  ]),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _notice(String message, Color card, Color line, Color text, {bool retry = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
      child: Row(children: [
        Icon(Icons.info_outline, size: 18, color: text),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: text, fontSize: 13, height: 1.4))),
        if (retry) TextButton(onPressed: _load, child: const Text('Try again')),
      ]),
    );
  }

  Widget _result(Color text, Color sub, Color card, Color line) {
    final s = _active!;
    final id = (s['id'] ?? '').toString();
    final photo = _photos[id] ?? 'assets/images/wellness/wellness_seasonal.jpg';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        SgHeroBanner(asset: photo, title: (s['name'] ?? '').toString(), subtitle: (s['description'] ?? '').toString(), height: 190),
        const SizedBox(height: 16),
        const Row(children: [SgBadgeLabel('AI-generated')]),
        const SizedBox(height: 10),
        if (_partial)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text("Some parts couldn't be completed.", style: TextStyle(color: sub, fontSize: 12.5)),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
          child: SelectableText(_resultText ?? '', style: TextStyle(color: text, fontSize: 15, height: 1.6)),
        ),
        const SizedBox(height: 14),
        Text(
          'General wellness information, not medical advice. If you feel unwell, talk to a qualified professional.',
          style: TextStyle(color: sub, fontSize: 11.5, height: 1.4),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _active = null;
            _resultText = null;
          }),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('All practices'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF144227)),
        ),
      ],
    );
  }
}

/// Small pill label.
class SgBadgeLabel extends StatelessWidget {
  const SgBadgeLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFE4C285).withValues(alpha: 0.35), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(color: Color(0xFF144227), fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
