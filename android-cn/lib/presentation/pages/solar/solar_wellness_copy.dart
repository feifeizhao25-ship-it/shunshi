import '../home/home_recommend.dart';
import '../home/ultimate_home_page.dart';

/// 「查看完整时辰养生表」这一页上写死的字，加上十二时辰卡片本身。
/// 整页文案守卫用它确认没有药效、茶饮、剂量、经络和孕期哺乳期禁忌食材。

const kSolarWellnessTitle = '时辰养生表';
const kSolarWellnessIntro = '一天十二个时辰，按这个吃饭、休息就好。';
const kSolarWellnessEmptyTitle = '时辰表还是空的';
const kSolarWellnessEmptyBody = '这一天的安排还没有准备好。过一会儿再打开看看。';
const kSolarWellnessErrorTitle = '时辰表没有打开';
const kSolarWellnessErrorBody = '时辰表没有加载出来。检查网络后再试一次。';
const kSolarWellnessLoginTitle = '请先登录';
const kSolarWellnessLoginBody = '登录后才能看这一天的时辰表。';
const kSolarWellnessRetry = '再试一次';
const kSolarWellnessNow = '现在';
const kSolarWellnessLoading = '正在准备时辰表。如果一直停在这里，返回后再打开一次。';

const solarWellnessMeridianTerms = <String>[
  '经络',
  '经活跃',
  '当令',
  '胆经',
  '肝经',
  '肺经',
  '大肠经',
  '胃经',
  '脾经',
  '心经',
  '小肠经',
  '膀胱经',
  '肾经',
  '心包经',
  '三焦经',
  '养百脉',
];

bool solarWellnessTextBlocked(String text, {String? lifeStage}) {
  if (text.isEmpty) return false;
  if (homeVisibleTextHasEfficacy(text) || homeDosagePattern.hasMatch(text))
    return true;
  if (text.contains('茶')) return true;
  if (solarWellnessMeridianTerms.any(text.contains)) return true;
  return homeTextBlockedForStage(text, lifeStage);
}

String shichenEntryBlob(ShiChenData sc) {
  return [
    sc.name,
    sc.meridian,
    shiChenHeadline(sc),
    shiChenTimeDisplay(sc),
    sc.principle,
    sc.principleShort,
    sc.wellnessPrinciple,
    sc.aiQuote,
    for (final action in sc.actions) ...[action.title, action.description],
  ].join('\n');
}

List<String> visibleSolarWellnessCopy() {
  return [
    kSolarWellnessTitle,
    kSolarWellnessIntro,
    kSolarWellnessEmptyTitle,
    kSolarWellnessEmptyBody,
    kSolarWellnessErrorTitle,
    kSolarWellnessErrorBody,
    kSolarWellnessLoginTitle,
    kSolarWellnessLoginBody,
    kSolarWellnessRetry,
    kSolarWellnessNow,
    kSolarWellnessLoading,
    ...visibleHomeTimeOfDayCopy(),
  ];
}

class SolarWellnessLoad {
  const SolarWellnessLoad({
    required this.entries,
    this.error,
    this.needsLogin = false,
  });

  final List<ShiChenData> entries;
  final String? error;
  final bool needsLogin;

  bool get failed => error != null;
}

/// 接口返回的条目必须和首页十二时辰逐字相同。对不上、或这一阶段不能吃的，整段丢掉。
List<ShiChenData> solarWellnessEntriesFromBody(dynamic body) {
  final data = body is Map && body['data'] is Map ? body['data'] as Map : body;
  if (data is! Map) return const [];
  final stage = data['life_stage']?.toString();
  final raw = data['entries'];
  if (raw is! List) return const [];
  final allow = {for (final sc in homeShiChenTable()) sc.name: sc};
  final kept = <String>{};
  for (final item in raw) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}'.trim();
    final local = allow[name];
    if (local == null || kept.contains(name)) continue;
    final apiBlob = _apiBlob(item);
    if (solarWellnessTextBlocked(apiBlob, lifeStage: stage)) continue;
    if (solarWellnessTextBlocked(shichenEntryBlob(local), lifeStage: stage))
      continue;
    if (!_matchesAllowlist(item, local)) continue;
    kept.add(name);
  }
  return [
    for (final sc in homeShiChenTable())
      if (kept.contains(sc.name)) sc,
  ];
}

SolarWellnessLoad solarWellnessLoadFromResponse(
  int? status,
  dynamic body, {
  bool failed = false,
}) {
  if (status == 401) {
    return const SolarWellnessLoad(
      entries: [],
      needsLogin: true,
      error: kSolarWellnessLoginBody,
    );
  }
  if (failed || status == null || status >= 400 || body is! Map) {
    return const SolarWellnessLoad(entries: [], error: kSolarWellnessErrorBody);
  }
  if (body['success'] != true) {
    return const SolarWellnessLoad(entries: [], error: kSolarWellnessErrorBody);
  }
  return SolarWellnessLoad(entries: solarWellnessEntriesFromBody(body));
}

Map<String, dynamic> solarWellnessApiBodyFor(
  List<ShiChenData> entries, {
  String? lifeStage,
}) {
  return {
    'success': true,
    'data': {
      'life_stage': lifeStage,
      'entries': [
        for (final sc in entries)
          {
            'name': sc.name,
            'time_range': shiChenTimeDisplay(sc),
            'period': sc.meridian,
            'headline': shiChenHeadline(sc),
            'principle': sc.principle,
            'principle_short': sc.principleShort,
            'advice': sc.wellnessPrinciple,
            'quote': sc.aiQuote,
            'actions': [
              for (final action in sc.actions)
                {'title': action.title, 'description': action.description},
            ],
          },
      ],
    },
  };
}

String _apiBlob(Map item) {
  final bits = <String>[];
  void add(dynamic value) {
    if (value is String && value.trim().isNotEmpty) bits.add(value.trim());
    if (value is Map) {
      for (final part in value.values) {
        add(part);
      }
    }
    if (value is List) {
      for (final part in value) {
        add(part);
      }
    }
  }

  for (final key in [
    'name',
    'time_range',
    'period',
    'headline',
    'principle',
    'principle_short',
    'advice',
    'quote',
    'organ',
    'meridian',
    'element',
    'effect',
    'actions',
  ]) {
    if (item.containsKey(key)) add(item[key]);
  }
  return bits.join('\n');
}

bool _fieldOk(dynamic value, String expected) {
  if (value == null) return true;
  if (value is! String) return false;
  final text = value.trim();
  if (text.isEmpty) return true;
  return text == expected;
}

bool _matchesAllowlist(Map item, ShiChenData local) {
  if (!_fieldOk(item['time_range'], shiChenTimeDisplay(local))) return false;
  if (!_fieldOk(item['period'], local.meridian)) return false;
  if (!_fieldOk(item['headline'], shiChenHeadline(local))) return false;
  if (!_fieldOk(item['principle'], local.principle)) return false;
  if (!_fieldOk(item['principle_short'], local.principleShort)) return false;
  if (!_fieldOk(item['advice'], local.wellnessPrinciple)) return false;
  if (!_fieldOk(item['quote'], local.aiQuote)) return false;
  final actions = item['actions'];
  if (actions == null) return true;
  if (actions is! List || actions.length != local.actions.length) return false;
  for (var i = 0; i < actions.length; i++) {
    final action = actions[i];
    if (action is! Map) return false;
    if (!_fieldOk(action['title'], local.actions[i].title)) return false;
    if (!_fieldOk(action['description'], local.actions[i].description))
      return false;
  }
  return true;
}
