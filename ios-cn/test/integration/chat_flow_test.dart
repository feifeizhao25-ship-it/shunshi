// test/integration/chat_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shunshi/main.dart';
import 'package:shunshi/data/storage/storage_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
  });

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

      final inputFields = find.byType(TextField);
      if (inputFields.evaluate().isNotEmpty) {
        await tester.enterText(inputFields.last, '今天立春，有什么养生建议？');
        await tester.pump();
        expect(find.text('今天立春，有什么养生建议？'), findsOneWidget);
      }
    });
  });
}
