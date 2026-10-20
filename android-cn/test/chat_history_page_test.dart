import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';

void main() {
  testWidgets(
    'history renders even when membership and solar term HTTP requests fail',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'local-test-token',
        'chat_history': 'user|之前的问题\nai|回复第一段\n回复第二段必须保留',
      });
      await tester.pumpWidget(const MaterialApp(home: ChatPage()));
      await tester.pumpAndSettle();
      expect(find.text('回复第一段\n回复第二段必须保留'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
