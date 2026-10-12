import 'store_connection.dart';
import 'account_bound_purchase.dart';
import 'apple_verification_receipt.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'restore_attempt.dart';
import 'purchase_update_processor.dart';
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
  late final StoreConnection _connection = StoreConnection(
    checkAvailable: _iap.isAvailable,
    purchaseStream: () => _iap.purchaseStream,
    queryProducts: () => _iap.queryProductDetails(productIds.values.toSet()),
    onPurchase: _handlePurchaseUpdate,
    onStreamError: () => debugPrint('[StoreService] 商店事件读取失败'),
  );
  bool get _available => _connection.available;
  List<ProductDetails> get _products => _connection.products;

  final _restoreAttempt = RestoreAttempt<RestoreResult>(
    isSuccess: (result) => result.success,
    pendingResult: const RestoreResult(
      success: false,
      code: 'pending',
      message: '暂未收到可确认的恢复结果，请刷新会员状态或稍后重试',
    ),
    failedResult: const RestoreResult(
      success: false,
      code: 'request_failed',
      message: '恢复购买请求失败，请稍后重试',
    ),
  );

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

  Future<void> initialize() => _connection.refresh();

  Future<void> refreshProducts() => _connection.refresh();

  // ==================== 购买流程 ====================

  late final PurchaseUpdateProcessor _processor = PurchaseUpdateProcessor(
    verifyPurchase: _handleSuccessfulPurchase,
    verifyRestore: _handleRestoredPurchase,
    completePurchase: _iap.completePurchase,
    onTerminal:
        (_) {}, // Purchase cancellation is not proof that restoration failed.
    onError: () => debugPrint('[StoreService] 交易处理未完成，等待后续重试'),
  );

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    // Capture at delivery, before this batch waits behind other transactions.
    final token = StorageManager.user.getToken();
    return _processor.handle(
      purchases,
      canVerify: () => _isCurrentToken(token),
    );
  }

  bool _isCurrentToken(String? token) =>
      token != null &&
      token.trim().isNotEmpty &&
      StorageManager.user.getToken() == token;

  Future<bool> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    final token = StorageManager.user.getToken();
    if (!_isCurrentToken(token)) return false;
    try {
      final planId = _productToPlan[purchaseDetails.productID];
      if (planId == null) return false;

      final receipt = await _receiptFor(purchaseDetails);
      if (!_isCurrentToken(token)) return false;
      return await _verifyReceipt(
        transactionId: purchaseDetails.purchaseID,
        token: token!,
        platform: Platform.isIOS ? 'ios' : 'android',
        receiptData: receipt,
        productId: purchaseDetails.productID,
        planId: planId,
      );
    } catch (e) {
      debugPrint('[StoreService] 处理购买异常: $e');
      return false;
    }
  }

  /// 处理恢复购买的交易
  Future<bool> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    final attemptId = _restoreAttempt.activeId;
    final token = StorageManager.user.getToken();
    if (!_isCurrentToken(token)) return false;
    try {
      final planId = _productToPlan[purchaseDetails.productID];
      if (planId == null) {
        return false;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      final receiptData = await _receiptFor(purchaseDetails);
      if (!_isCurrentToken(token)) return false;

      final result = await _restoreToServer(
        transactionId: purchaseDetails.purchaseID,
        token: token!,
        platform: platform,
        receiptData: receiptData,
        productId: purchaseDetails.productID,
        planId: planId,
      );

      if (!_isCurrentToken(token)) return false;
      _restoreAttempt.report(attemptId, result);
      return result.success;
    } catch (e) {
      debugPrint('[StoreService] 处理恢复购买异常: $e');
      return false;
    }
  }

  Future<String> _receiptFor(PurchaseDetails purchase) =>
      appleVerificationReceipt(
        storeKit2: Platform.isIOS && purchase is SK2PurchaseDetails,
        eventData: purchase.verificationData.serverVerificationData,
        readAppReceipt: SKReceiptManager.retrieveReceiptData,
      );

  // ==================== 收据验证 ====================

  Future<bool> _verifyReceipt({
    required String? transactionId,
    required String token,
    required String platform,
    required String receiptData,
    required String productId,
    required String planId,
  }) async {
    try {
      final baseUrl = ApiClient.baseUrl;
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      // Use the captured credential; never substitute a newly logged-in account.
      if (!_isCurrentToken(token)) throw StateError('Account changed');
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.post(
        '/api/v1/subscription/verify-receipt-v2',
        data: {
          'platform': platform,
          'receipt_data': receiptData,
          'transaction_id': transactionId,
          'product_id': productId,
          'plan': planId,
        },
      );

      return _isCurrentToken(token) && response.data['success'] == true;
    } catch (e) {
      debugPrint('[StoreService] 收据验证请求失败: $e');
      return false;
    }
  }

  /// 发送恢复购买请求到后端
  Future<RestoreResult> _restoreToServer({
    required String? transactionId,
    required String token,
    required String platform,
    required String receiptData,
    required String productId,
    required String planId,
  }) async {
    try {
      final baseUrl = ApiClient.baseUrl;
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      // Use the captured credential; never substitute a newly logged-in account.
      if (!_isCurrentToken(token)) throw StateError('Account changed');
      dio.options.headers['Authorization'] = 'Bearer $token';

      final Map<String, dynamic> body;

      if (platform == 'ios') {
        body = {
          'platform': 'ios',
          'receipt': receiptData,
          'transaction_id': transactionId,
          'product_id': productId,
        };
      } else {
        body = {
          'platform': 'android',
          'purchase_token': receiptData,
          'product_id': productId,
        };
      }

      final response = await dio.post(
        '/api/v1/subscription/restore',
        data: body,
      );
      if (!_isCurrentToken(token)) return _accountChanged;
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
        return RestoreResult(success: false, code: code, message: message);
      }
    } on DioException catch (e) {
      debugPrint('[StoreService] 恢复购买网络错误: ${e.message}');
      return RestoreResult(success: false, message: '网络连接失败，请检查网络后重试');
    } catch (e) {
      debugPrint('[StoreService] 恢复购买异常: $e');
      return const RestoreResult(success: false, message: '恢复购买未完成，请稍后重试');
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

  /// Await verified success or an explicitly uncertain, bounded result.
  Future<RestoreResult> restorePurchases({
    RestoreResultCallback? onResult,
  }) async {
    final token = StorageManager.user.getToken();
    RestoreResult result;
    if (!_isCurrentToken(token)) {
      result = const RestoreResult(
        success: false,
        code: 'login_required',
        message: '请先登录，再恢复购买',
      );
    } else if (!_available) {
      result = const RestoreResult(
        success: false,
        code: 'unavailable',
        message: '当前设备的商店暂不可用，请刷新后重试',
      );
    } else {
      result = await _restoreAttempt.run(_iap.restorePurchases);
    }
    if (token != null && !_isCurrentToken(token)) result = _accountChanged;
    onResult?.call(result);
    return result;
  }

  static const _accountChanged = RestoreResult(
    success: false,
    code: 'account_changed',
    message: '登录状态已变化，请确认当前账号后重新恢复购买',
  );

  // ==================== 购买 ====================

  Future<bool> purchase(String productId) async {
    if (!_available || !_isCurrentToken(StorageManager.user.getToken())) {
      return false;
    }

    final storeProductId = productIds[productId];
    if (storeProductId == null) return false;

    final details = _products.where((p) => p.id == storeProductId).firstOrNull;
    if (details == null) return false;

    if (Platform.isIOS) {
      return launchAccountBoundPurchase(
        readToken: StorageManager.user.getToken,
        loadAccountToken: (token) async {
          final dio = Dio(
            BaseOptions(
              baseUrl: ApiClient.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
          try {
            final response = await dio.get(
              '/api/v1/subscription/store-account',
            );
            final body = response.data;
            if (body is! Map ||
                body['success'] != true ||
                body['data'] is! Map) {
              return null;
            }
            final value = body['data']['app_account_token'];
            return value is String ? value : null;
          } finally {
            dio.close();
          }
        },
        buy: (accountToken) => _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(
            productDetails: details,
            applicationUserName: accountToken,
          ),
        ),
      );
    }
    try {
      if (Platform.isAndroid) {
        return await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: details),
        );
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

  Future<void> dispose() {
    _restoreAttempt.cancel();
    return _connection.dispose();
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
