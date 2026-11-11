/// Backend route: `GET /api/v1/constitution/questions`
/// (`backend/app/router/constitution.py`, prefix `/api/v1/constitution`).
/// The body is `{success, data: {questions: [...], total}}`, and each option
/// is `{text, value}`, not a bare string.
const kConstitutionQuestionsPath = '/api/v1/constitution/questions';

List<Map<String, dynamic>> parseConstitutionQuestions(dynamic body) {
  final out = <Map<String, dynamic>>[];
  for (final raw in _questionList(body)) {
    if (raw is! Map) continue;
    final text = _questionText(raw);
    if (text.isEmpty) continue;
    final id = raw['id'];
    out.add({
      'id': id is int ? id : int.tryParse('$id') ?? out.length + 1,
      'question': text,
      'options': _optionLabels(raw['options']),
    });
  }
  return out;
}

List<dynamic> _questionList(dynamic body) {
  if (body is List) return body;
  if (body is! Map) return const [];
  final data = body['data'];
  if (data is List) return data;
  if (data is Map && data['questions'] is List) return data['questions'] as List;
  if (body['questions'] is List) return body['questions'] as List;
  return const [];
}

String _questionText(Map raw) {
  for (final key in ['question', 'text', 'content']) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

List<String> _optionLabels(dynamic options) {
  if (options is! List || options.isEmpty) return const ['是', '有时是', '否'];
  final labels = <String>[];
  for (final opt in options) {
    if (opt is String && opt.trim().isNotEmpty) {
      labels.add(opt.trim());
    } else if (opt is Map) {
      final text = opt['text'] ?? opt['label'] ?? opt['value'];
      if (text is String && text.trim().isNotEmpty) labels.add(text.trim());
    }
  }
  return labels.isEmpty ? const ['是', '有时是', '否'] : labels;
}
