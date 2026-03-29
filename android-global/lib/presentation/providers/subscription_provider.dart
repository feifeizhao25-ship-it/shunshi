import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/subscription_service.dart';

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Dio _dio;
  String _userId = 'seasons-user';

  SubscriptionNotifier()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://localhost:8000',
          connectTimeout: const Duration(seconds: 10),
        )),
        super(SubscriptionState(
          isLoading: true,
          plans: SubscriptionProducts.plans,
        )) {
    _init();
  }

  Future<void> _init() async {
    await _loadUserId();
    final service = SubscriptionService(userId: _userId);
    final fetchedState = await service.fetchState();

    // Try to load from SEASONS API
    try {
      final apiState = await _fetchFromSeasonsApi();
      state = apiState.copyWith(plans: SubscriptionProducts.plans);
    } catch (_) {
      // Fall back to local service
      state = fetchedState.copyWith(plans: SubscriptionProducts.plans);
    }
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ?? 'seasons-user';
    } catch (_) {
      _userId = 'seasons-user';
    }
  }

  /// Fetch subscription status from SEASONS backend
  /// GET /api/v1/seasons/subscription/status?user_id=X
  Future<SubscriptionState> _fetchFromSeasonsApi() async {
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

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _init();
  }

  /// Purchase via SEASONS checkout
  /// POST /api/v1/seasons/subscription/checkout
  Future<void> purchase(SubscriptionTier tier) async {
    state = state.copyWith(isPurchasing: true);
    try {
      final productId = _tierToId(tier);
      await _dio.post(
        '/api/v1/seasons/subscription/checkout',
        data: {'product_id': productId, 'billing': 'monthly'},
        queryParameters: {'user_id': _userId},
      );
      // Note: Actual activation happens via Stripe webhook
      state = state.copyWith(
        currentTier: tier,
        isPurchasing: false,
      );
    } catch (e) {
      state = state.copyWith(isPurchasing: false);
    }
  }

  /// Restore purchases from App Store / Play Store
  /// POST /api/v1/seasons/subscription/restore
  Future<void> restore() async {
    state = state.copyWith(isRestoring: true);
    try {
      await _dio.post(
        '/api/v1/seasons/subscription/restore',
        queryParameters: {'user_id': _userId},
      );
      await refresh();
    } catch (e) {
      state = state.copyWith(isRestoring: false);
    }
  }

  /// Restore with actual store receipt/token
  Future<void> restoreWithReceipt({
    String? receiptData,
    String? purchaseToken,
    String platform = 'android',
  }) async {
    state = state.copyWith(isRestoring: true);
    try {
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
          isRestoring: false,
          expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
        );
      } else {
        state = state.copyWith(isRestoring: false);
      }
    } catch (e) {
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<bool> startTrial(SubscriptionTier tier) async {
    state = state.copyWith(isPurchasing: true);
    final productId = _tierToId(tier);
    if (productId == null) {
      state = state.copyWith(isPurchasing: false);
      return false;
    }
    try {
      await _dio.post(
        '/api/v1/seasons/subscription/trial',
        data: {'product_id': productId},
        queryParameters: {'user_id': _userId},
      );
      state = state.copyWith(isPurchasing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPurchasing: false);
      return false;
    }
  }

  /// Open subscription management page
  /// Navigates to /subscribe where users can view/restore their subscription
  Future<void> manageSubscription() async {
    // The actual navigation is handled in the UI layer via context.push('/subscribe')
    // This method exists to satisfy the ref.read(subscriptionProvider.notifier) call
    // The UI will navigate to /subscribe which shows current tier + restore option
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

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
