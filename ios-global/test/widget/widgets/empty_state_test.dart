import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/empty_state.dart';

void main() {
  group('EmptyState widget', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.inbox_outlined, title: '暂无内容'),
          ),
        ),
      );

      expect(find.text('暂无内容'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.inbox_outlined, title: 'Empty'),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: '暂无数据',
              actionLabel: '刷新',
              onAction: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('刷新'), findsOneWidget);
      await tester.tap(find.text('刷新'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No data',
              description: 'Try again later',
            ),
          ),
        ),
      );

      expect(find.text('No data'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
    });
  });
}
