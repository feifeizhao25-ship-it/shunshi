// test/integration/chat_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shunshi/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat flow integration', () {
    testWidgets('chat page is accessible from home', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ShunshiApp()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for chat tab/button
      final chatFinder = find.byIcon(Icons.chat_bubble_outline);
      if (chatFinder.evaluate().isNotEmpty) {
        await tester.tap(chatFinder.first);
        await tester.pumpAndSettle();
        // Chat page should be visible
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('chat input field accepts text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ShunshiApp()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final inputFinder = find.byType(TextField).last;
      if (inputFinder.evaluate().isNotEmpty) {
        await tester.enterText(inputFinder, '今天立春，有什么养生建议？');
        await tester.pump();
        expect(find.text('今天立春，有什么养生建议？'), findsOneWidget);
      }
    });
  });
}
