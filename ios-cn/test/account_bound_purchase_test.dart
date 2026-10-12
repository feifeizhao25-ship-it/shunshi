import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/account_bound_purchase.dart';

void main() {
  const account = 'ca3328f4-3a98-51e4-afaa-c21de2a2d694';
  test(
    'server UUID is passed to purchase, never the login credential',
    () async {
      String? sent;
      final result = await launchAccountBoundPurchase(
        readToken: () => 'credential',
        loadAccountToken: (token) async {
          expect(token, 'credential');
          return account;
        },
        buy: (value) async {
          sent = value;
          return true;
        },
      );
      expect(result, isTrue);
      expect(sent, account);
    },
  );
  for (final value in <String?>[null, '', 'not-a-uuid']) {
    test('invalid association $value never opens payment sheet', () async {
      expect(
        await launchAccountBoundPurchase(
          readToken: () => 'credential',
          loadAccountToken: (_) async => value,
          buy: (_) async {
            fail('must not buy');
          },
        ),
        isFalse,
      );
    });
  }
  test('switching account during lookup prevents purchase', () async {
    var token = 'a';
    final lookup = Completer<String?>();
    final pending = launchAccountBoundPurchase(
      readToken: () => token,
      loadAccountToken: (_) => lookup.future,
      buy: (_) async {
        fail('must not buy');
      },
    );
    token = 'b';
    lookup.complete(account);
    expect(await pending, isFalse);
  });
  test(
    'late SDK result after logout does not report current-session success',
    () async {
      String? token = 'a';
      final sdk = Completer<bool>();
      final started = Completer<void>();
      final pending = launchAccountBoundPurchase(
        readToken: () => token,
        loadAccountToken: (_) async => account,
        buy: (_) {
          started.complete();
          return sdk.future;
        },
      );
      await started.future;
      token = null;
      sdk.complete(true);
      expect(await pending, isFalse);
    },
  );
  test('signed-out caller cannot fetch an association or purchase', () async {
    expect(
      await launchAccountBoundPurchase(
        readToken: () => null,
        loadAccountToken: (_) async {
          fail('must not fetch');
        },
        buy: (_) async {
          fail('must not buy');
        },
      ),
      isFalse,
    );
  });
  test('lookup failure has no unbound purchase fallback', () async {
    expect(
      await launchAccountBoundPurchase(
        readToken: () => 'a',
        loadAccountToken: (_) async => throw StateError('offline'),
        buy: (_) async {
          fail('must not buy');
        },
      ),
      isFalse,
    );
  });
}
