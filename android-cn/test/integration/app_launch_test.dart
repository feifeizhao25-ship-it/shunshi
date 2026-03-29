// test/integration/app_launch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shunshi/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App launch integration', () {
    testWidgets('app starts without crash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ShunshiApp()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should show either splash or login
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app title is 顺时 ShunShi', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ShunshiApp()),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, '顺时 ShunShi');
    });
  });
}
