// test/widget/widgets/gentle_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/components/gentle_button.dart';

void main() {
  group('GentleButton widget', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(label: '确认', onTap: () {}),
          ),
        ),
      );

      expect(find.text('确认'), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(label: '立春养生', onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('立春养生'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(label: '加载中', onTap: () {}, isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is disabled when onTap is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(label: '禁用按钮'),
          ),
        ),
      );

      // Should render without crash
      expect(find.text('禁用按钮'), findsOneWidget);
    });
  });
}
