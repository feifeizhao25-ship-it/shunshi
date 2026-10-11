import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shunshi/data/services/store_connection.dart';

ProductDetailsResponse catalog(String price) => ProductDetailsResponse(
  productDetails: [
    ProductDetails(
      id: 'sku',
      title: '测试',
      description: '测试商品',
      price: price,
      rawPrice: 58,
      currencyCode: 'CNY',
    ),
  ],
  notFoundIDs: [],
);
void main() {
  test(
    'parallel initialization shares query and repeated refresh keeps one listener',
    () async {
      final stream = StreamController<List<PurchaseDetails>>.broadcast();
      final result = Completer<ProductDetailsResponse>();
      var queries = 0, listens = 0, events = 0;
      final connection = StoreConnection(
        checkAvailable: () async => true,
        purchaseStream: () {
          listens++;
          return stream.stream;
        },
        queryProducts: () {
          queries++;
          return result.future;
        },
        onPurchase: (_) {
          events++;
        },
        onStreamError: () {},
      );
      addTearDown(() async {
        await connection.dispose();
        await stream.close();
      });
      final first = connection.refresh(), second = connection.refresh();
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(queries, 1);
      expect(listens, 1);
      result.complete(catalog('¥58'));
      await Future.wait([first, second]);
      await connection.refresh();
      expect(queries, 2);
      expect(listens, 1);
      stream.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(events, 1);
      expect(() => connection.products.clear(), throwsUnsupportedError);
    },
  );
  test('unavailable store can recover on later refresh', () async {
    final stream = StreamController<List<PurchaseDetails>>.broadcast();
    var enabled = false;
    final connection = StoreConnection(
      checkAvailable: () async => enabled,
      purchaseStream: () => stream.stream,
      queryProducts: () async => catalog('¥58'),
      onPurchase: (_) {},
      onStreamError: () {},
    );
    addTearDown(() async {
      await connection.dispose();
      await stream.close();
    });
    await connection.refresh();
    expect(connection.available, isFalse);
    expect(connection.products, isEmpty);
    enabled = true;
    await connection.refresh();
    expect(connection.available, isTrue);
    expect(connection.products.single.price, '¥58');
  });
  test('failed refresh clears stale prices and permits retry', () async {
    final stream = StreamController<List<PurchaseDetails>>.broadcast();
    var failure = false;
    final connection = StoreConnection(
      checkAvailable: () async => true,
      purchaseStream: () => stream.stream,
      queryProducts: () async {
        if (failure) throw StateError('offline');
        return catalog('¥58');
      },
      onPurchase: (_) {},
      onStreamError: () {},
    );
    addTearDown(() async {
      await connection.dispose();
      await stream.close();
    });
    await connection.refresh();
    failure = true;
    await expectLater(connection.refresh(), throwsStateError);
    expect(connection.products, isEmpty);
    expect(connection.available, isFalse);
    failure = false;
    await connection.refresh();
    expect(connection.products.single.price, '¥58');
  });
  test('SDK error response is not accepted as a priced catalog', () async {
    final stream = StreamController<List<PurchaseDetails>>.broadcast();
    final connection = StoreConnection(
      checkAvailable: () async => true,
      purchaseStream: () => stream.stream,
      queryProducts: () async => ProductDetailsResponse(
        productDetails: catalog('¥58').productDetails,
        notFoundIDs: [],
        error: IAPError(source: 'fixture', code: 'offline', message: 'fixture'),
      ),
      onPurchase: (_) {},
      onStreamError: () {},
    );
    addTearDown(() async {
      await connection.dispose();
      await stream.close();
    });
    await expectLater(connection.refresh(), throwsStateError);
    expect(connection.products, isEmpty);
  });
  test(
    'dispose invalidates late results without clearing newer refresh',
    () async {
      final stream = StreamController<List<PurchaseDetails>>.broadcast();
      final old = Completer<ProductDetailsResponse>(),
          fresh = Completer<ProductDetailsResponse>();
      var queries = 0;
      final connection = StoreConnection(
        checkAvailable: () async => true,
        purchaseStream: () => stream.stream,
        queryProducts: () => ++queries == 1 ? old.future : fresh.future,
        onPurchase: (_) {},
        onStreamError: () {},
      );
      addTearDown(() async {
        await connection.dispose();
        await stream.close();
      });
      final first = connection.refresh();
      await Future<void>.delayed(Duration.zero);
      await connection.dispose();
      final second = connection.refresh();
      await Future<void>.delayed(Duration.zero);
      old.complete(catalog('¥1'));
      await first;
      expect(connection.products, isEmpty);
      expect(identical(connection.refresh(), second), isTrue);
      fresh.complete(catalog('¥58'));
      await second;
      expect(connection.products.single.price, '¥58');
    },
  );
  test('query timeout releases refresh for retry', () async {
    final stream = StreamController<List<PurchaseDetails>>.broadcast();
    var timeout = true;
    final connection = StoreConnection(
      checkAvailable: () async => true,
      purchaseStream: () => stream.stream,
      queryProducts: () => timeout
          ? Completer<ProductDetailsResponse>().future
          : Future.value(catalog('¥58')),
      onPurchase: (_) {},
      onStreamError: () {},
      timeout: const Duration(milliseconds: 5),
    );
    addTearDown(() async {
      await connection.dispose();
      await stream.close();
    });
    await expectLater(connection.refresh(), throwsA(isA<TimeoutException>()));
    expect(connection.products, isEmpty);
    timeout = false;
    await connection.refresh();
    expect(connection.available, isTrue);
  });
  test('closed purchase stream can attach again after refresh', () async {
    final old = StreamController<List<PurchaseDetails>>.broadcast(),
        fresh = StreamController<List<PurchaseDetails>>.broadcast();
    var count = 0, events = 0;
    final connection = StoreConnection(
      checkAvailable: () async => true,
      purchaseStream: () => ++count == 1 ? old.stream : fresh.stream,
      queryProducts: () async => catalog('¥58'),
      onPurchase: (_) {
        events++;
      },
      onStreamError: () {},
    );
    addTearDown(() async {
      await connection.dispose();
      await fresh.close();
    });
    await connection.refresh();
    await old.close();
    await connection.refresh();
    fresh.add([]);
    await Future<void>.delayed(Duration.zero);
    expect(count, 2);
    expect(events, 1);
  });
}
