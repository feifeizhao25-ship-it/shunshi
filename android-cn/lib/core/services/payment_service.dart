import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/storage_manager.dart';

/// 支付服务统一接口
///
/// 支持:
/// - 国内版: 支付宝 (alipay)
/// - 国际版: Apple App Store IAP / Google Play Billing / Stripe
///
/// 使用示例:
/// ```dart
/// final result = await paymentService.purchase(
///   productId: 'shunshi_premium_annual',
///   provider: PaymentProvider.iap,
/// );
/// ```
class PaymentService {
  final Dio _dio;

  PaymentService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  /// 获取商品列表
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/subscription/plans');
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> items = data['data'];
        return items.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('[Payment] 获取商品列表失败: $e');
      return [];
    }
  }

  /// 发起购买
  ///
  /// [productId] 商品ID
  /// [provider] 支付渠道
  Future<PurchaseResult> purchase({
    required String productId,
    required PaymentProvider provider,
  }) async {
    try {
      switch (provider) {
        case PaymentProvider.alipay:
          return await _purchaseAlipay(productId);
        case PaymentProvider.iap:
          return await _purchaseIAP(productId);
        case PaymentProvider.stripe:
          return await _purchaseStripe(productId);
      }
    } catch (e) {
      return PurchaseResult.failure(message: '购买失败: $e');
    }
  }

  /// 恢复购买（用于换机或重新安装）
  Future<PurchaseResult> restorePurchases() async {
    try {
      // TODO: 接入真实 IAP SDK
      // await InAppPurchase.instance.restorePurchases();

      // 调用后端验证
      final response = await _dio.post('/subscription/restore', data: {
        'receipt': 'PLACEHOLDER_RECEIPT', // TODO: 替换为真实 receipt
      });

      final data = response.data;
      if (data['success'] == true) {
        // 更新本地订阅状态
        await _updateLocalSubscription(data['data']);
        return PurchaseResult.success(
          transactionId: data['data']['transaction_id'],
          message: '恢复购买成功',
        );
      }
      return PurchaseResult.failure(message: data['error'] ?? '恢复失败');
    } catch (e) {
      return PurchaseResult.failure(message: '恢复购买失败: $e');
    }
  }

  /// 查询当前订阅状态
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    try {
      final response = await _dio.get('/subscription');
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        await _updateLocalSubscription(data['data']);
        return SubscriptionStatus.fromJson(data['data']);
      }
      return SubscriptionStatus.none();
    } catch (e) {
      return SubscriptionStatus.none();
    }
  }

  /// 支付宝购买流程
  Future<PurchaseResult> _purchaseAlipay(String productId) async {
    // 1. 创建订单
    final orderRes = await _dio.post('/subscription/subscribe', data: {
      'product_id': productId,
      'provider': 'alipay',
    });

    if (orderRes.data['success'] != true) {
      return PurchaseResult.failure(message: orderRes.data['error'] ?? '创建订单失败');
    }

    final orderData = orderRes.data['data'];
    final orderId = orderData['order_id'];
    final payUrl = orderData['pay_url']; // 支付宝跳转链接或 SDK 调用参数

    // TODO: 调用支付宝 SDK 发起支付
    // 国内版: 使用 alipay_kit 或 url_launcher 打开 payUrl
    // 模拟成功
    await Future.delayed(const Duration(seconds: 2));

    // 2. 轮询支付结果
    return await _pollPaymentResult(orderId, maxAttempts: 30);
  }

  /// IAP (Apple/Google) 购买流程
  Future<PurchaseResult> _purchaseIAP(String productId) async {
    // TODO: 接入真实 In-App Purchase SDK
    // 1. 查询商品
    // final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({productId});
    // 2. 发起购买
    // final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    // await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    // 3. 监听购买结果
    // 4. 发送 receipt 到后端验证

    await Future.delayed(const Duration(seconds: 2));

    // 模拟 receipt 验证
    final verifyRes = await _dio.post('/subscription/verify', data: {
      'provider': 'apple', // or 'google'
      'product_id': productId,
      'receipt': 'PLACEHOLDER_RECEIPT',
    });

    if (verifyRes.data['success'] == true) {
      await _updateLocalSubscription(verifyRes.data['data']);
      return PurchaseResult.success(
        transactionId: verifyRes.data['data']['transaction_id'],
        message: '购买成功',
      );
    }
    return PurchaseResult.failure(message: verifyRes.data['error'] ?? '验证失败');
  }

  /// Stripe 购买流程
  Future<PurchaseResult> _purchaseStripe(String productId) async {
    // 1. 创建 Stripe Checkout Session
    final sessionRes = await _dio.post('/subscription/subscribe', data: {
      'product_id': productId,
      'provider': 'stripe',
    });

    if (sessionRes.data['success'] != true) {
      return PurchaseResult.failure(message: sessionRes.data['error'] ?? '创建 Session 失败');
    }

    final checkoutUrl = sessionRes.data['data']['checkout_url'];

    // TODO: 打开 WebView 或浏览器完成支付
    // 模拟成功
    await Future.delayed(const Duration(seconds: 2));

    return PurchaseResult.success(
      transactionId: sessionRes.data['data']['session_id'],
      message: '请完成网页支付',
    );
  }

  /// 轮询支付结果
  Future<PurchaseResult> _pollPaymentResult(String orderId, {required int maxAttempts}) async {
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final response = await _dio.get('/subscription/orders/$orderId');
        final status = response.data['data']?['status'];
        if (status == 'completed') {
          await _updateLocalSubscription(response.data['data']);
          return PurchaseResult.success(
            transactionId: orderId,
            message: '支付成功',
          );
        } else if (status == 'failed') {
          return PurchaseResult.failure(message: '支付失败');
        }
      } catch (_) {
        // 继续轮询
      }
    }
    return PurchaseResult.failure(message: '支付超时，请稍后查询订单状态');
  }

  /// 更新本地订阅缓存
  Future<void> _updateLocalSubscription(Map<String, dynamic> data) async {
    await StorageManager.user.setSubscription(data);
  }
}

/// 支付渠道
enum PaymentProvider {
  alipay,   // 支付宝
  iap,      // Apple/Google In-App Purchase
  stripe,   // Stripe
}

/// 商品信息
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String period; // monthly / annual / lifetime

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.period,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    currency: json['currency'] ?? 'CNY',
    period: json['period'] ?? 'monthly',
  );
}

/// 购买结果
class PurchaseResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorCode;

  PurchaseResult._({
    required this.success,
    this.transactionId,
    this.message,
    this.errorCode,
  });

  factory PurchaseResult.success({
    required String transactionId,
    required String message,
  }) => PurchaseResult._(
    success: true,
    transactionId: transactionId,
    message: message,
  );

  factory PurchaseResult.failure({
    required String message,
    String? errorCode,
  }) => PurchaseResult._(
    success: false,
    message: message,
    errorCode: errorCode,
  );
}

/// 订阅状态
class SubscriptionStatus {
  final bool isActive;
  final String? plan;
  final String? tier;
  final DateTime? expiresAt;
  final bool willAutoRenew;

  SubscriptionStatus({
    required this.isActive,
    this.plan,
    this.tier,
    this.expiresAt,
    this.willAutoRenew = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) => SubscriptionStatus(
    isActive: json['is_active'] ?? false,
    plan: json['plan'],
    tier: json['tier'],
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    willAutoRenew: json['will_auto_renew'] ?? false,
  );

  factory SubscriptionStatus.none() => SubscriptionStatus(isActive: false);
}

/// 全局实例
final paymentService = PaymentService();
