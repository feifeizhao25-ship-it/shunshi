import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/components/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No conversations yet',
              subtitle: 'Start chatting with your AI companion',
            ),
          ),
        ),
      );

      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Start chatting with your AI companion'), findsOneWidget);
    });

    testWidgets('displays action button when onAction provided', (tester) async {
      var actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No data',
              subtitle: 'Nothing to show',
              actionLabel: 'Refresh',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionPressed, true);
    });

    testWidgets('does not show action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No items',
              subtitle: 'The list is empty',
            ),
          ),
        ),
      );

      // No button should be present
      // The EmptyState should not render an action button
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No results',
              subtitle: 'Try a different search',
              icon: Icons.search_off,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });
}
