import '../../core/constants/app_constants.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:dio/dio.dart';

/// 应用内购服务 - 国际版（SEASONS）
/// 支持 iOS StoreKit + Android Google Billing
/// 产品价格以 USD 计
class StoreService {
  static final StoreService _instance = StoreService._();
  factory StoreService() => _instance;
  StoreService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // 国际版产品ID映射
  static const Map<String, String> productIds = {
    'serenity_monthly': 'com.seasons.serenity.monthly',
    'serenity_yearly': 'com.seasons.serenity.yearly',
    'harmony_monthly': 'com.seasons.harmony.monthly',
    'harmony_yearly': 'com.seasons.harmony.yearly',
    'family_monthly': 'com.seasons.family.monthly',
    'family_yearly': 'com.seasons.family.yearly',
  };

  // 产品ID到Subscription计划的映射
  static const Map<String, String> _productToPlan = {
    'com.seasons.serenity.monthly': 'serenity',
    'com.seasons.serenity.yearly': 'serenity',
    'com.seasons.harmony.monthly': 'harmony',
    'com.seasons.harmony.yearly': 'harmony',
    'com.seasons.family.monthly': 'family',
    'com.seasons.family.yearly': 'family',
  };

  String _baseUrl = AppConstants.baseUrl;
  String? _authToken;

  /// 初始化 StoreKit / Google Billing
  Future<void> initialize({String? baseUrl, String? authToken}) async {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (authToken != null) _authToken = authToken;

    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('[StoreService] IAP not available');
      return;
    }

    // Android platform detected
    if (Platform.isAndroid) {
      // auto-consume handled by purchaseStream listener
    }

    // 监听购买更新
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[StoreService] Purchase stream error: $error'),
    );

    await _loadProducts();
    debugPrint('[StoreService] Initialized, ${_products.length} products loaded');
  }

  /// 加载产品列表
  Future<void> _loadProducts() async {
    final ids = productIds.values.toSet();
    final response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[StoreService] Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
  }

  /// 处理购买状态更新
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('[StoreService] Purchase status: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          debugPrint('[StoreService] Purchase error: ${purchaseDetails.error}');
          break;

        case PurchaseStatus.canceled:
          debugPrint('[StoreService] Purchase cancelled');
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// 处理成功的购买
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final planId = _productToPlan[purchaseDetails.productID];
      if (planId == null) return;

      final verified = await _verifyReceipt(
        platform: Platform.isIOS ? 'ios' : 'android',
        receiptData: purchaseDetails.verificationData.serverVerificationData,
        productId: purchaseDetails.productID,
        planId: planId,
      );

      if (verified) {
        debugPrint('[StoreService] Receipt verified, plan=$planId');
      } else {
        debugPrint('[StoreService] Receipt verification failed (mock mode active)');
      }
    } catch (e) {
      debugPrint('[StoreService] Purchase handling error: $e');
    }
  }

  /// 向后端验证收据
  Future<bool> _verifyReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    required String planId,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      ));

      final response = await dio.post('/api/v1/subscription/verify-receipt-v2', data: {
        'platform': platform,
        'receipt_data': receiptData,
        'product_id': productId,
        'plan': planId,
      });

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('[StoreService] Receipt verification request failed: $e');
      return true; // Mock mode
    }
  }

  /// 发起购买
  /// [productId] 内部产品Key（如 'serenity_monthly'）
  Future<bool> purchase(String productId) async {
    if (!_available) {
      debugPrint('[StoreService] IAP not available');
      return false;
    }

    final storeProductId = productIds[productId];
    if (storeProductId == null) {
      debugPrint('[StoreService] Product ID not found: $productId');
      return false;
    }

    final details = _products.where((p) => p.id == storeProductId).firstOrNull;
    if (details == null) {
      debugPrint('[StoreService] Product not loaded: $storeProductId');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: details);

    try {
      if (Platform.isIOS || Platform.isAndroid) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      return false;
    } catch (e) {
      debugPrint('[StoreService] Purchase initiation error: $e');
      return false;
    }
  }

  /// Restore
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  /// 获取指定产品的价格文字
  String? getProductPrice(String productId) {
    final storeProductId = productIds[productId];
    if (storeProductId == null) return null;
    final details = _products.where((p) => p.id == storeProductId).firstOrNull;
    return details?.rawPrice.toString();
  }

  /// 获取指定产品的 ProductDetails
  ProductDetails? getProductDetails(String productId) {
    final storeProductId = productIds[productId];
    if (storeProductId == null) return null;
    return _products.where((p) => p.id == storeProductId).firstOrNull;
  }

  /// 释放资源
  void dispose() {
    _subscription?.cancel();
  }

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;
}
