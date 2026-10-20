import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';
import 'package:shunshi/presentation/pages/chat/chat_membership.dart';

class MembershipAdapter implements HttpClientAdapter {
  dynamic response;
  int status = 200;
  MembershipAdapter(this.response);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/subscription/status')) {
      return ResponseBody.fromString(
        jsonEncode(response),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString('{}', 503);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> membership(String plan, bool active) => {
  'success': true,
  'tier': active ? 'premium' : 'free',
  'data': {'plan': plan, 'is_active': active, 'plan_name': '测试套餐'},
};
void main() {
  test(
    'actual membership contract handles free and all paid plans without data.tier',
    () {
      expect(parseChatMembership(membership('free', false)), isFalse);
      for (final plan in ['yangxin', 'yiyang', 'jiahe']) {
        expect(parseChatMembership(membership(plan, true)), isTrue);
      }
    },
  );
  test('missing, unknown and contradictory fields never grant membership', () {
    for (final value in [
      null,
      {},
      {'success': true, 'data': {}},
      membership('unknown', true),
      membership('free', true),
      membership('jiahe', false),
    ]) {
      expect(() => parseChatMembership(value), throwsFormatException);
    }
  });
  for (final plan in ['free', 'yangxin', 'yiyang', 'jiahe']) {
    testWidgets('$plan badge follows server fields without fabricated quota', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
      final dio = Dio(BaseOptions(baseUrl: 'https://local.test'));
      dio.httpClientAdapter = MembershipAdapter(
        membership(plan, plan != 'free'),
      );
      await tester.pumpWidget(MaterialApp(home: ChatPage(client: dio)));
      await tester.pumpAndSettle();
      expect(find.text(plan == 'free' ? '免费版' : '会员'), findsOneWidget);
      expect(find.text('10/10'), findsNothing);
      expect(find.text('状态待查询'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('failed lookup is unknown and retry restores verified state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
    final dio = Dio(BaseOptions(baseUrl: 'https://local.test'));
    final adapter = MembershipAdapter({})..status = 503;
    dio.httpClientAdapter = adapter;
    await tester.pumpWidget(MaterialApp(home: ChatPage(client: dio)));
    await tester.pumpAndSettle();
    expect(find.text('状态待查询'), findsOneWidget);
    expect(find.text('会员'), findsNothing);
    expect(find.text('免费版'), findsNothing);
    adapter.response = membership('jiahe', true);
    adapter.status = 200;
    await tester.tap(find.text('会员状态暂未查到，点击重试'));
    await tester.pumpAndSettle();
    expect(find.text('会员'), findsOneWidget);
    expect(find.text('状态待查询'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
