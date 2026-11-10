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
    expect(find.text('Body Types'), findsNothing);
    expect(find.text('Pressure Points'), findsNothing);
    expect(find.text('Seasonal Recipes'), findsOneWidget);
    expect(find.text('Herbal Teas'), findsOneWidget);
    expect(find.text('Movement'), findsOneWidget);
    expect(find.text('Sleep Sounds'), findsOneWidget);
  });

  testWidgets('the flag shows Body Types and Pressure Points without deleting their sheets', (tester) async {
    await _pump(tester, const LibraryPage(showBodyTypesAndPressurePoints: true));
    expect(find.text('Body Types'), findsOneWidget);
    expect(find.text('Pressure Points'), findsOneWidget);

    await tester.tap(find.text('Body Types'));
    await tester.pumpAndSettle();
    expect(find.text('Vital'), findsOneWidget);

    Navigator.of(tester.element(find.text('Vital'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pressure Points'));
    await tester.pumpAndSettle();
    expect(find.text('Third Eye Point (Yintang)'), findsOneWidget);
  });
}
