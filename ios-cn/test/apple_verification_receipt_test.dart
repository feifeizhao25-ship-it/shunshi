import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/apple_verification_receipt.dart';

void main() {
  test('StoreKit2 JWS is replaced by native app receipt', () async {
    expect(
      await appleVerificationReceipt(
        storeKit2: true,
        eventData: 'header.payload.signature',
        readAppReceipt: () async => 'native-base64-receipt',
      ),
      'native-base64-receipt',
    );
  });
  test(
    'legacy receipts and other platforms do not read native iOS data',
    () async {
      expect(
        await appleVerificationReceipt(
          storeKit2: false,
          eventData: 'event-receipt',
          readAppReceipt: () async {
            fail('must not call');
          },
        ),
        'event-receipt',
      );
    },
  );
  for (final value in ['', ' ', 'header.payload.signature']) {
    test('missing or JWS receipt fails closed: $value', () async {
      await expectLater(
        appleVerificationReceipt(
          storeKit2: true,
          eventData: 'jws',
          readAppReceipt: () async => value,
        ),
        throwsStateError,
      );
    });
  }
  test('native receipt timeout does not hang the transaction queue', () async {
    await expectLater(
      appleVerificationReceipt(
        storeKit2: true,
        eventData: 'jws',
        timeout: const Duration(milliseconds: 10),
        readAppReceipt: () => Completer<String>().future,
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
