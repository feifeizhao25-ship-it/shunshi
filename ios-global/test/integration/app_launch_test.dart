import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/main.dart' as app;

void main() {
  group('App Launch', () {
    testWidgets('app renders without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should find at least a Scaffold or MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
