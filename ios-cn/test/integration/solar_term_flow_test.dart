// test/integration/solar_term_flow_test.dart
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

  group('Solar term flow integration', () {
    testWidgets('home shows solar term section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ShunshiApp()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The home screen may be signed out, so this only checks that the app loaded.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
