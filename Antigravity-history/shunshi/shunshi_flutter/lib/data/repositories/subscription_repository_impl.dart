import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/entities/subscription_state.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/logger.dart';
import '../datasources/remote/ai_router_datasource.dart';

/// StoreKit/Billing 真实购买实现
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final InAppPurchase _iap = InAppPurchase.instance;
  final AIRouterDatasource _remoteDatasource;
  final _stateController = StreamController<SubscriptionState>.broadcast();

  SubscriptionRepositoryImpl(this._remoteDatasource) {
    _initIap();
  }

  void _initIap() {
    _iap.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _stateController.close();
    }, onError: (error) {
      Logger.error('IAP Stream Error', error: error);
    });
  }

  @override
  Future<SubscriptionState> getEntitlement() async {
    try {
      final res = await _remoteDatasource.getUserEntitlement();
      final isActive = res['is_active'] == true;
      final state = SubscriptionState(
        status: isActive ? SubscriptionStatus.active : SubscriptionStatus.none,
        productId: res['product_id'],
        expirationDate: res['expires_at'] != null ? DateTime.parse(res['expires_at']) : null,
        purchaseDate: res['purchased_at'] != null ? DateTime.parse(res['purchased_at']) : null,
      );
      _stateController.add(state);
      return state;
    } catch (e) {
      return const SubscriptionState();
    }
  }

  @override
  Stream<SubscriptionState> listenEntitlement() {
    return _stateController.stream;
  }

  @override
  Future<SubscriptionState> purchase(String productId) async {
    final available = await _iap.isAvailable();
    if (!available) throw const ServerException('应用内购买不可用');

    final response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      throw const ServerException('商品不存在');
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    
    // 触发原生购买底窗
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    
    // 返回 pending 状态，后续通过 listenEntitlement 更新
    return const SubscriptionState(status: SubscriptionStatus.pending);
  }

  @override
  Future<SubscriptionState> restore() async {
    await _iap.restorePurchases();
    return const SubscriptionState(status: SubscriptionStatus.pending);
  }

  @override
  Future<List<SubscriptionProduct>> getProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];

    final ids = {
      AppConstants.monthlyPremiumId,
      AppConstants.annualPremiumId
    };
    
    final response = await _iap.queryProductDetails(ids);
    return response.productDetails.map((pd) => SubscriptionProduct(
      id: pd.id,
      title: pd.title,
      description: pd.description,
      price: pd.price,
      currencyCode: pd.currencyCode,
    )).toList();
  }

  @override
  Future<SubscriptionState> verifyReceipt(String receipt) async {
    try {
      final res = await _remoteDatasource.verifyReceipt(receipt);
      final state = SubscriptionState(
        status: res['is_active'] == true ? SubscriptionStatus.active : SubscriptionStatus.expired,
        productId: res['product_id'],
        expirationDate: res['expires_at'] != null ? DateTime.parse(res['expires_at']) : null,
      );
      _stateController.add(state);
      return state;
    } catch (e) {
      throw const ServerException('收据验证失败');
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _stateController.add(const SubscriptionState(status: SubscriptionStatus.pending));
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _stateController.add(const SubscriptionState(status: SubscriptionStatus.expired));
        Logger.error('Purchase Failed', error: purchaseDetails.error);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // 完成购买，向服务器验证 receipt
        try {
          final receipt = purchaseDetails.verificationData.serverVerificationData;
          await verifyReceipt(receipt);
        } catch (e) {
          Logger.error('Receipt Verification Failed', error: e);
          _stateController.add(const SubscriptionState(status: SubscriptionStatus.expired));
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }
}
