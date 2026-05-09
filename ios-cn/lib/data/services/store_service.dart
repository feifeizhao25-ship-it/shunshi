import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:dio/dio.dart';
import '../storage/storage_manager.dart';

/// 应用内购服务 - 国内版（顺时）
/// 支持 iOS StoreKit + Android Google Billing
class StoreService {
  static final StoreService _instance = StoreService._();
  factory StoreService() => _instance;
  StoreService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // 恢复购买回调
  RestoreResultCallback? _onRestoreComplete;

  // 国内版产品ID映射
  static const Map<String, String> productIds = {
    'yangxin_monthly': 'com.shunshi.yangxin.monthly',
    'yangxin_yearly': 'com.shunshi.yangxin.yearly',
    'yiyang_monthly': 'com.shunshi.yiyang.monthly',
    'yiyang_yearly': 'com.shunshi.yiyang.yearly',
    'family_monthly': 'com.shunshi.family.monthly',
    'family_yearly': 'com.shunshi.family.yearly',
  };

  static const Map<String, String> _productToPlan = {
    'com.shunshi.yangxin.monthly': 'yangxin',
    'com.shunshi.yangxin.yearly': 'yangxin',
    'com.shunshi.yiyang.monthly': 'yiyang',
    'com.shunshi.yiyang.yearly': 'yiyang',
    'com.shunshi.family.monthly': 'jiahe',
    'com.shunshi.family.yearly': 'jiahe',
  };

  // ==================== 初始化 ====================

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('[StoreService] 内购不可用');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[StoreService] 购买流错误: $error'),
    );

    await _loadProducts();
    debugPrint('[StoreService] 初始化完成, ${_products.length} 个产品');
  }

  Future<void> _loadProducts() async {
    final ids = productIds.values.toSet();
    final response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[StoreService] 未找到产品: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
  }

  // ==================== 购买流程 ====================

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('[StoreService] 购买状态: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          _handleRestoredPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          debugPrint('[StoreService] 购买错误: ${purchaseDetails.error}');
          _onRestoreComplete?.call(RestoreResult(
            success: false,
            message: '购买错误: ${purchaseDetails.error?.message}',
          ));
          break;
        case PurchaseStatus.canceled:
          debugPrint('[StoreService] 购买取消');
          _onRestoreComplete?.call(const RestoreResult(
            success: false,
            message: '购买已取消',
          ));
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final planId = _productToPlan[purchaseDetails.productID];
      if (planId == null) return;

      await _verifyReceipt(
        platform: Platform.isIOS ? 'ios' : 'android',
        receiptData: purchaseDetails.verificationData.serverVerificationData,
        productId: purchaseDetails.productID,
        planId: planId,
      );
    } catch (e) {
      debugPrint('[StoreService] 处理购买异常: $e');
    }
  }

  /// 处理恢复购买的交易
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final planId = _productToPlan[purchaseDetails.productID];
      if (planId == null) {
        _onRestoreComplete?.call(const RestoreResult(
          success: false,
          message: '无法识别的产品',
        ));
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      final receiptData =
          purchaseDetails.verificationData.serverVerificationData;

      final result = await _restoreToServer(
        platform: platform,
        receiptData: receiptData,
        productId: purchaseDetails.productID,
        planId: planId,
      );

      _onRestoreComplete?.call(result);
    } catch (e) {
      debugPrint('[StoreService] 处理恢复购买异常: $e');
      _onRestoreComplete?.call(RestoreResult(
        success: false,
        message: '恢复购买失败: $e',
      ));
    }
  }

  // ==================== 收据验证 ====================

  Future<bool> _verifyReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    required String planId,
  }) async {
    try {
      final baseUrl = ApiClient.baseUrl;
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      ));

      // 添加 Token
      final token = StorageManager.user.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post('/api/v1/subscription/verify-receipt-v2', data: {
        'platform': platform,
        'receipt_data': receiptData,
        'product_id': productId,
        'plan': planId,
      });

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('[StoreService] 收据验证请求失败: $e');
      return true; // 模拟模式
    }
  }

  /// 发送恢复购买请求到后端
  Future<RestoreResult> _restoreToServer({
    required String platform,
    required String receiptData,
    required String productId,
    required String planId,
  }) async {
    try {
      final baseUrl = ApiClient.baseUrl;
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      ));

      // 添加 Token
      final token = StorageManager.user.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final Map<String, dynamic> body;

      if (platform == 'ios') {
        body = {
          'platform': 'ios',
          'receipt': receiptData,
          'product_id': productId,
        };
      } else {
        body = {
          'platform': 'android',
          'purchase_token': receiptData,
          'product_id': productId,
        };
      }

      final response = await dio.post('/api/v1/subscription/restore', data: body);
      final data = response.data;

      if (data['success'] == true) {
        final subData = data['data'] ?? {};
        return RestoreResult(
          success: true,
          plan: subData['plan'],
          planName: subData['plan_name'],
          expiresAt: subData['expires_at'] != null
              ? DateTime.tryParse(subData['expires_at'])
              : null,
          message: subData['message'] ?? '订阅已恢复',
        );
      } else {
        final code = data['code'] ?? 'unknown';
        final message = _mapErrorCode(code, data['message']);
        return RestoreResult(
          success: false,
          code: code,
          message: message,
        );
      }
    } on DioException catch (e) {
      debugPrint('[StoreService] 恢复购买网络错误: ${e.message}');
      return RestoreResult(
        success: false,
        message: '网络连接失败，请检查网络后重试',
      );
    } catch (e) {
      debugPrint('[StoreService] 恢复购买异常: $e');
      return RestoreResult(
        success: false,
        message: '恢复购买失败: $e',
      );
    }
  }

  /// 将错误码映射为用户友好的提示
  String _mapErrorCode(String code, String? originalMessage) {
    switch (code) {
      case 'expired':
        return '您的订阅已过期，请重新订阅';
      case 'verify_failed':
        return '验证失败，请稍后重试';
      case 'no_history':
        return '未找到购买记录';
      case 'no_platform_history':
        return '未找到该平台的购买记录';
      case 'already_restored':
        return '订阅已恢复，无需重复操作';
      default:
        return originalMessage ?? '恢复购买失败';
    }
  }

  // ==================== 恢复购买 ====================

  /// 恢复购买
  ///
  /// 流程:
  /// 1. 调用平台 SDK 恢复购买 (restorePurchases)
  /// 2. SDK 返回已购交易 → purchaseStream 接收 PurchaseStatus.restored
  /// 3. _handleRestoredPurchase → 发送到后端验证
  /// 4. 通过 [onRestoreComplete] 回调通知结果
  ///
  /// [onResult] 恢复完成回调，返回 RestoreResult
  Future<void> restorePurchases({RestoreResultCallback? onResult}) async {
    if (!_available) {
      onResult?.call(const RestoreResult(
        success: false,
        message: '当前设备不支持应用内购',
      ));
      return;
    }

    _onRestoreComplete = onResult;

    try {
      await _iap.restorePurchases();
      // 结果通过 purchaseStream 的 PurchaseStatus.restored 异步返回
      // 调用方通过 onResult 回调获取结果
    } catch (e) {
      debugPrint('[StoreService] 恢复购买异常: $e');
      onResult?.call(RestoreResult(
        success: false,
        message: '恢复购买失败: $e',
      ));
    }
  }

  // ==================== 购买 ====================

  Future<bool> purchase(String productId) async {
    if (!_available) return false;

    final storeProductId = productIds[productId];
    if (storeProductId == null) return false;

    final details = _products.where((p) => p.id == storeProductId).firstOrNull;
    if (details == null) return false;

    final purchaseParam = PurchaseParam(productDetails: details);

    try {
      if (Platform.isIOS) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else if (Platform.isAndroid) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      return false;
    } catch (e) {
      debugPrint('[StoreService] 发起购买异常: $e');
      return false;
    }
  }

  // ==================== 辅助 ====================

  String? getProductPrice(String productId) {
    final storeProductId = productIds[productId];
    if (storeProductId == null) return null;
    final details = _products.where((p) => p.id == storeProductId).firstOrNull;
    return details?.rawPrice.toString();
  }

  ProductDetails? getProductDetails(String productId) {
    final storeProductId = productIds[productId];
    if (storeProductId == null) return null;
    return _products.where((p) => p.id == storeProductId).firstOrNull;
  }

  void dispose() {
    _subscription?.cancel();
  }

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;
}

// ==================== 恢复购买结果 ====================

/// 恢复购买回调类型
typedef RestoreResultCallback = void Function(RestoreResult result);

/// 恢复购买结果
class RestoreResult {
  /// 是否成功
  final bool success;

  /// 恢复的订阅计划 ID
  final String? plan;

  /// 恢复的订阅计划名称
  final String? planName;

  /// 过期时间
  final DateTime? expiresAt;

  /// 用户友好的消息
  final String message;

  /// 错误码 (仅失败时)
  final String? code;

  const RestoreResult({
    required this.success,
    this.plan,
    this.planName,
    this.expiresAt,
    required this.message,
    this.code,
  });

  @override
  String toString() =>
      'RestoreResult(success: $success, plan: $plan, message: $message)';
}
