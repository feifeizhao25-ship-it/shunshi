import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/config/app_config.dart';
import 'package:seasons/presentation/pages/library/library_page.dart';

Future<void> _pump(WidgetTester tester, LibraryPage page) async {
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  test('international builds hide the TCM library categories', () {
    expect(AppConfig.showTcmLibraryCategories, isFalse);
  });

  testWidgets('Body Types and Pressure Points are hidden by default and the rest stay', (tester) async {
    await _pump(tester, const LibraryPage());
    expect(find.text('Daily Rhythm'), findsNothing);
    expect(find.text('Calm Touch'), findsNothing);
    expect(find.text('Seasonal Food'), findsOneWidget);
    expect(find.text('Warm Cups'), findsOneWidget);
    expect(find.text('Easy Movement'), findsOneWidget);
    expect(find.text('Light & Sleep'), findsOneWidget);
  });

  testWidgets('the flag shows Daily Rhythm and Calm Touch without deleting their sheets', (tester) async {
    await _pump(tester, const LibraryPage(showBodyTypesAndPressurePoints: true));
    expect(find.text('Daily Rhythm'), findsOneWidget);
    expect(find.text('Calm Touch'), findsOneWidget);

    await tester.tap(find.text('Daily Rhythm'));
    await tester.pumpAndSettle();
    expect(find.text('Vital'), findsOneWidget);

    Navigator.of(tester.element(find.text('Vital'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calm Touch'));
    await tester.pumpAndSettle();
    expect(find.text('Third Eye Point (Yintang)'), findsOneWidget);
  });
}
