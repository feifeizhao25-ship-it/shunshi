import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/datasources/subscription_service.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/presentation/pages/subscription/subscription_page_v2.dart';

void main() {
  Dio client(dynamic body, {bool offline = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/v1/subscription/status');
          expect(options.headers['Authorization'], 'Bearer owner');
          if (offline) {
            handler.reject(DioException(requestOptions: options));
          } else {
            handler.resolve(
              Response(requestOptions: options, data: body, statusCode: 200),
            );
          }
        },
      ),
    );
    return dio;
  }

  const headers = {'Authorization': 'Bearer owner'};
  test('valid free and paid states come from the response', () async {
    for (final paid in [false, true]) {
      final result = await SubscriptionService.fetchCurrentStatus(
        client({
          'success': true,
          'data': {
            'plan': paid ? 'jiahe' : 'free',
            'plan_name': paid ? '家和版' : '免费版',
            'is_active': paid,
            'features': {},
            'expires_at': paid ? 1798761600 : null,
          },
        }),
        headers: headers,
      );
      expect(result.isActive, paid);
      expect(result.planId, paid ? 'jiahe' : 'free');
      expect(result.expiresAt != null, paid);
    }
  });
  test('network failure is not a fabricated free subscription', () async {
    await expectLater(
      SubscriptionService.fetchCurrentStatus(
        client(null, offline: true),
        headers: headers,
      ),
      throwsA(isA<DioException>()),
    );
  });
  for (final body in [
    null,
    {'success': false},
    {'success': true, 'data': {}},
    {
      'success': true,
      'data': {'plan': 'free', 'plan_name': '免费版', 'is_active': 'true'},
    },
  ]) {
    test('reject malformed response $body', () async {
      await expectLater(
        SubscriptionService.fetchCurrentStatus(client(body), headers: headers),
        throwsStateError,
      );
    });
  }
  testWidgets('failure is shown without free banner; retry loads paid state', (
    tester,
  ) async {
    var fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: SubscriptionPageV2(
          loadPlans: () async => [],
          loadStatus: () async {
            if (fail) throw StateError('offline');
            return UserSubscriptionStatus(
              planId: 'jiahe',
              planName: '家和版',
              isActive: true,
              features: {},
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('会员状态暂时无法查询，请检查网络后重试'), findsOneWidget);
    expect(find.text('免费版'), findsNothing);
    fail = false;
    await tester.tap(find.text('重新查询'));
    await tester.pumpAndSettle();
    expect(find.text('家和版'), findsWidgets);
    expect(find.text('会员有效'), findsOneWidget);
    expect(find.text('ACTIVE'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
