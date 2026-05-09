import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

/// 订阅服务 - 对接后端 API
class SubscriptionService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'http://116.62.32.43:4000',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 获取订阅计划列表
  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final res = await _dio.get('/api/v1/orders/products');
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
      final res = await _dio.get('/api/v1/orders/user/$userId');
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
        '/api/v1/orders/create',
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
      throw Exception('支付功能即将上线，敬请期待');
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
      final res = await _dio.post('/api/v1/orders/restore', data: {'user_id': userId});
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
