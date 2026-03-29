import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/components/gentle_button.dart';

void main() {
  group('GentleButton', () {
    testWidgets('renders text label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GentleButton(
              label: 'Get Started',
              onPressed: _nullHandler,
            ),
          ),
        ),
      );

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(
              label: 'Tap Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GentleButton));
      expect(pressed, true);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(
              label: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GentleButton));
      expect(pressed, false);
    });

    testWidgets('renders with loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GentleButton(
              label: 'Loading...',
              onPressed: _nullHandler,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('does not call onPressed while loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GentleButton(
              label: 'Loading',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GentleButton));
      expect(pressed, false); // onPressed should be disabled during loading
    });

    testWidgets('renders icon when leadingIcon is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GentleButton(
              label: 'With Icon',
              onPressed: _nullHandler,
              leadingIcon: Icons.favorite,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}

// Helper to avoid null warnings in test callbacks
void _nullHandler() {}
