import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';

class _Offline implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI identity notice is shown once and the menu label is Chinese', (tester) async {
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'page-user'})))}.signature';
    SharedPreferences.setMockInitialValues({'auth_token': token});
    final dio = Dio()..httpClientAdapter = _Offline();

    await tester.pumpWidget(MaterialApp(home: ChatPage(client: dio)));
    await tester.pumpAndSettle();

    expect(find.text('你在和人工智能对话，不是真人。'), findsOneWidget);
    expect(find.text('你在和人工智能对话，不是真人'), findsNothing);
    expect(find.byTooltip('打开菜单'), findsOneWidget);
    expect(find.byTooltip('Show menu'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
