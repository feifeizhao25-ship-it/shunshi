import 'package:seasons/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Re-export for convenience
export 'package:seasons/domain/entities/user.dart' show SubscriptionTier;

class SubscriptionState {
  final SubscriptionTier currentTier;
  final bool isPurchasing;
  final bool isRestoring;
  final String? error;
  final DateTime? expiresAt;
  final List<SubscriptionPlan> plans;
  final String? stripePublishableKey;

  const SubscriptionState({
    this.currentTier = SubscriptionTier.free,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.error,
    this.expiresAt,
    this.plans = const [],
    this.stripePublishableKey,
  });

  bool get isPremium =>
      currentTier == SubscriptionTier.serenity ||
      currentTier == SubscriptionTier.harmony ||
      currentTier == SubscriptionTier.family;
  bool get isFamily => currentTier == SubscriptionTier.family;

  SubscriptionState copyWith({
    SubscriptionTier? currentTier,
    bool? isPurchasing,
    bool? isRestoring,
    String? error,
    DateTime? expiresAt,
    List<SubscriptionPlan>? plans,
    String? stripePublishableKey,
  }) {
    return SubscriptionState(
      currentTier: currentTier ?? this.currentTier,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      error: error,
      expiresAt: expiresAt ?? this.expiresAt,
      plans: plans ?? this.plans,
      stripePublishableKey: stripePublishableKey ?? this.stripePublishableKey,
    );
  }
}

/// Subscription plan data class
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String? period;
  final List<String> features;
  final String description;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    this.period,
    required this.features,
    required this.description,
  });

  String get priceDisplay => '\$${price.toStringAsFixed(2)}';
  String get periodDisplay => period != null ? '/$period' : '';
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Dio _dio;
  String _userId = 'user-001';

  SubscriptionNotifier({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'http://116.62.32.43',
              connectTimeout: const Duration(seconds: 15),
              headers: {'Content-Type': 'application/json'},
            )),
        super(const SubscriptionState()) {
    _loadUserId();
    _loadPlans();
    _checkSubscription();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ?? 'user-001';
    } catch (_) {
      _userId = 'user-001';
    }
  }

  /// Load subscription plans from SEASONS backend API
  /// GET /api/v1/seasons/subscription/products
  Future<void> _loadPlans() async {
    try {
      final response = await _dio.get('/api/v1/seasons/subscription/products');
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        final plans = data
            .map((e) => SubscriptionPlan(
                  id: e['id'] ?? '',
                  name: e['name'] ?? '',
                  price: (e['monthly_price'] ?? 0).toDouble(),
                  currency: 'usd',
                  period: 'month',
                  features: (e['features'] as List<dynamic>?)?.cast<String>() ?? [],
                  description: '',
                ))
            .toList();
        state = state.copyWith(plans: plans);
      }
    } catch (e) {
      // Fallback to hardcoded plans if backend is unavailable
      state = state.copyWith(plans: _fallbackPlans);
    }
  }

  /// Load Stripe publishable key
  Future<void> _loadStripeConfig() async {
    try {
      final response = await _dio.get('/api/v1/stripe/config');
      final data = response.data;
      if (data['success'] == true) {
        state = state.copyWith(
          stripePublishableKey: data['data']['publishable_key'],
        );
      }
    } catch (_) {
      // Config unavailable, will use mock mode
    }
  }

  /// Check current subscription status from backend
  /// GET /api/v1/seasons/subscription/status?user_id=X
  Future<void> _checkSubscription() async {
    try {
      await _loadUserId();
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
        case 'premium':
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

      state = state.copyWith(
        currentTier: tier,
        expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
      );
    } catch (_) {
      // Silently fail, keep current tier
    }
  }

  /// Purchase via Stripe Checkout
  /// Opens Stripe checkout URL in external browser
  Future<void> purchase(SubscriptionTier tier, {String? userId}) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      await _loadUserId();
      final uid = userId ?? _userId;

      final response = await _dio.post(
        '/api/v1/seasons/subscription/checkout',
        data: {
          'product_id': _tierToPlanId(tier),
          'billing': 'monthly',
        },
        queryParameters: {'user_id': uid},
      );

      final data = response.data;
      final checkoutUrl = data['checkout_url'] as String?;
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      // Note: Actual subscription activation happens via Stripe webhook
      // After successful payment, Stripe calls our webhook which updates the DB
      // The app should poll /api/v1/seasons/subscription/status or check on next launch
      state = state.copyWith(isPurchasing: false);
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Payment initialization failed. Please try again.',
      );
    }
  }

  /// Restore previous purchases from App Store / Play Store
  /// POST /api/v1/seasons/subscription/restore
  ///
  /// On iOS: Use StoreKit to get the transaction receipts, then send to backend
  /// On Android: Use InAppBilling to get purchase tokens, then send to backend
  Future<void> restore() async {
    state = state.copyWith(isRestoring: true, error: null);

    try {
      await _loadUserId();

      // In production, you would:
      // 1. Query the StoreKit for past transactions (iOS)
      // 2. Or query InAppBillingPlugin for past purchases (Android)
      // 3. Send the receipt/token to the backend for verification

      // For now, call the restore endpoint without a receipt
      // (backend will check in-memory history)
      final response = await _dio.post(
        '/api/v1/seasons/subscription/restore',
        queryParameters: {'user_id': _userId},
      );

      final data = response.data as Map<String, dynamic>;
      final restored = data['restored'] == true;

      if (restored) {
        final tierStr = data['tier'] ?? 'free';
        final expiresAtStr = data['expires_at'] as String?;

        SubscriptionTier tier;
        switch (tierStr) {
          case 'serenity':
          case 'premium':
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

        state = state.copyWith(
          currentTier: tier,
          expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
          isRestoring: false,
        );
      } else {
        state = state.copyWith(
          isRestoring: false,
          error: 'No purchases found to restore.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRestoring: false,
        error: 'No purchases found to restore.',
      );
    }
  }

  /// Restore with actual store receipt/token (for iOS StoreKit / Android IAP)
  Future<void> restoreWithReceipt({
    required String receiptData,
    String? purchaseToken,
    String platform = 'ios',
  }) async {
    state = state.copyWith(isRestoring: true, error: null);

    try {
      await _loadUserId();

      final response = await _dio.post(
        '/api/v1/seasons/subscription/restore',
        data: {
          'user_id': _userId,
          'receipt_data': platform == 'ios' ? receiptData : null,
          'purchase_token': platform == 'android' ? purchaseToken : null,
          'platform': platform,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final restored = data['restored'] == true;

      if (restored) {
        final tierStr = data['tier'] ?? 'free';
        final expiresAtStr = data['expires_at'] as String?;

        SubscriptionTier tier;
        switch (tierStr) {
          case 'serenity':
          case 'premium':
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

        state = state.copyWith(
          currentTier: tier,
          expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
          isRestoring: false,
        );
      } else {
        state = state.copyWith(
          isRestoring: false,
          error: data['message'] ?? 'No purchases found to restore.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRestoring: false,
        error: 'No purchases found to restore.',
      );
    }
  }

  /// Refresh subscription status from backend
  Future<void> refreshSubscription() async {
    await _checkSubscription();
  }

  String _tierToPlanId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.premium:
      case SubscriptionTier.serenity:
        return 'serenity';
      case SubscriptionTier.harmony:
        return 'harmony';
      case SubscriptionTier.family:
        return 'family';
    }
  }
}

/// Fallback plans when backend is unreachable
const List<SubscriptionPlan> _fallbackPlans = [
  SubscriptionPlan(
    id: 'free',
    name: 'Free',
    price: 0,
    currency: 'usd',
    features: [
      '5 messages per day',
      'Basic content library',
      'Limited reflections',
      'Daily suggestions',
    ],
    description: 'Start your wellness journey',
  ),
  SubscriptionPlan(
    id: 'serenity',
    name: 'Serenity',
    price: 9.99,
    currency: 'usd',
    period: 'month',
    features: [
      'Unlimited AI companion',
      'All content library',
      'Seasonal insights',
      'Unlimited reflections',
      'Sleep audio & stories',
    ],
    description: 'Perfect for personal wellness',
  ),
  SubscriptionPlan(
    id: 'harmony',
    name: 'Harmony',
    price: 19.99,
    currency: 'usd',
    period: 'month',
    features: [
      'Everything in Serenity',
      'Family features',
      'Priority support',
      'Weekly AI insights',
      'Advanced seasonal programs',
    ],
    description: 'Enhanced wellness with family care',
  ),
  SubscriptionPlan(
    id: 'family',
    name: 'Family',
    price: 29.99,
    currency: 'usd',
    period: 'month',
    features: [
      'Everything in Harmony',
      'Up to 5 family members',
      'Shared family insights',
      'Family wellness plans',
      'Dedicated support',
    ],
    description: 'Wellness for the whole family',
  ),
];

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
