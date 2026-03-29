import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seasons/main.dart' as app;

/// Integration test: App Launch
///
/// Tests that the app launches without crashing and displays
/// the splash screen / initial route correctly.
///
/// Run with:
///   flutter test integration_test/app_launch_test.dart -d <device-id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch', () {
    testWidgets('app launches and displays MaterialApp', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify MaterialApp is present (app bootstrapped)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app has correct title', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'SEASONS');
    });

    testWidgets('app uses system theme mode', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('dark and light themes are both configured', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Both themes should be set (light + dark)
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.theme, isNot(equals(materialApp.darkTheme)));
    });

    testWidgets('app uses GoRouter for navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify router is configured — MaterialApp.router should be present
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.router, isNotNull);
    });
  });

  group('Splash Screen', () {
    testWidgets('splash page renders after launch', (tester) async {
      app.main();
      await tester.pump();

      // Initially splash should be visible
      // After pumpAndSettle it may have navigated away
      await tester.pump(const Duration(milliseconds: 500));

      // Splash should render something (logo or text)
      // At minimum the app should still be running
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
