/// ──────────────────────────────────────────────────
/// SubscriptionState — 统一双端订阅状态
/// ──────────────────────────────────────────────────

enum SubscriptionPlatform { ios, android }

enum SubscriptionStatus { none, active, expired, pending, error }

class SubscriptionState {
  final SubscriptionStatus status;
  final SubscriptionPlatform? platform;
  final String? productId;
  final DateTime? expirationDate;
  final DateTime? purchaseDate;
  final bool isTrialPeriod;
  final String? errorMessage;
  final bool needsRevalidation;

  const SubscriptionState({
    this.status = SubscriptionStatus.none,
    this.platform,
    this.productId,
    this.expirationDate,
    this.purchaseDate,
    this.isTrialPeriod = false,
    this.errorMessage,
    this.needsRevalidation = false,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPremium => isActive;

  static const none = SubscriptionState();

  factory SubscriptionState.fromJson(Map<String, dynamic> json) =>
      SubscriptionState(
        status: SubscriptionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SubscriptionStatus.none,
        ),
        productId: json['product_id'] as String?,
        expirationDate: json['expiration_date'] != null
            ? DateTime.tryParse(json['expiration_date'] as String)
            : null,
        purchaseDate: json['purchase_date'] != null
            ? DateTime.tryParse(json['purchase_date'] as String)
            : null,
        isTrialPeriod: json['is_trial_period'] as bool? ?? false,
        needsRevalidation: json['needs_revalidation'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'product_id': productId,
        'expiration_date': expirationDate?.toIso8601String(),
        'purchase_date': purchaseDate?.toIso8601String(),
        'is_trial_period': isTrialPeriod,
        'needs_revalidation': needsRevalidation,
      };

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionPlatform? platform,
    String? productId,
    DateTime? expirationDate,
    DateTime? purchaseDate,
    bool? isTrialPeriod,
    String? errorMessage,
    bool? needsRevalidation,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      platform: platform ?? this.platform,
      productId: productId ?? this.productId,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isTrialPeriod: isTrialPeriod ?? this.isTrialPeriod,
      errorMessage: errorMessage ?? this.errorMessage,
      needsRevalidation: needsRevalidation ?? this.needsRevalidation,
    );
  }
}

/// 订阅商品
class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;

  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currencyCode = 'CNY',
  });
}
