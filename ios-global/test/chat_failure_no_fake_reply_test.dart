// When the chat API fails, SEASONS must not invent a wellness reply (it used to answer "I can't sleep" with a
// foot-soak tip and diet cards). It shows an honest English error, keeps the message in the box for a retry,
// and adds no AI bubble. Network calls fail in flutter_test (every HTTP request gets a 400), so both chat
// endpoints fail here.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/chat/chat_failure.dart';
import 'package:seasons/presentation/pages/chat/seasons_chat_page.dart';
import 'package:seasons/presentation/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

DioException _dio(DioExceptionType type, [int? status]) => DioException(
      requestOptions: RequestOptions(path: '/ai/chat'),
      type: type,
      response: status == null ? null : Response(requestOptions: RequestOptions(path: '/ai/chat'), statusCode: status),
    );

void main() {
  final cjk = RegExp(r'[\u3400-\u9fff]');

  test('failure messages are English and never give advice', () {
    final messages = [
      chatFailureMessage(_dio(DioExceptionType.connectionError)),
      chatFailureMessage(_dio(DioExceptionType.badResponse, 401)),
      chatFailureMessage(_dio(DioExceptionType.badResponse, 429)),
      chatFailureMessage(_dio(DioExceptionType.badResponse, 422)),
      chatFailureMessage(_dio(DioExceptionType.receiveTimeout)),
      chatFailureMessage(_dio(DioExceptionType.badResponse, 500)),
      chatFailureMessage(StateError('bad payload')),
    ];
    expect(messages.first, seasonsOfflineChatNotice);
    expect(messages.toSet().length, messages.length);
    for (final m in messages) {
      expect(cjk.hasMatch(m), isFalse, reason: m);
      expect(m.toLowerCase(), isNot(contains('tea')));
      expect(m.toLowerCase(), isNot(contains('sleep')));
    }
  });

  testWidgets('a failed send shows an error, keeps the text and adds no AI reply', (tester) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    const message = "I can't sleep and feel tired";
    await tester.enterText(find.byType(TextField).last, message);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    // Let the two real (test-mocked) HTTP calls finish.
    for (var i = 0; i < 100 && find.byKey(const ValueKey('chat-error')).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const ValueKey('chat-error')), findsWidgets);
    expect(find.textContaining('soaking your feet'), findsNothing);
    expect(find.textContaining('ginger-date tea'), findsNothing);
    expect(find.textContaining('snow fungus'), findsNothing);
    expect(find.textContaining('based on TCM wellness principles'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller?.text, message);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('seasons chat request failure adds no assistant bubble', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SeasonsChatPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    const message = "I can't sleep and feel tired";
    await tester.enterText(find.byType(TextField).last, message);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    for (var i = 0; i < 100 && find.byKey(const ValueKey('chat-error')).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const ValueKey('chat-error')), findsOneWidget);
    expect(find.textContaining('trouble connecting'), findsNothing);
    expect(find.textContaining("I'm here"), findsNothing);
    expect(find.textContaining('soaking your feet'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller?.text, message);
    await tester.pumpWidget(const SizedBox());
  });
}
