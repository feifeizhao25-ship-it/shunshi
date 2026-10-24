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
  /// ISO 4217 code from the API (e.g. USD). When the API gives none we show no amount
  /// rather than guess (the shared backend currently returns domestic CNY amounts).
  final String? currency;

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
    this.currency,
  });

  static const pricePending = 'Price shown at checkout';

  static String formatMoney(int cents, String? currency) {
    if (currency == null || currency.isEmpty || currency.toUpperCase() == 'CNY') return pricePending;
    const symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'AUD': 'A\$', 'CAD': 'C\$', 'JPY': '¥'};
    final code = currency.toUpperCase();
    final amount = (cents / 100).toStringAsFixed(code == 'JPY' ? 0 : 2).replaceAll(RegExp(r'\.00$'), '');
    final sym = symbols[code];
    return sym != null ? '$sym$amount' : '$code $amount';
  }

  String get priceDisplay {
    if (priceCents == 0) return 'Free';
    return formatMoney(priceCents, currency);
  }

  String get priceYearlyDisplay {
    if (priceYearlyCents == null) return '';
    return formatMoney(priceYearlyCents!, currency);
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json, {bool recommended = false}) {
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
    final descMap = {0: 'Basic features', 1: 'Monthly membership, enjoy all features', 2: 'Annual membership, best value', 3: 'Family sharing, up to 4 users'};
    final featMap = {
      0: {'basic_chat': true},
      1: {'basic_chat': true, 'unlimited_chat': true, 'today_plan': true},
      2: {'basic_chat': true, 'unlimited_chat': true, 'today_plan': true, 'deep_suggestions': false},
      3: {'basic_chat': true, 'unlimited_chat': true, 'today_plan': true, 'deep_suggestions': false, 'family': true},
    };
    return SubscriptionPlan(
      id: json['id'] ?? 'free',
      name: json['name'] ?? '',
      priceCents: priceCents,
      priceYearlyCents: json['price_yearly_cents'],
      period: json['period'] ?? (level == 1 ? 'month' : 'year'),
      periodName: json['period_name'] ?? (level == 1 ? 'month' : 'year'),
      description: json['description'] ?? descMap[level] ?? '',
      features: Map<String, bool>.from(json['features'] ?? featMap[level] ?? {}),
      isCurrent: json['is_current'] ?? false,
      familySeats: level == 3 ? 4 : 0,
      isRecommended: recommended || level == 2,
      currency: (json['currency'] as String?)?.toUpperCase(),
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
      paymentUrl: json['payment_url'],
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
    // 后端 /api/v1/subscription/status 返回 plan / plan_name（中文）/ expires_at（秒级时间戳）；
    // 原实现只认 plan_id 并对数字 DateTime.parse，一解析就抛异常，付费用户被显示成 Free。
    final id = (json['plan_id'] ?? json['plan'] ?? 'free').toString();
    const enNames = {'free': 'Free', 'yangxin': 'Wellness', 'yiyang': 'Premium', 'jiahe': 'Family'};
    final rawExp = json['expires_at'];
    DateTime? exp;
    if (rawExp is num) {
      exp = DateTime.fromMillisecondsSinceEpoch((rawExp * 1000).round());
    } else if (rawExp is String && rawExp.isNotEmpty) {
      exp = DateTime.tryParse(rawExp);
    }
    final rawFeatures = json['features'];
    return UserSubscriptionStatus(
      planId: id,
      planName: enNames[id] ?? 'Free',
      isActive: json['is_active'] ?? false,
      expiresAt: exp,
      dayRemaining: json['day_remaining'] ?? 0,
      features: rawFeatures is Map
          ? Map<String, bool>.fromEntries(rawFeatures.entries
              .where((e) => e.value is bool)
              .map((e) => MapEntry(e.key.toString(), e.value as bool)))
          : <String, bool>{},
    );
  }
}
