/// 数据模型 - 订阅
class Subscription {
  final String id;
  final String userId;
  final String planType;
  final String? paymentMethod;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool isActive;

  Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    this.paymentMethod,
    required this.startedAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      planType: json['plan_type'] ?? 'free',
      paymentMethod: json['payment_method'],
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }
}

/// 订阅计划（从前端固定写入，对应后端4个层级）
class SubscriptionPlan {
  final String id;
  final String name;
  final int priceCents;
  final int? priceYearlyCents;
  final String? period;
  final String? periodName;
  final String description;
  final Map<String, bool> features;
  final bool isCurrent;
  final int familySeats;
  final bool isRecommended;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceCents,
    this.priceYearlyCents,
    this.period,
    this.periodName,
    required this.description,
    required this.features,
    this.isCurrent = false,
    this.familySeats = 0,
    this.isRecommended = false,
  });

  String get priceDisplay {
    if (priceCents == 0) return '免费';
    return '¥${(priceCents / 100).toStringAsFixed(0)}';
  }

  String get priceYearlyDisplay {
    if (priceYearlyCents == null) return '';
    return '¥${(priceYearlyCents! / 100).toStringAsFixed(0)}';
  }

  factory SubscriptionPlan.fromJson(
    Map<String, dynamic> json, {
    bool recommended = false,
  }) {
    // Support both price (yuan) and price_cents (fen)
    int priceCents;
    if (json.containsKey('price_cents')) {
      // 0S3 付费档只卖年付：月价为空时用年价，避免把付费档显示成「免费」
      priceCents = json['price_cents'] ?? json['price_yearly_cents'] ?? 0;
    } else if (json['price'] is num) {
      priceCents = ((json['price'] as num) * 100).round();
    } else if (json['price_yearly'] is num) {
      priceCents = ((json['price_yearly'] as num) * 100).round();
    } else {
      priceCents = 0;
    }
    // Map level to description and features
    final level = json['level'] as int? ?? 0;
    final descMap = {
      0: '基础功能',
      1: '年付内容订阅',
      2: '年付会员',
    };
    final featMap = {
      0: {'basic_chat': true},
      1: {'basic_chat': true, 'today_plan': true},
      2: {'basic_chat': true, 'today_plan': true},
    };
    final durationDays = json['duration_days'];
    final yearly = durationDays is num && durationDays >= 365;
    return SubscriptionPlan(
      id: json['id'] ?? json['product_id'] ?? 'free',
      name: json['name'] ?? '',
      priceCents: priceCents,
      priceYearlyCents: json['price_yearly_cents'],
      period: json['period'] ?? (yearly || priceCents > 0 ? 'year' : 'year'),
      periodName: json['period_name'] ?? (yearly || priceCents > 0 ? '年' : '年'),
      description: json['description'] ??
          (priceCents > 0 ? '年付，次数以订单页说明为准' : (descMap[level] ?? '')),
      features: Map<String, bool>.from(
        json['features'] ?? featMap[level] ?? {},
      ),
      isCurrent: json['is_current'] ?? json['is_current_tier'] ?? false,
      familySeats: level == 3 ? 4 : 0,
      isRecommended: recommended || level == 2,
    );
  }
}

/// 订单信息
class SubscriptionOrder {
  final String orderId;
  final String planId;
  final int amountCents;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? paymentUrl;

  SubscriptionOrder({
    required this.orderId,
    required this.planId,
    required this.amountCents,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.paymentUrl,
  });

  factory SubscriptionOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionOrder(
      orderId: json['order_id'] ?? json['id'] ?? '',
      planId: json['plan_id'] ?? '',
      amountCents: json['amount_cents'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      paymentUrl: json['pay_url'] ?? json['payment_url'],
    );
  }
}

/// 用户订阅状态
class UserSubscriptionStatus {
  final String planId;
  final String planName;
  final bool isActive;
  final DateTime? expiresAt;
  final int dayRemaining;
  final Map<String, bool> features;

  UserSubscriptionStatus({
    required this.planId,
    required this.planName,
    required this.isActive,
    this.expiresAt,
    this.dayRemaining = 0,
    required this.features,
  });

  factory UserSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionStatus(
      planId: json['plan_id'] ?? json['plan'] ?? 'free',
      planName: json['plan_name'] ?? '免费版',
      isActive: json['is_active'] ?? false,
      expiresAt: _parseMembershipExpiry(json['expires_at']),
      dayRemaining: json['day_remaining'] ?? 0,
      features: Map<String, bool>.from(json['features'] ?? {}),
    );
  }
}

// The status API uses Unix seconds; older responses used ISO dates.
DateTime? _parseMembershipExpiry(dynamic value) {
  if (value is num && value.isFinite) {
    final milliseconds = value * 1000;
    if (milliseconds.abs() > 8640000000000000) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt(), isUtc: true);
  }
  return value is String ? DateTime.tryParse(value) : null;
}
