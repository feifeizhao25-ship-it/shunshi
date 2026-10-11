import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/datasources/subscription_service.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/presentation/pages/subscription/subscription_page_v2.dart';

void main() {
  Dio client(dynamic products, {bool offline = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          expect(o.path, '/api/v1/subscription/products');
          expect(o.queryParameters, {'platform': 'alipay'});
          if (offline) {
            h.reject(DioException(requestOptions: o));
          } else {
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'products': products},
                },
              ),
            );
          }
        },
      ),
    );
    return dio;
  }

  test('preserve server prices and fractions of yuan', () async {
    final plans = await SubscriptionService.fetchPlans(
      client([
        {
          'product_id': 'yiyang_monthly',
          'tier': 'yiyang',
          'duration_days': 30,
          'name': '颐养版',
          'price': 58.88,
        },
        {'id': 'jiahe', 'name': '家和版', 'price_cents': 68899.0},
      ]),
    );
    expect(plans[0].tier, 'yiyang');
    expect(plans[0].periodName, '30天');
    expect(plans[0].priceCents, 5888);
    expect(plans[0].priceDisplay, '¥58.88');
    expect(plans[1].priceCents, 68899);
    expect(plans[1].priceDisplay, '¥688.99');
  });
  test('offline does not return fabricated prices', () async {
    await expectLater(
      SubscriptionService.fetchPlans(client(null, offline: true)),
      throwsA(isA<DioException>()),
    );
  });
  test('valid empty catalog remains empty', () async {
    expect(await SubscriptionService.fetchPlans(client([])), isEmpty);
  });
  for (final price in [null, -1, 0, double.infinity]) {
    test('reject invalid paid price $price', () async {
      await expectLater(
        SubscriptionService.fetchPlans(
          client([
            {'id': 'yiyang', 'name': '颐养版', 'price': price},
          ]),
        ),
        throwsStateError,
      );
    });
  }
  test('reject duplicate IDs and fractional cents', () async {
    final p = {'id': 'yiyang', 'name': '颐养版', 'price': 59};
    await expectLater(
      SubscriptionService.fetchPlans(client([p, p])),
      throwsStateError,
    );
    await expectLater(
      SubscriptionService.fetchPlans(
        client([
          {'id': 'yiyang', 'name': '颐养版', 'price_cents': 1.2},
        ]),
      ),
      throwsStateError,
    );
  });
  testWidgets(
    'one purchase flow across payment selection and order creation; released after failure',
    (tester) async {
      var selections = 0, orders = 0;
      final method = Completer<String?>();
      final order = Completer<SubscriptionOrder?>();
      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionPageV2(
            loadStatus: () async => UserSubscriptionStatus(
              planId: 'free',
              planName: '免费版',
              isActive: false,
              features: {},
            ),
            loadPlans: () async => [
              SubscriptionPlan(
                id: 'yiyang',
                name: '颐养版',
                priceCents: 5888,
                description: '测试',
                features: {},
                isRecommended: true,
              ),
              SubscriptionPlan(
                id: 'jiahe',
                name: '家和版',
                priceCents: 9900,
                description: '测试',
                features: {},
              ),
            ],
            choosePaymentMethod: () {
              selections++;
              return method.future;
            },
            createOrder: (id, payment) {
              orders++;
              expect(payment, 'alipay');
              return order.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('开通').first);
      await tester.tap(find.text('开通').first);
      await tester.pump();
      await tester.ensureVisible(find.text('开通').last);
      await tester.tap(find.text('开通').last);
      await tester.pump();
      expect(selections, 1);
      expect(orders, 0);
      method.complete('alipay');
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('开通').last);
      await tester.pump();
      expect(orders, 1);
      expect(selections, 1);
      order.complete(null);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('开通').first);
      await tester.tap(find.text('开通').first);
      await tester.pumpAndSettle();
      expect(selections, 2);
      expect(orders, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
