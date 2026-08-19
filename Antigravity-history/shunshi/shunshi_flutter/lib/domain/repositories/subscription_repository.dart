import '../entities/subscription_state.dart';

/// 订阅仓库抽象 — 统一 StoreKit2 + Google Play Billing
abstract class SubscriptionRepository {
  /// 查询当前权益
  Future<SubscriptionState> getEntitlement();

  /// 实时监听订阅状态变更
  Stream<SubscriptionState> listenEntitlement();

  /// 发起购买
  Future<SubscriptionState> purchase(String productId);

  /// 恢复购买
  Future<SubscriptionState> restore();

  /// 查询可购买商品列表
  Future<List<SubscriptionProduct>> getProducts();

  /// 服务端收据验证
  Future<SubscriptionState> verifyReceipt(String receipt);
}
