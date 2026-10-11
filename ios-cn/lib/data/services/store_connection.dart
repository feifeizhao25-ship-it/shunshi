import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// One store listener and one catalog refresh at a time.
class StoreConnection {
  StoreConnection({
    required this.checkAvailable,
    required this.purchaseStream,
    required this.queryProducts,
    required this.onPurchase,
    required this.onStreamError,
    this.timeout = const Duration(seconds: 15),
  });
  final Future<bool> Function() checkAvailable;
  final Stream<List<PurchaseDetails>> Function() purchaseStream;
  final Future<ProductDetailsResponse> Function() queryProducts;
  final void Function(List<PurchaseDetails>) onPurchase;
  final void Function() onStreamError;
  final Duration timeout;
  bool available = false;
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => List.unmodifiable(_products);
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void>? _refresh;
  int _generation = 0;

  Future<void> refresh() {
    final generation = _generation;
    return _refresh ??= _load(generation).whenComplete(() {
      if (generation == _generation) _refresh = null;
    });
  }

  Future<void> _load(int generation) async {
    try {
      final enabled = await checkAvailable().timeout(timeout);
      if (generation != _generation) return;
      available = enabled;
      if (!enabled) {
        _products = [];
        return;
      }
      _subscription ??= purchaseStream().listen(
        onPurchase,
        onError: (Object error) => onStreamError(),
        onDone: () {
          if (generation == _generation) _subscription = null;
        },
      );
      final response = await queryProducts().timeout(timeout);
      if (generation != _generation) return;
      if (response.error != null) throw StateError('商店商品查询失败');
      _products = List.of(response.productDetails);
    } catch (_) {
      if (generation == _generation) {
        available = false;
        _products = [];
      }
      rethrow;
    }
  }

  Future<void> dispose() async {
    ++_generation;
    _refresh = null;
    available = false;
    _products = [];
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
