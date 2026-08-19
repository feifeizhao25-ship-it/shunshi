import '../../data/models/subscription_state.dart';

abstract class SubscriptionRepository {
  /// 获取当前权益状态（冷启动刷新）
  Future<SubscriptionState> getEntitlement();

  /// 监听权益变化流（购买回调、前台刷新）
  Stream<SubscriptionState> listenEntitlement();

  /// 发起购买
  Future<SubscriptionState> purchase(String productId);

  /// 恢复购买
  Future<SubscriptionState> restore();

  /// 获取可用商品列表
  Future<List<SubscriptionProduct>> getProducts();
}

class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final SubscriptionPeriod period;

  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.period,
  });
}

enum SubscriptionPeriod { monthly, quarterly, yearly }

extension SubscriptionPeriodX on SubscriptionPeriod {
  String get label {
    switch (this) {
      case SubscriptionPeriod.monthly:
        return '月度';
      case SubscriptionPeriod.quarterly:
        return '季度';
      case SubscriptionPeriod.yearly:
        return '年度';
    }
  }
}
