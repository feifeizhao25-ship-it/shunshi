/// 把后端内容里的英文枚举值统一显示为中文，避免界面出现英文原值。
/// 已经是中文的值原样返回；识别不了的英文值显示为空串，宁可不显示也不露出英文。
class ZhLabels {
  ZhLabels._();

  static final RegExp _latin = RegExp(r'[A-Za-z]{2,}');

  static const Map<String, String> _bestTime = {
    'any': '全天', 'all': '全天', 'anytime': '全天',
    'morning': '清晨', 'noon': '中午', 'afternoon': '下午',
    'evening': '晚上', 'night': '夜间', 'bedtime': '睡前',
  };
  static const Map<String, String> _season = {
    'spring': '春季', 'summer': '夏季', 'autumn': '秋季', 'fall': '秋季',
    'winter': '冬季', 'late_summer': '长夏', 'all': '四季皆宜',
  };
  static const Map<String, String> _difficulty = {
    'easy': '简单', 'medium': '中等', 'hard': '较难',
  };
  static const Map<String, String> _type = {
    'recipe': '食谱', 'food_therapy': '食疗', 'tea': '茶饮', 'acupoint': '穴位',
    'acupressure': '穴位按摩', 'exercise': '运动', 'tips': '养生小贴士',
    'sleep_tip': '睡眠', 'emotion': '情志', 'solar_term': '节气', 'meditation': '冥想',
    'diet': '饮食', 'herb': '药膳',
  };

  static String _lookup(Map<String, String> m, Object? v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return '';
    final hit = m[s.toLowerCase()];
    if (hit != null) return hit;
    return _latin.hasMatch(s) ? '' : s;
  }

  static String bestTime(Object? v) => _lookup(_bestTime, v);
  static String season(Object? v) => _lookup(_season, v);
  static String difficulty(Object? v) => _lookup(_difficulty, v);
  static String contentType(Object? v) => _lookup(_type, v);
}
