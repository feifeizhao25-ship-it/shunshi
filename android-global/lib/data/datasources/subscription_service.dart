import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../../core/config/app_config.dart';
import '../storage/storage_manager.dart';

/// 订阅服务 - 对接后端 API
class SubscriptionService {
  // 订阅/套餐接口都要求登录：此前这个 Dio 没带 Authorization，已登录用户也拿到 401，
  // 页面因此显示“查询失败”（国内）或回退成假的“Free · ACTIVE”（国际）。
  static final Dio _dio = _withAuth(Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  )));

  static Dio _withAuth(Dio dio) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = StorageManager.user.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
    return dio;
  }

  /// 获取订阅计划列表
  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final res = await _dio.get('/api/v1/subscription/status');
      if (res.data?['success'] == true) {
        final List data = res.data['data'];
        // 标记 recommended plan（yiyang 颐养版）
        return data.map((p) {
          return SubscriptionPlan.fromJson(p, recommended: p['id'] == 'yiyang');
        }).toList();
      }
    } catch (e) {
      // fallback to hardcoded plans
    }
    return _fallbackPlans;
  }

  /// 获取用户当前订阅状态
  static Future<UserSubscriptionStatus> getCurrentStatus() async {
    final userId = await _getUserId();
    try {
      final res = await _dio.get('/api/v1/subscription/status');
      if (res.data?['success'] == true) {
        return UserSubscriptionStatus.fromJson(res.data['data']);
      }
    } catch (e) {
      // fallback
    }
    return UserSubscriptionStatus(
      planId: 'free',
      planName: 'Free',
      isActive: true,
      features: {'basic_chat': true, 'solar_terms': true},
    );
  }

  /// 创建订单（获取支付链接）
  static Future<SubscriptionOrder?> createOrder(String planId, {int period = 1}) async {
    final userId = await _getUserId();
    try {
      final res = await _dio.post(
        '/api/v1/subscription/create-order',
        data: {
          'user_id': userId,
          'plan_id': planId,
          'period_count': period,
        },
      );
      if (res.data?['success'] == true) {
        return SubscriptionOrder.fromJson(res.data['data']);
      }
    } catch (e) {
      // fallback: 模拟下单（用于开发/测试）
      throw Exception('Payment coming soon, stay tuned');
    }
    return null;
  }

  /// 轮询订单状态（扫码支付场景）
  static Future<String?> pollOrderStatus(String orderId, {int maxAttempts = 30}) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final res = await _dio.get('/api/v1/orders/$orderId');
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
      final res = await _dio.post('/api/v1/subscription/restore', data: {'user_id': userId});
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

  /// 开发模式模拟订单
  static SubscriptionOrder _mockOrder(String planId) {
    final plan = _fallbackPlans.firstWhere((p) => p.id == planId, orElse: () => _fallbackPlans.first);
    return SubscriptionOrder(
      orderId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      planId: planId,
      amountCents: plan.priceCents,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  /// 后端不可用时的硬编码 plan fallback
  static final List<SubscriptionPlan> _fallbackPlans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      priceCents: 0,
      description: 'Basic features for daily wellness',
      features: {'basic_chat': true, 'solar_terms': true, 'unlimited_chat': false},
      isCurrent: true,
    ),
    SubscriptionPlan(
      id: 'yangxin',
      name: 'Wellness',
      priceCents: 2900,
      priceYearlyCents: 19900,
      period: 'month',
      periodName: 'month',
      description: 'Unlimited chat + daily plans for wellness enthusiasts',
      features: {'basic_chat': true, 'solar_terms': true, 'unlimited_chat': true, 'today_plan': true},
    ),
    SubscriptionPlan(
      id: 'yiyang',
      name: 'Premium',
      priceCents: 5900,
      priceYearlyCents: 39900,
      period: 'month',
      periodName: 'month',
      description: 'Deep suggestions + weekly summary for wellness pros',
      isRecommended: true,
      features: {'basic_chat': true, 'solar_terms': true, 'unlimited_chat': true, 'today_plan': true, 'deep_suggestions': true, 'weekly_summary': true},
    ),
    SubscriptionPlan(
      id: 'jiahe',
      name: 'Family',
      priceCents: 9900,
      priceYearlyCents: 69900,
      period: 'month',
      periodName: 'month',
      description: 'Family sharing (4 seats) for the whole household',
      familySeats: 4,
      features: {'basic_chat': true, 'solar_terms': true, 'unlimited_chat': true, 'today_plan': true, 'deep_suggestions': true, 'weekly_summary': true, 'family': true},
    ),
  ];
}
