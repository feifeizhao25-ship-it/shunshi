import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shunshi/data/services/purchase_update_processor.dart';

PurchaseDetails transaction(
  String id,
  PurchaseStatus status, {
  bool pending = true,
}) => PurchaseDetails(
  purchaseID: id,
  productID: 'com.shunshi.yiyang.yearly',
  transactionDate: '1',
  verificationData: PurchaseVerificationData(
    localVerificationData: 'fixture',
    serverVerificationData: 'fixture',
    source: 'app_store',
  ),
  status: status,
)..pendingCompletePurchase = pending;

void main() {
  test(
    'restored transaction waits for successful server verification',
    () async {
      final verified = Completer<bool>();
      final events = <String>[];
      final processor = PurchaseUpdateProcessor(
        verifyPurchase: (_) async => true,
        verifyRestore: (_) {
          events.add('verify');
          return verified.future;
        },
        completePurchase: (p) async {
          events.add('complete');
        },
        onTerminal: (_) {},
        onError: () {
          events.add('error');
        },
      );
      final result = processor.handle([
        transaction('r', PurchaseStatus.restored),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['verify']);
      verified.complete(true);
      await result;
      expect(events, ['verify', 'complete']);
    },
  );
  for (final status in [PurchaseStatus.restored, PurchaseStatus.purchased]) {
    test(
      '$status failure leaves transaction pending; later retry succeeds',
      () async {
        var valid = false;
        final completed = <String?>[];
        final processor = PurchaseUpdateProcessor(
          verifyPurchase: (_) async => valid,
          verifyRestore: (_) async => valid,
          completePurchase: (p) async {
            completed.add(p.purchaseID);
          },
          onTerminal: (_) {},
          onError: () {},
        );
        final p = transaction('retry', status);
        await processor.handle([p]);
        expect(completed, isEmpty);
        valid = true;
        await processor.handle([p]);
        expect(completed, ['retry']);
      },
    );
  }
  test(
    'pending is never completed; terminal failures are cleaned without verification',
    () async {
      final completed = <String?>[], terminal = <String?>[];
      final processor = PurchaseUpdateProcessor(
        verifyPurchase: (_) async => throw StateError('must not verify'),
        verifyRestore: (_) async => throw StateError('must not verify'),
        completePurchase: (p) async {
          completed.add(p.purchaseID);
        },
        onTerminal: (p) {
          terminal.add(p.purchaseID);
        },
        onError: () {
          fail('unexpected verification');
        },
      );
      await processor.handle([
        transaction('pending', PurchaseStatus.pending),
        transaction('error', PurchaseStatus.error),
        transaction('cancel', PurchaseStatus.canceled),
      ]);
      expect(completed, ['error', 'cancel']);
      expect(terminal, ['error', 'cancel']);
    },
  );
  test(
    'overlapping batches are serialized through verification and completion',
    () async {
      final barrier = Completer<bool>();
      final events = <String>[];
      final processor = PurchaseUpdateProcessor(
        verifyPurchase: (_) async => true,
        verifyRestore: (p) {
          events.add('verify-${p.purchaseID}');
          return p.purchaseID == 'first' ? barrier.future : Future.value(true);
        },
        completePurchase: (p) async {
          events.add('complete-${p.purchaseID}');
        },
        onTerminal: (_) {},
        onError: () {},
      );
      final first = processor.handle([
        transaction('first', PurchaseStatus.restored),
      ]);
      final second = processor.handle([
        transaction('second', PurchaseStatus.restored),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['verify-first']);
      barrier.complete(true);
      await Future.wait([first, second]);
      expect(events, [
        'verify-first',
        'complete-first',
        'verify-second',
        'complete-second',
      ]);
    },
  );
  test(
    'verification and completion exceptions do not poison later batches',
    () async {
      final completed = <String?>[];
      var errors = 0;
      final processor = PurchaseUpdateProcessor(
        verifyPurchase: (p) async {
          if (p.purchaseID == 'verify-error') throw StateError('injected');
          return true;
        },
        verifyRestore: (_) async => true,
        completePurchase: (p) async {
          if (p.purchaseID == 'complete-error') throw StateError('injected');
          completed.add(p.purchaseID);
        },
        onTerminal: (_) {},
        onError: () {
          errors++;
        },
      );
      await processor.handle([
        transaction('verify-error', PurchaseStatus.purchased),
        transaction('complete-error', PurchaseStatus.restored),
      ]);
      await processor.handle([
        transaction('ok', PurchaseStatus.restored),
        transaction(
          'already-finished',
          PurchaseStatus.purchased,
          pending: false,
        ),
      ]);
      expect(errors, 2);
      expect(completed, ['ok']);
    },
  );
}
