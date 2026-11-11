import 'dart:convert';

import '../../core/solar_term/solar_term_table.dart';

/// One snapshot for the name, the membership line, and the season line.
///
/// Settings, the profile name, and the home season capsule all read this.
///
/// Name comes from the signed-in account (`user_info.nickname` or `name`,
/// otherwise the `user_name` saved by profile setup). Logged out is always
/// 「未登录」. The mock 「云水禅心」 and the logged-out default 「朋友」 are not names.
///
/// Membership comes from `GET /api/v1/subscription/status`, which is
/// `membership_status()` on the Entitlement row. The same parser as chat
/// (`parseChatMembership`) turns that into 会员 / 免费版. Unreadable is
/// 「状态待查询」. A local subscription blob or a hard-coded 「年付」 is not used.
///
/// Season comes from the generated solar-term table, the same dates as
/// `backend/app/utils/solar_term_calendar.py`. The line is
/// 「节气 · 孟/仲/季 + 季节 + 之节」. On 2026-11-11 that is 「立冬 · 孟冬之节」.
/// A month bucket (November = 秋季) and the long `/solar-terms/current`
/// description are not this line.
const kMembershipStatusPath = '/api/v1/subscription/status';

const _seasonByTerm = <String, String>{
  '立春': '孟春', '雨水': '孟春',
  '惊蛰': '仲春', '春分': '仲春',
  '清明': '季春', '谷雨': '季春',
  '立夏': '孟夏', '小满': '孟夏',
  '芒种': '仲夏', '夏至': '仲夏',
  '小暑': '季夏', '大暑': '季夏',
  '立秋': '孟秋', '处暑': '孟秋',
  '白露': '仲秋', '秋分': '仲秋',
  '寒露': '季秋', '霜降': '季秋',
  '立冬': '孟冬', '小雪': '孟冬',
  '大雪': '仲冬', '冬至': '仲冬',
  '小寒': '季冬', '大寒': '季冬',
};

class AccountSurface {
  const AccountSurface({required this.name, required this.membership, required this.seasonText});

  final String name;
  final String membership;
  final String seasonText;
}

/// [beijingDay] is a Beijing calendar day. Omit it to use Beijing today.
String solarTermSeasonLine([DateTime? beijingDay]) {
  final day = beijingDay ?? beijingNow();
  final term = solarTermNameOn(DateTime(day.year, day.month, day.day));
  if (term != null) {
    final season = _seasonByTerm[term];
    return season == null ? term : '$term · $season之节';
  }
  return _approxSolarTermLine(day);
}

String accountName({required bool loggedIn, String? nickname}) {
  if (!loggedIn) return '未登录';
  final name = nickname?.trim() ?? '';
  return name.isEmpty ? '顺时用户' : name;
}

String membershipLabel({required bool loggedIn, bool? active}) {
  if (!loggedIn) return '未登录';
  if (active == null) return '状态待查询';
  return active ? '会员' : '免费版';
}

/// Account record first, then the name saved during profile setup.
String? accountNickname({String? userInfoJson, String? userName}) {
  final fromInfo = _nameFromUserInfo(userInfoJson);
  if (fromInfo != null) return fromInfo;
  final pref = userName?.trim() ?? '';
  return pref.isEmpty ? null : pref;
}

AccountSurface accountSurface({
  required bool loggedIn,
  String? nickname,
  bool? membershipActive,
  DateTime? beijingDay,
}) {
  return AccountSurface(
    name: accountName(loggedIn: loggedIn, nickname: nickname),
    membership: membershipLabel(loggedIn: loggedIn, active: membershipActive),
    seasonText: solarTermSeasonLine(beijingDay),
  );
}

String? _nameFromUserInfo(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final value = decoded['nickname'] ?? decoded['name'];
    if (value is! String) return null;
    final name = value.trim();
    return name.isEmpty ? null : name;
  } catch (_) {
    return null;
  }
}

String _approxSolarTermLine(DateTime day) {
  const terms = [
    (1, 6, '小寒', '季冬'), (1, 20, '大寒', '季冬'),
    (2, 4, '立春', '孟春'), (2, 19, '雨水', '孟春'),
    (3, 6, '惊蛰', '仲春'), (3, 21, '春分', '仲春'),
    (4, 5, '清明', '季春'), (4, 20, '谷雨', '季春'),
    (5, 6, '立夏', '孟夏'), (5, 21, '小满', '孟夏'),
    (6, 6, '芒种', '仲夏'), (6, 21, '夏至', '仲夏'),
    (7, 7, '小暑', '季夏'), (7, 23, '大暑', '季夏'),
    (8, 7, '立秋', '孟秋'), (8, 23, '处暑', '孟秋'),
    (9, 8, '白露', '仲秋'), (9, 23, '秋分', '仲秋'),
    (10, 8, '寒露', '季秋'), (10, 23, '霜降', '季秋'),
    (11, 7, '立冬', '孟冬'), (11, 22, '小雪', '孟冬'),
    (12, 7, '大雪', '仲冬'), (12, 22, '冬至', '仲冬'),
  ];
  var termName = '清明';
  var season = '季春';
  for (final t in terms) {
    if (day.month < t.$1 || (day.month == t.$1 && day.day < t.$2)) break;
    termName = t.$3;
    season = t.$4;
  }
  return '$termName · $season之节';
}
