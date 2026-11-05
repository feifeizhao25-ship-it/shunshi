/// Parsing + filtering helpers for the wellness library page.
///
/// GET /api/v1/contents/recommend answers
/// `{"success":true,"data":{"items":[...],"total":N,"season":"..."}}`.
/// The page used to require `data` to be a bare list, so the library always
/// rendered its empty state even though the API returned 20 entries.
List<Map<String, dynamic>> parseRecommendItems(dynamic body) {
  dynamic data = body is Map ? body['data'] : null;
  if (data is Map) data = data['items'];
  if (data is! List) return <Map<String, dynamic>>[];
  return data
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

const _typesByFilter = <String, Set<String>>{
  'nutrition': {'food_therapy', 'tea', 'recipe', 'diet'},
  'movement': {'exercise'},
  'mindfulness': {'meditation', 'mindfulness'},
  'sleep': {'sleep'},
};

const _cnFilterKey = <String, String>{
  '睡眠': 'sleep',
  '饮食': 'nutrition',
  '运动': 'movement',
  '冥想': 'mindfulness',
  '节气养生': 'seasonal',
};

/// [filter] is the chip label (Chinese or English). `All`/`全部` is handled by
/// the caller.
bool matchesWellnessFilter(Map<String, dynamic> c, String filter) {
  final lower = filter.toLowerCase();
  final key = _cnFilterKey[filter] ?? lower;
  final cat = (c['category'] ?? '').toString().toLowerCase();
  final type = (c['type'] ?? '').toString().toLowerCase();
  final tags = (c['tags'] as List?)?.map((t) => t.toString().toLowerCase()) ??
      <String>[];
  if (cat == lower || tags.contains(lower)) return true;
  if (key == 'seasonal') {
    final s = (c['season_tag'] ?? '').toString();
    return s.isNotEmpty;
  }
  if (_typesByFilter[key]?.contains(type) ?? false) return true;
  if (key == 'sleep') {
    final text = '$cat ${tags.join(' ')} ${(c['title'] ?? '')}'.toLowerCase();
    return text.contains('睡眠') || text.contains('安神') || text.contains('失眠') || text.contains('sleep');
  }
  return false;
}
