import 'dart:convert';
import 'package:shunshi/presentation/pages/chat/chat_history_store.dart';
import 'package:shunshi/presentation/pages/chat/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';

void main() {
  testWidgets(
    'history renders even when membership and solar term HTTP requests fail',
    (tester) async {
      final token =
          'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'page-user'})))}.signature';
      SharedPreferences.setMockInitialValues({'auth_token': token});
      final prefs = await SharedPreferences.getInstance();
      await ChatHistoryStore(prefs, token).save([
        ChatMessage(role: 'ai', text: '回复第一段\n回复第二段必须保留', time: '12:00'),
      ], 'page-conversation');
      await tester.pumpWidget(const MaterialApp(home: ChatPage()));
      await tester.pumpAndSettle();
      expect(find.text('回复第一段\n回复第二段必须保留'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('unowned legacy content is not displayed to a signed in user', (
    tester,
  ) async {
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'new-user'})))}.signature';
    SharedPreferences.setMockInitialValues({
      'auth_token': token,
      'chat_history': 'ai|其他账户的私密内容',
      'conversation_id': 'old-account',
    });
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));
    await tester.pumpAndSettle();
    expect(find.text('其他账户的私密内容'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('explicit conversation displays its own complete history', (
    tester,
  ) async {
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'same-user'})))}.signature';
    SharedPreferences.setMockInitialValues({'auth_token': token});
    final prefs = await SharedPreferences.getInstance();
    final store = ChatHistoryStore(prefs, token);
    await store.save([
      ChatMessage(role: 'ai', text: '指定会话完整正文', time: '12:00'),
    ], 'selected');
    await store.save([
      ChatMessage(role: 'ai', text: '其他会话正文', time: '12:01'),
    ], 'latest');
    await tester.pumpWidget(
      const MaterialApp(home: ChatPage(conversationId: 'selected')),
    );
    await tester.pumpAndSettle();
    expect(find.text('指定会话完整正文'), findsOneWidget);
    expect(find.text('其他会话正文'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
