import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/chat/chat_api.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';

class ChatAdapter implements HttpClientAdapter {
  final int status;
  final dynamic body;
  final requests = <RequestOptions>[];
  ChatAdapter(this.status, this.body);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    dynamic result = body;
    var code = status;
    if (options.path.endsWith('guest-login')) {
      result = {'access_token': 'guest-test-token'};
      code = 200;
    } else if (options.path.endsWith('subscription/status')) {
      result = {
        'success': true,
        'data': {'plan': 'free', 'is_active': false},
      };
      code = 200;
    } else if (options.path.endsWith('solar-terms/current')) {
      result = {};
      code = 503;
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'guest reads actual top-level access_token and rejects missing token',
    () {
      expect(parseGuestToken({'access_token': 'abc'}), 'abc');
      for (final body in [
        null,
        {},
        {'access_token': ''},
        {
          'data': {'token': 'wrong'},
        },
      ]) {
        expect(() => parseGuestToken(body), throwsFormatException);
      }
    },
  );
  test(
    'sends exactly one request to canonical JSON endpoint and preserves full reply',
    () async {
      final adapter = ChatAdapter(200, {
        'text': '第一段\n\n第二段|末尾',
        'sources': ['来源一', '来源二'],
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://local.test'))
        ..httpClientAdapter = adapter;
      final reply = await sendChat(dio, 'token', '今天想放松一下');
      expect(reply.text, '第一段\n\n第二段|末尾');
      expect(reply.sources, ['来源一', '来源二']);
      expect(adapter.requests.single.path, '/api/v1/chat/send');
      expect(adapter.requests.single.data, {'message': '今天想放松一下'});
      expect(adapter.requests.single.headers['Authorization'], 'Bearer token');
    },
  );
  test('empty or malformed success is rejected without retry', () async {
    for (final body in [
      {},
      {'text': '  '},
      {'text': 12},
      {
        'text': '正文',
        'sources': [42],
      },
    ]) {
      final adapter = ChatAdapter(200, body);
      final dio = Dio(BaseOptions(baseUrl: 'https://local.test'))
        ..httpClientAdapter = adapter;
      await expectLater(sendChat(dio, 'token', '问题'), throwsFormatException);
      expect(adapter.requests.length, 1);
    }
  });
  for (final status in [401, 429, 503, 200]) {
    testWidgets(
      'failure $status remains visible, preserves input and never counts an AI reply',
      (tester) async {
        SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
        final adapter = ChatAdapter(status, {});
        final dio = Dio(BaseOptions(baseUrl: 'https://local.test'))
          ..httpClientAdapter = adapter;
        await tester.pumpWidget(MaterialApp(home: ChatPage(client: dio)));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '今天想安排散步');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('chat-error')), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '今天想安排散步',
        );
        expect(
          (await SharedPreferences.getInstance()).getInt('chat_count'),
          isNull,
        );
        expect(
          adapter.requests.where((r) => r.path == '/api/v1/chat/send').length,
          1,
        );
        expect(
          adapter.requests.where(
            (r) => r.path == '/ai/chat' || r.path == '/api/v1/chat',
          ),
          isEmpty,
        );
        final error = tester
            .widget<Text>(find.byKey(const ValueKey('chat-error')))
            .data!;
        if (status == 401) expect(error, contains('登录'));
        if (status == 429) expect(error, contains('额度'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'guest token authenticates subsequent chat and full text is displayed',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final adapter = ChatAdapter(200, {
        'text': '第一段完整回复\n第二段完整回复',
        'sources': ['来源一'],
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://local.test'))
        ..httpClientAdapter = adapter;
      await tester.pumpWidget(MaterialApp(home: ChatPage(client: dio)));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        'guest-test-token',
      );
      await tester.enterText(find.byType(TextField), '今天想安排散步');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(find.textContaining('第一段完整回复\n第二段完整回复'), findsOneWidget);
      expect(find.text('来源一'), findsOneWidget);
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer guest-test-token',
      );
      expect((await SharedPreferences.getInstance()).getInt('chat_count'), 1);
      expect(find.byKey(const ValueKey('chat-error')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
