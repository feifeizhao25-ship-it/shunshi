import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../../core/config/app_config.dart';
import '../storage/storage_manager.dart';

/// 订阅服务 - 对接后端 API
class SubscriptionService {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// 获取订阅计划列表
  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final userId = await _getUserId();
      final res = await _dio.get(
        '/api/v1/subscription/products',
        queryParameters: {'platform': 'alipay', 'user_id': userId},
      );
      if (res.data?['success'] == true) {
        final List data = res.data['data']['products'];
        // 标记 recommended plan（yiyang 颐养版）
        return data.map((p) {
          return SubscriptionPlan.fromJson(p, recommended: p['id'] == 'yiyang');
        }).toList();
      }
    } catch (_) {
      // fallback to hardcoded plans
    }
    return _fallbackPlans;
  }

  /// 获取用户当前订阅状态
  static Future<UserSubscriptionStatus> getCurrentStatus() async {
    try {
      final res = await _dio.get(
        '/api/v1/subscription/status',
        options: Options(headers: _authHeaders()),
      );
      if (res.data?['success'] == true) {
        return UserSubscriptionStatus.fromJson(res.data['data']);
      }
    } catch (_) {
      // fallback
    }
    return UserSubscriptionStatus(
      planId: 'free',
      planName: '免费版',
      isActive: true,
      features: {'basic_chat': true, 'solar_terms': true},
    );
  }

  /// 创建订单（获取支付链接）
  static Future<SubscriptionOrder?> createOrder(
    String planId, {
    int period = 1,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/subscription/create-order',
        data: {'product_id': planId, 'platform': 'alipay'},
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
        : {'Authorization': 'Bearer $token'};
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

  /// 支付功能尚未上线，创建订单时返回 null
  /// 上线后对接真实支付 SDK

  /// 后端不可用时的硬编码 plan fallback
  static final List<SubscriptionPlan> _fallbackPlans = [
    SubscriptionPlan(
      id: 'free',
      name: '免费版',
      priceCents: 0,
      description: '基础功能，满足日常养生需求',
      features: {
        'basic_chat': true,
        'solar_terms': true,
        'unlimited_chat': false,
      },
      isCurrent: true,
    ),
    SubscriptionPlan(
      id: 'yangxin',
      name: '养心版',
      priceCents: 2900,
      priceYearlyCents: 19900,
      period: 'month',
      periodName: '月',
      description: '无限聊天+今日计划，适合养生爱好者',
      features: {
        'basic_chat': true,
        'solar_terms': true,
        'unlimited_chat': true,
        'today_plan': true,
      },
    ),
    SubscriptionPlan(
      id: 'yiyang',
      name: '颐养版',
      priceCents: 5900,
      priceYearlyCents: 39900,
      period: 'month',
      periodName: '月',
      description: '深度建议+周总结，适合养生达人',
      isRecommended: true,
      features: {
        'basic_chat': true,
        'solar_terms': true,
        'unlimited_chat': true,
        'today_plan': true,
        'deep_suggestions': true,
        'weekly_summary': true,
      },
    ),
    SubscriptionPlan(
      id: 'jiahe',
      name: '家和版',
      priceCents: 9900,
      priceYearlyCents: 69900,
      period: 'month',
      periodName: '月',
      description: '家庭共享（4席位），适合全家使用',
      familySeats: 4,
      features: {
        'basic_chat': true,
        'solar_terms': true,
        'unlimited_chat': true,
        'today_plan': true,
        'deep_suggestions': true,
        'weekly_summary': true,
        'family': true,
      },
    ),
  ];
}
