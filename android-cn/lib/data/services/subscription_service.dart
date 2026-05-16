import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

enum SubscriptionTier { free, serenity, harmony, family }

// ── Subscription Plan (for UI display) ────────────────

class SubscriptionPlan {
  final String id;
  final String name;
  final String priceDisplay;
  final String period; // "month" or "year"
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceDisplay,
    required this.period,
    required this.features,
  });
}

// ── Subscription Product (full product data) ──────────

class SubscriptionProduct {
  final String id;
  final String name;
  final String description;
  final SubscriptionTier tier;
  final double monthlyPriceUSD;
  final double yearlyPriceUSD;
  final int trialDays;
  final bool hasIntroOffer;
  final double? introOfferPrice;
  final int? introOfferDurationDays;
  final List<String> features;

  const SubscriptionProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.monthlyPriceUSD,
    required this.yearlyPriceUSD,
    this.trialDays = 0,
    this.hasIntroOffer = false,
    this.introOfferPrice,
    this.introOfferDurationDays,
    this.features = const [],
  });
}

// ── All Products ──────────────────────────────────────

class SubscriptionProducts {
  static const free = SubscriptionProduct(
    id: 'free',
    name: 'Free',
    description: 'A gentle beginning',
    tier: SubscriptionTier.free,
    monthlyPriceUSD: 0,
    yearlyPriceUSD: 0,
    features: [
      'Daily insight',
      '3 AI companion conversations per day',
      'Basic reflection tracking',
      'Seasonal content',
    ],
  );

  static const serenity = SubscriptionProduct(
    id: 'serenity',
    name: 'Serenity',
    description: 'For your daily calm practice',
    tier: SubscriptionTier.serenity,
    monthlyPriceUSD: 9.99,
    yearlyPriceUSD: 79.99,
    trialDays: 7,
    features: [
      'Unlimited AI conversations',
      'Full content library',
      'Audio guides & soundscapes',
      'Weekly reflection summaries',
      'Priority support',
    ],
  );

  static const harmony = SubscriptionProduct(
    id: 'harmony',
    name: 'Harmony',
    description: 'For deeper wellness',
    tier: SubscriptionTier.harmony,
    monthlyPriceUSD: 14.99,
    yearlyPriceUSD: 119.99,
    trialDays: 14,
    hasIntroOffer: true,
    introOfferPrice: 0.99,
    introOfferDurationDays: 7,
    features: [
      'Everything in Serenity',
      'Exclusive Harmony content',
      'Advanced weekly summaries',
      'Custom rituals builder',
      'Insights dashboard',
    ],
  );

  static const family = SubscriptionProduct(
    id: 'family',
    name: 'Family',
    description: 'Share calm with your household',
    tier: SubscriptionTier.family,
    monthlyPriceUSD: 19.99,
    yearlyPriceUSD: 159.99,
    trialDays: 14,
    hasIntroOffer: true,
    introOfferPrice: 1.99,
    introOfferDurationDays: 7,
    features: [
      'Everything in Harmony',
      'Up to 4 family members',
      'Shared family dashboard',
      'Individual profiles',
      'Parent controls',
    ],
  );

  static List<SubscriptionProduct> get all => [free, serenity, harmony, family];

  static List<SubscriptionPlan> get plans => [
        SubscriptionPlan(
          id: 'free',
          name: 'Free',
          priceDisplay: 'Free',
          period: 'forever',
          features: free.features,
        ),
        SubscriptionPlan(
          id: 'serenity',
          name: 'Serenity',
          priceDisplay: '\$9.99',
          period: 'month',
          features: serenity.features,
        ),
        SubscriptionPlan(
          id: 'harmony',
          name: 'Harmony',
          priceDisplay: '\$14.99',
          period: 'month',
          features: harmony.features,
        ),
        SubscriptionPlan(
          id: 'family',
          name: 'Family',
          priceDisplay: '\$19.99',
          period: 'month',
          features: family.features,
        ),
      ];

  static SubscriptionProduct? fromId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ── Subscription State ─────────────────────────────────

class SubscriptionState {
  final SubscriptionTier currentTier;
  final List<SubscriptionPlan> plans;
  final bool isLoading;
  final bool isPurchasing;
  final bool isRestoring;
  final String? error;
  final DateTime? expiresAt;

  const SubscriptionState({
    this.currentTier = SubscriptionTier.free,
    this.plans = const [],
    this.isLoading = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.error,
    this.expiresAt,
  });

  bool get isPremium => currentTier != SubscriptionTier.free;
  bool get isFamily => currentTier == SubscriptionTier.family;

  SubscriptionState copyWith({
    SubscriptionTier? currentTier,
    List<SubscriptionPlan>? plans,
    bool? isLoading,
    bool? isPurchasing,
    bool? isRestoring,
    String? error,
    DateTime? expiresAt,
  }) {
    return SubscriptionState(
      currentTier: currentTier ?? this.currentTier,
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      error: error,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

// ── Subscription Service ────────────────────────────────

class SubscriptionService {
  final Dio _dio;
  final String _baseUrl;
  final String _userId;

  SubscriptionService({
    String baseUrl = "http://116.62.32.43",
    required String userId,
  })  : _baseUrl = baseUrl,
        _userId = userId,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
        ));

  /// Fetch subscription state from SEASONS API
  /// GET /api/v1/seasons/subscription/status?user_id=X
  Future<SubscriptionState> fetchState() async {
    try {
      final response = await _dio.get(
        '/api/v1/seasons/subscription/status',
        queryParameters: {'user_id': _userId},
      );
      final data = response.data as Map<String, dynamic>;
      final tierStr = data['tier'] ?? 'free';
      final expiresAtStr = data['expires_at'] as String?;

      SubscriptionTier tier;
      switch (tierStr.toString()) {
        case 'serenity':
          tier = SubscriptionTier.serenity;
          break;
        case 'harmony':
          tier = SubscriptionTier.harmony;
          break;
        case 'family':
          tier = SubscriptionTier.family;
          break;
        default:
          tier = SubscriptionTier.free;
      }

      return SubscriptionState(
        currentTier: tier,
        plans: SubscriptionProducts.plans,
        isLoading: false,
        expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
      );
    } catch (e) {
      return SubscriptionState(
        currentTier: SubscriptionTier.free,
        plans: SubscriptionProducts.plans,
        isLoading: false,
      );
    }
  }

  /// Start a free trial
  /// POST /api/v1/seasons/subscription/trial
  Future<bool> startTrial(SubscriptionTier tier) async {
    final productId = _tierToId(tier);
    if (productId == null) return false;
    try {
      await _dio.post(
        '/api/v1/seasons/subscription/trial',
        data: {'product_id': productId},
        queryParameters: {'user_id': _userId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create checkout session
  /// POST /api/v1/seasons/subscription/checkout
  Future<bool> purchase(SubscriptionTier tier) async {
    final productId = _tierToId(tier);
    if (productId == null) return false;
    try {
      await _dio.post(
        '/api/v1/seasons/subscription/checkout',
        data: {'product_id': productId, 'billing': 'monthly'},
        queryParameters: {'user_id': _userId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore purchases from app store
  /// POST /api/v1/seasons/subscription/restore
  Future<bool> restore() async {
    try {
      await _dio.post(
        '/api/v1/seasons/subscription/restore',
        queryParameters: {'user_id': _userId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  String? _tierToId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.serenity:
        return 'serenity';
      case SubscriptionTier.harmony:
        return 'harmony';
      case SubscriptionTier.family:
        return 'family';
    }
  }
}
