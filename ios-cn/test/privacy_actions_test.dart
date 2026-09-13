import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/profile/privacy_page.dart';

Response<dynamic> reply(String path, Object data) => Response<dynamic>(
  requestOptions: RequestOptions(path: path), data: data, statusCode: 200);

void main() {
  testWidgets('export waits for server data and shows actual JSON', (tester) async {
    final result = Completer<Response<dynamic>>();
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(home: PrivacyPage(request: (method, path) {
      calls.add('$method $path');
      return result.future;
    })));
    await tester.tap(find.text('导出我的数据'));
    await tester.pump();
    expect(find.text('我的账户数据'), findsNothing);
    expect(find.text('数据导出成功，已保存'), findsNothing);
    result.complete(reply('/api/v1/auth/data/export', {
      'user': {'id': 'test-user'}, 'domestic_billing': {'refund_requests': []}
    }));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(calls, ['POST /api/v1/auth/data/export']);
    expect(find.text('我的账户数据'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data, contains('test-user'));
    expect(find.text('复制 JSON'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
  });

  testWidgets('unconfirmed memory response never reports cleared', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(home: PrivacyPage(request: (method, path) async {
      calls.add('$method $path');
      return reply(path, {'deleted': false});
    })));
    await tester.ensureVisible(find.text('清空 AI 记忆'));
    await tester.tap(find.text('清空 AI 记忆'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tester.tap(find.text('确认清空'));
    await tester.pumpAndSettle();
    expect(calls, ['DELETE /api/v1/memory/all']);
    expect(find.text('服务端对话记忆已清空'), findsNothing);
    expect(find.text('清空未确认，请检查登录状态和网络后重试'), findsOneWidget);
  });

  testWidgets('deletion explains retained billing and requires server confirmation', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(home: PrivacyPage(request: (method, path) async {
      calls.add('$method $path');
      return reply(path, {'deleted': false});
    })));
    await tester.tap(find.text('注销账号'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.textContaining('注销不会自动退款'), findsOneWidget);
    await tester.tap(find.text('确认注销'));
    await tester.pumpAndSettle();
    expect(calls, ['DELETE /api/v1/auth/account']);
    expect(find.text('注销未确认，请检查网络后重试'), findsOneWidget);
  });
}
