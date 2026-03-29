// test/widget/widgets/empty_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/empty_state.dart';

void main() {
  group('EmptyState widget', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(message: '暂无内容'),
          ),
        ),
      );

      expect(find.text('暂无内容'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: '暂无数据',
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
  });
}
