import '../../account/account_surface.dart';

/// 首页「今日推荐」：只留当前节气的白话饮食和作息。
///
/// 药效、主治、毒性、穴位适应症不展示。没有安全白话就丢掉。
/// 孕期 / 哺乳期名字与 backend `contraindications.py` 读到的现有名单一致，这里不改那些表。

const homeEfficacyTerms = <String>[
  '补血',
  '活血',
  '调经',
  '止痛',
  '通乳',
  '乳汁',
  '有毒',
  '炮制',
  '功效',
  '疗效',
  '主治',
  '禁用',
  '慎用',
  '本草',
  '穴位',
  '温补肾阳',
];

const _pregnancyNames = <String>[
  '藏红花',
  '薏苡仁',
  '益母草',
  '山楂',
  '薏米',
  '螃蟹',
  '甲鱼',
  '芦荟',
  '红花',
  '桃仁',
  '三棱',
  '莪术',
  '丹参',
  '赤芍',
  '黄芪',
  '当归',
  '肉桂',
  '干姜',
  '附子',
  '麝香',
  '冰片',
  '薄荷',
];

const _breastfeedingNames = <String>[
  '螃蟹',
  '薏米',
  '山楂',
  '柚子',
  '鸭肉',
  '薄荷',
  '人参',
];

const _pregnancyMarkers = ['怀孕', '孕妇', '孕期', '孕早', '孕中', '孕晚', 'pregnant', 'pregnancy'];
const _breastfeedingMarkers = ['哺乳', '母乳', 'breastfeed', 'breastfeeding', 'lactation'];

class HomeSuggest {
  const HomeSuggest({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.season,
  });

  final String id;
  final String title;
  final String subtitle;
  final String tag;
  final String season;

  String get blob => '$title$subtitle';
}

const plainHomeSuggestions = <HomeSuggest>[
  HomeSuggest(id: 'home-spring-greens', title: '午饭加一盘青菜', subtitle: '午饭加一盘应季绿叶菜，少放油和盐。', tag: '饮食', season: 'spring'),
  HomeSuggest(id: 'home-spring-walk', title: '午后走一走', subtitle: '午后出去走十分钟，回来喝杯温水。', tag: '作息', season: 'spring'),
  HomeSuggest(id: 'home-spring-sleep', title: '今晚早一点睡', subtitle: '今晚把灯调暗，比平时早一点上床。', tag: '作息', season: 'spring'),
  HomeSuggest(id: 'home-summer-water', title: '多喝白水', subtitle: '天热时多喝白水，少喝冰的。', tag: '饮食', season: 'summer'),
  HomeSuggest(id: 'home-summer-rest', title: '午饭后歇一会儿', subtitle: '午饭后闭眼歇二十分钟。', tag: '作息', season: 'summer'),
  HomeSuggest(id: 'home-summer-shade', title: '避开正午晒', subtitle: '外出带水，把走动放在早上或傍晚。', tag: '作息', season: 'summer'),
  HomeSuggest(id: 'home-autumn-water', title: '白天喝温水', subtitle: '空气干，白天多喝几口温水。', tag: '饮食', season: 'autumn'),
  HomeSuggest(id: 'home-autumn-layer', title: '早晚加一件衣服', subtitle: '早晚凉，出门加一件外套。', tag: '作息', season: 'autumn'),
  HomeSuggest(id: 'home-autumn-pear', title: '晚饭后可以吃一点梨', subtitle: '晚饭后可以吃一点梨，或者喝温水。', tag: '饮食', season: 'autumn'),
  HomeSuggest(id: 'home-winter-porridge', title: '晚饭喝一碗热粥', subtitle: '晚饭喝一碗热粥或热面条，别吃得太晚。', tag: '饮食', season: 'winter'),
  HomeSuggest(id: 'home-winter-sleep', title: '今晚早点休息', subtitle: '天黑得早，今晚早点放下手机休息。', tag: '作息', season: 'winter'),
  HomeSuggest(id: 'home-winter-warm', title: '出门把脖子和脚盖暖', subtitle: '出门把脖子和脚盖暖，路上走慢一点。', tag: '作息', season: 'winter'),
];

String seasonKeyOn(DateTime day) {
  final line = solarTermSeasonLine(DateTime(day.year, day.month, day.day));
  if (line.contains('春')) return 'spring';
  if (line.contains('夏')) return 'summer';
  if (line.contains('秋')) return 'autumn';
  return 'winter';
}

bool homeTextHasEfficacy(String text) => homeEfficacyTerms.any(text.contains);

Set<String> homeExclusionNames(String? lifeStage) {
  final blob = (lifeStage ?? '').toLowerCase();
  final names = <String>{};
  if (_pregnancyMarkers.any(blob.contains)) names.addAll(_pregnancyNames);
  if (_breastfeedingMarkers.any(blob.contains)) names.addAll(_breastfeedingNames);
  return names;
}

bool homeTextBlockedForStage(String text, String? lifeStage) {
  final names = homeExclusionNames(lifeStage);
  if (names.isEmpty || text.isEmpty) return false;
  return names.any(text.contains);
}

bool _isAcupoint(Map<String, dynamic> item) {
  final kind = '${item['type'] ?? ''}${item['category'] ?? ''}';
  final title = '${item['title'] ?? item['name'] ?? ''}';
  return kind.contains('acupoint') || kind.contains('acupressure') || kind.contains('穴位') || title.endsWith('穴');
}

/// 接口条目能不能出现在首页。季节不对、有药效、是穴位，或点到禁忌名，都不要。
bool keepHomePayload(Map<String, dynamic> item, {required String season, String? lifeStage}) {
  if (_isAcupoint(item)) return false;
  final title = '${item['title'] ?? item['name'] ?? ''}'.trim();
  final subtitle = '${item['description'] ?? item['subtitle'] ?? ''}'.trim();
  if (title.isEmpty || subtitle.isEmpty) return false;
  final itemSeason = item['season'] ?? item['season_tag'];
  if (itemSeason is String && itemSeason.isNotEmpty && itemSeason != season) return false;
  final blob = '$title$subtitle${item['effect'] ?? ''}';
  if (homeTextHasEfficacy(blob)) return false;
  if (homeTextBlockedForStage(blob, lifeStage)) return false;
  return true;
}

List<HomeSuggest> homeSuggestionsFor({
  required String season,
  String? lifeStage,
  List<HomeSuggest> extra = const [],
}) {
  bool ok(HomeSuggest item) {
    if (item.season != season) return false;
    if (homeTextHasEfficacy(item.blob)) return false;
    if (homeTextBlockedForStage(item.blob, lifeStage)) return false;
    if (item.subtitle.trim().isEmpty) return false;
    return true;
  }

  final out = <HomeSuggest>[];
  final seen = <String>{};
  for (final item in [...plainHomeSuggestions, ...extra]) {
    if (!ok(item) || seen.contains(item.id)) continue;
    seen.add(item.id);
    out.add(item);
  }
  return out;
}
