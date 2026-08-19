import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/subscription_state.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final InAppPurchase _iap;
  final SharedPreferences _prefs;

  static const String _entitlementKey = 'subscription_state';
  static const String _monthlyId = 'shunshi_monthly';
  static const String _yearlyId = 'shunshi_yearly';

  final _stateController = StreamController<SubscriptionState>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  SubscriptionRepositoryImpl({
    required InAppPurchase iap,
    required SharedPreferences prefs,
  })  : _iap = iap,
        _prefs = prefs {
    _init();
  }

  void _init() {
    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) {
        _stateController.add(SubscriptionState(
          error: '购买状态获取失败，请稍后重试。',
        ));
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _iap.completePurchase(purchase);
        final newState = SubscriptionState(
          tier: SubscriptionTier.premium,
          isActive: true,
          productId: purchase.productID,
        );
        _saveEntitlement(newState);
        _stateController.add(newState);
      } else if (purchase.status == PurchaseStatus.error) {
        _stateController.add(SubscriptionState(
          error: '购买未完成，如有疑问请联系支持。',
        ));
      }
    }
  }

  void _saveEntitlement(SubscriptionState state) {
    // Save a simple flag (premium = true)
    _prefs.setBool(_entitlementKey, state.isPremium);
  }

  @override
  Future<SubscriptionState> getEntitlement() async {
    try {
      final isAvail = await _iap.isAvailable();
      if (!isAvail) {
        // Fallback to local cache
        final cached = _prefs.getBool(_entitlementKey) ?? false;
        return SubscriptionState(
          tier: cached ? SubscriptionTier.premium : SubscriptionTier.free,
          isActive: cached,
        );
      }
      // In production, verify with server; here we use local cache
      final cached = _prefs.getBool(_entitlementKey) ?? false;
      return SubscriptionState(
        tier: cached ? SubscriptionTier.premium : SubscriptionTier.free,
        isActive: cached,
      );
    } catch (_) {
      return const SubscriptionState();
    }
  }

  @override
  Stream<SubscriptionState> listenEntitlement() => _stateController.stream;

  @override
  Future<SubscriptionState> purchase(String productId) async {
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        return const SubscriptionState(
          error: '暂时无法获取商品信息，请稍后再试。',
        );
      }
      final param = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      await _iap.buyNonConsumable(purchaseParam: param);
      return const SubscriptionState(isLoading: true);
    } catch (e) {
      return const SubscriptionState(
        error: '购买请求发送失败，请检查网络后重试。',
      );
    }
  }

  @override
  Future<SubscriptionState> restore() async {
    try {
      await _iap.restorePurchases();
      return const SubscriptionState(isLoading: true);
    } catch (e) {
      return const SubscriptionState(
        error: '恢复购买失败，请稍后重试。',
      );
    }
  }

  @override
  Future<List<SubscriptionProduct>> getProducts() async {
    try {
      final response = await _iap.queryProductDetails({_monthlyId, _yearlyId});
      return response.productDetails.map((d) {
        return SubscriptionProduct(
          id: d.id,
          title: d.title,
          description: d.description,
          price: d.price,
          currencyCode: d.currencyCode,
          period: d.id == _yearlyId
              ? SubscriptionPeriod.yearly
              : SubscriptionPeriod.monthly,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
    _stateController.close();
  }
}
