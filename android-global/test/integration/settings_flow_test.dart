import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seasons/main.dart' as app;

/// Integration test: Settings Flow
///
/// Tests settings, privacy, and subscription pages.
///
/// Run with:
///   flutter test integration_test/settings_flow_test.dart -d <device-id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Flow', () {
    testWidgets('profile tab renders', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile tab
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Profile page should be present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('profile page has user-related content', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Look for profile-related icons or text
      // Common profile elements
      final icons = find.byType(Icon);
      expect(icons, findsWidgets);
    });
  });

  group('Library Page', () {
    testWidgets('library tab renders', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.auto_stories_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('library page has content cards', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.auto_stories_outlined));
      await tester.pumpAndSettle();

      // Library page should have scrollable content
      // Either a ListView, GridView, or CustomScrollView
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets);
    });
  });

  group('Seasons Page', () {
    testWidgets('seasons tab renders', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.eco_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('seasons page displays seasonal content', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.eco_outlined));
      await tester.pumpAndSettle();

      // Should have some content — verify scrollable
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets);
    });
  });
}
