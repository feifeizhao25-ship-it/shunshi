import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../../core/config/app_config.dart';
import '../storage/storage_manager.dart';

/// 订阅服务 - 对接后端 API
class SubscriptionService {
  // 订阅/套餐接口都要求登录：此前这个 Dio 没带 Authorization，已登录用户也拿到 401，
  // 页面因此显示“查询失败”（国内）或回退成假的“Free · ACTIVE”（国际）。
  static final Dio _dio = _withAuth(Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  ));

  static Dio _withAuth(Dio dio) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = StorageManager.user.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token'; // zh-gate:allow HTTP 头
      }
      handler.next(options);
    }));
    return dio;
  }

  /// 获取订阅计划列表
  static Future<List<SubscriptionPlan>> getPlans({
    String platform = 'alipay',
  }) => fetchPlans(_dio, platform: platform);

  static Future<List<SubscriptionPlan>> fetchPlans(
    Dio client, {
    String platform = 'alipay',
  }) async {
    final response = await client.get(
      '/api/v1/subscription/products',
      queryParameters: {'platform': platform},
    );
    final body = response.data;
    if (body is! Map ||
        body['success'] != true ||
        body['data'] is! Map ||
        body['data']['products'] is! List) {
      throw StateError('套餐价格暂时无法查询');
    }
    final plans = <SubscriptionPlan>[];
    final ids = <String>{};
    for (final raw in body['data']['products']) {
      if (raw is! Map) throw StateError('套餐信息无效');
      final item = Map<String, dynamic>.from(raw);
      final id = item['id'] ?? item['product_id'];
      final price = item.containsKey('price_cents')
          ? item['price_cents']
          : item['price'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          item['name'] is! String ||
          price is! num ||
          !price.isFinite ||
          price < 0 ||
          (item.containsKey('price_cents') && price != price.round()) ||
          (id != 'free' && price == 0)) {
        throw StateError('套餐价格信息无效');
      }
      if (item.containsKey('price_cents')) item['price_cents'] = price.toInt();
      plans.add(
        SubscriptionPlan.fromJson(
          item,
          recommended: (item['tier'] ?? id) == 'yiyang',
        ),
      );
    }
    return plans;
  }

  /// 获取用户当前订阅状态
  static Future<UserSubscriptionStatus> getCurrentStatus() =>
      fetchCurrentStatus(_dio, headers: _authHeaders());

  /// Errors must remain distinguishable from a verified free account.
  static Future<UserSubscriptionStatus> fetchCurrentStatus(
    Dio client, {
    required Map<String, String> headers,
  }) async {
    final response = await client.get(
      '/api/v1/subscription/status',
      options: Options(headers: headers),
    );
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw StateError('会员状态响应无效');
    }
    final data = Map<String, dynamic>.from(body['data']);
    if (data['plan'] is! String ||
        data['plan_name'] is! String ||
        data['is_active'] is! bool) {
      throw StateError('会员状态不完整');
    }
    return UserSubscriptionStatus.fromJson(data);
  }

  /// 创建订单（获取支付链接）
  static Future<SubscriptionOrder?> createOrder(
    String planId, {
    int period = 1,
    String platform = 'alipay',
    String paymentScene = 'native',
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/subscription/create-order',
        data: {
          'product_id': planId,
          'platform': platform,
          'payment_scene': paymentScene,
        },
        options: Options(headers: _authHeaders()),
      );
      if (res.data?['success'] == true) {
        return SubscriptionOrder.fromJson(res.data['data']);
      }
    } catch (_) {
      // 调用方展示统一错误，不在生产日志输出可能包含网络细节的异常。
    }
    return null;
  }

  static Map<String, String> _authHeaders() {
    final token = StorageManager.user.getToken();
    return token == null || token.isEmpty
        ? const {}
        : {'Authorization': 'Bearer $token'}; // zh-gate:allow HTTP 头
  }

  /// 轮询订单状态（扫码支付场景）
  static Future<String?> pollOrderStatus(
    String orderId, {
    int maxAttempts = 30,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final res = await _dio.get(
          '/api/v1/subscription/orders/$orderId',
          options: Options(headers: _authHeaders()),
        );
        if (res.data?['success'] == true) {
          final status = res.data['data']['status'];
          if (status == 'paid') return 'paid';
          if (status == 'failed' || status == 'cancelled') return status;
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
    return 'timeout';
  }

  /// 恢复购买（iOS/Google）
  static Future<bool> restorePurchases() async {
    final userId = await _getUserId();
    try {
      final res = await _dio.post(
        '/api/v1/subscription/restore',
        data: {'user_id': userId},
      );
      return res.data?['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 保存 user_id 到本地
  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('user_id');
    if (uid == null || uid.isEmpty) {
      uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', uid);
    }
    return uid;
  }
}
