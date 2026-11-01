/// 个人进度（积分 / 等级 / 打卡天数 / 徽章）—— 对应后端 `GET /api/v1/gamification/me`。
///
/// 「记录」「成就」「我的」页以前各读各的：成就页读本地 SharedPreferences 里从来没人写过的计数，
/// 记录页读后端根本不返回的字段，「我的」页写死了数字——用户打卡 / 写日记后，这些页面永远显示 0（复测 B03）。
/// 现在三处都读服务端这一份：数字就是打卡、日记、收藏等写入接口留下的记录。
library;

import 'package:dio/dio.dart';

class ProgressBadge {
  final String id;
  final String name;
  final String description;
  final bool unlocked;
  final int? progress;
  final int? target;
  const ProgressBadge({required this.id, required this.name, required this.description, required this.unlocked, this.progress, this.target});

  factory ProgressBadge.fromJson(Map j) => ProgressBadge(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        description: '${j['description'] ?? ''}',
        unlocked: j['unlocked'] == true,
        progress: (j['progress'] as num?)?.toInt(),
        target: (j['target'] as num?)?.toInt(),
      );
}

class UserProgress {
  final int points;
  final int level;
  final String levelName;
  final String? nextLevelName;
  final int? nextLevelPoints;
  final int streakDays;
  final int totalCheckinDays;
  final int weekCheckinDays;
  final int todayCompleted;
  final int todayTotal;
  final int journalCount;
  final int favoriteCount;
  final int chatCount;
  final int exerciseCount;
  final int badgeCount;
  final int badgeTotal;
  final List<ProgressBadge> badges;

  const UserProgress({
    this.points = 0,
    this.level = 1,
    this.levelName = '',
    this.nextLevelName,
    this.nextLevelPoints,
    this.streakDays = 0,
    this.totalCheckinDays = 0,
    this.weekCheckinDays = 0,
    this.todayCompleted = 0,
    this.todayTotal = 0,
    this.journalCount = 0,
    this.favoriteCount = 0,
    this.chatCount = 0,
    this.exerciseCount = 0,
    this.badgeCount = 0,
    this.badgeTotal = 0,
    this.badges = const [],
  });

  /// 到下一级的进度 0–1；已满级返回 1。
  double get levelProgress {
    final next = nextLevelPoints;
    if (next == null || next <= 0) return 1.0;
    return (points / next).clamp(0.0, 1.0);
  }

  int get pointsToNextLevel {
    final next = nextLevelPoints;
    return next == null ? 0 : (next - points).clamp(0, 1 << 30);
  }

  bool get isEmpty => points == 0 && totalCheckinDays == 0 && journalCount == 0 && chatCount == 0 && favoriteCount == 0;

  static int _i(dynamic v) => v is num ? v.toInt() : 0;

  /// 接受 `{success, data: {...}}` 或直接 `{...}`；形状不对返回 null（页面按「读取失败」处理，不显示假数字）。
  static UserProgress? fromBody(dynamic body) {
    final inner = body is Map && body['data'] is Map ? body['data'] as Map : body;
    if (inner is! Map || inner['points'] is! num) return null;
    final today = inner['today'] is Map ? inner['today'] as Map : const {};
    return UserProgress(
      points: _i(inner['points']),
      level: _i(inner['level']),
      levelName: '${inner['level_name'] ?? ''}',
      nextLevelName: inner['next_level_name'] as String?,
      nextLevelPoints: (inner['next_level_points'] as num?)?.toInt(),
      streakDays: _i(inner['streak_days']),
      totalCheckinDays: _i(inner['total_checkin_days']),
      weekCheckinDays: _i(inner['week_checkin_days']),
      todayCompleted: _i(today['completed']),
      todayTotal: _i(today['total']),
      journalCount: _i(inner['journal_count']),
      favoriteCount: _i(inner['favorite_count']),
      chatCount: _i(inner['chat_count']),
      exerciseCount: _i(inner['exercise_count']),
      badgeCount: _i(inner['badge_count']),
      badgeTotal: _i(inner['badge_total']),
      badges: [
        if (inner['badges'] is List)
          for (final b in inner['badges'] as List)
            if (b is Map) ProgressBadge.fromJson(b),
      ],
    );
  }
}

/// 读取当前登录账号的进度。失败（没登录、网络、服务端出错）返回 null。
/// [headers] 国际版传 `LocaleHeaders.values`，服务端才会用英文回答。
Future<UserProgress?> fetchUserProgress(Dio dio, {required String token, Map<String, String> headers = const {}}) async {
  try {
    final res = await dio.get(
      '/api/v1/gamification/me',
      options: Options(headers: {...headers, 'Authorization': 'Bearer $token'}),
    );
    return UserProgress.fromBody(res.data);
  } catch (_) {
    return null;
  }
}
