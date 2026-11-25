import 'subscription_service.dart';

/// 把 `/api/v1/subscription/status` 读成和国际版界面同一套档位。
///
/// 响应外层的 `tier` 是注册表档（free/plus/pro/family），到期日是秒级整数。
/// 以前按外层不存在的 `serenity` 和字符串到期日来解析，付费用户会落到免费版；
/// 对话页又去读内层没有的 `tier`，`null != 'free'` 让免费用户也显示成付费。
class RightsSnapshot {
  final SubscriptionTier tier;
  final bool paid;
  final int dailyChatLimit;
  final DateTime? expiresAt;

  const RightsSnapshot({
    required this.tier,
    required this.paid,
    required this.dailyChatLimit,
    this.expiresAt,
  });
}

RightsSnapshot rightsFromStatusBody(Map<String, dynamic> body) {
  final nested = body['data'] is Map
      ? Map<String, dynamic>.from(body['data'] as Map)
      : <String, dynamic>{};
  final plan = (nested['plan'] ?? body['plan'] ?? 'free').toString();
  final tierStr = (body['tier'] ?? nested['tier'] ?? 'free').toString();
  final features = nested['features'] is Map ? nested['features'] as Map : const {};
  final rawLimit = features['daily_chat_limit'];
  final limit = rawLimit is num ? rawLimit.toInt() : 20;

  late final SubscriptionTier tier;
  if (plan == 'jiahe' || plan == 'family' || tierStr == 'family') {
    tier = SubscriptionTier.family;
  } else if (plan == 'yangxin' ||
      plan == 'yiyang' ||
      tierStr == 'plus' ||
      tierStr == 'pro' ||
      tierStr == 'premium' ||
      tierStr == 'serenity' ||
      tierStr == 'harmony') {
    tier = SubscriptionTier.serenity;
  } else {
    tier = SubscriptionTier.free;
  }

  return RightsSnapshot(
    tier: tier,
    paid: tier != SubscriptionTier.free,
    dailyChatLimit: limit,
    expiresAt: expiryFromRights(body['expires_at'] ?? nested['expires_at']),
  );
}

DateTime? expiryFromRights(dynamic raw) {
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch((raw * 1000).round(), isUtc: true);
  }
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
