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
      priceCents = json['price_cents'] ?? 0;
    } else if (json.containsKey('price')) {
      priceCents = ((json['price'] as num) * 100).round();
    } else {
      priceCents = 0;
    }
    // Map level to description and features
    final level = json['level'] as int? ?? 0;
    final descMap = {
      0: '基础功能',
      1: '月度会员，畅享全部功能',
      2: '年度会员，超值优惠',
      3: '家庭共享，最多4人使用',
    };
    final featMap = {
      0: {'basic_chat': true},
      1: {'basic_chat': true, 'unlimited_chat': true, 'today_plan': true},
      2: {
        'basic_chat': true,
        'unlimited_chat': true,
        'today_plan': true,
        'deep_suggestions': true,
      },
      3: {
        'basic_chat': true,
        'unlimited_chat': true,
        'today_plan': true,
        'deep_suggestions': true,
        'family': true,
      },
    };
    return SubscriptionPlan(
      id: json['id'] ?? json['product_id'] ?? 'free',
      name: json['name'] ?? '',
      priceCents: priceCents,
      priceYearlyCents: json['price_yearly_cents'],
      period: json['period'] ?? (level == 1 ? 'month' : 'year'),
      periodName: json['period_name'] ?? (level == 1 ? '月' : '年'),
      description: json['description'] ?? descMap[level] ?? '',
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
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      dayRemaining: json['day_remaining'] ?? 0,
      features: Map<String, bool>.from(json['features'] ?? {}),
    );
  }
}
