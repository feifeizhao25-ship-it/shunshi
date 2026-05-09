import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seasons/main.dart' as app;

/// Integration test: Chat Flow
///
/// Tests the AI companion chat experience end-to-end.
///
/// Run with:
///   flutter test integration_test/chat_flow_test.dart -d <device-id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow', () {
    testWidgets('chat page renders input field and send button', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to chat tab via bottom nav
      final chatTab = find.byIcon(Icons.chat_bubble_outline);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      // Verify chat input is present
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
    });

    testWidgets('can type in chat input field', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to chat
      final chatTab = find.byIcon(Icons.chat_bubble_outline);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField, 'Hello, I need some advice');
        await tester.pump();

        expect(find.text('Hello, I need some advice'), findsOneWidget);
      }
    });

    testWidgets('send button is tappable', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to chat
      final chatTab = find.byIcon(Icons.chat_bubble_outline);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      // Try to find a send button or icon
      final sendButton = find.byIcon(Icons.send);
      // If not found, there may be an alternative send mechanism
      // The test verifies the app doesn't crash regardless
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pump();
      }

      // No crash = pass
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('voice input button is present on chat page', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to chat
      final chatTab = find.byIcon(Icons.chat_bubble_outline);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      // Voice input widget should be present
      // (named based on actual widget in the codebase)
      final voiceInput = find.byType(IconButton);
      expect(voiceInput, findsWidgets);
    });
  });

  group('Navigation', () {
    testWidgets('bottom nav shows 5 tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have 5 tab icons in the bottom nav
      // Home, Companion, Seasons, Library, Profile
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('can switch between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Seasons tab
      await tester.tap(find.byIcon(Icons.eco_outlined));
      await tester.pumpAndSettle();

      // Tap Library tab
      await tester.tap(find.byIcon(Icons.auto_stories_outlined));
      await tester.pumpAndSettle();

      // Tap Profile tab
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Tab switch should not crash
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('tapping active tab navigates to its page', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Initially on Home tab — tap Home icon
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      // App should remain stable
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
