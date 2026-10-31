import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/settings/culture_settings_page.dart';

final cjk = RegExp(r'[\u3400-\u9fff]');

Widget host({required Future<Map<String, dynamic>> Function() load, required Future<Map<String, dynamic>> Function(Map<String, dynamic>) save}) =>
    MaterialApp(home: CultureSettingsPage(load: load, save: save));

Map<String, dynamic> empty() => {'diet': [], 'observances': [], 'units': null, 'hemisphere': null};

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(800, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

String allText(WidgetTester t) => t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? w.textSpan?.toPlainText() ?? '').join(' ');

void main() {
  testWidgets('starts empty, nothing is saved until the user chooses and saves; body uses fixed keys', (t) async {
    tall(t);
    Map<String, dynamic>? sent;
    await t.pumpWidget(host(load: () async => empty(), save: (b) async {
      sent = b;
      return b;
    }));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('culture-note')), findsOneWidget);
    expect(tester(t, 'culture-save'), isNull, reason: 'save is disabled until something changes');
    await t.tap(find.byKey(const Key('culture-diet-halal')));
    await t.tap(find.byKey(const Key('culture-observance-ramadan_fasting')));
    await t.tap(find.text('Imperial'));
    await t.tap(find.text('Southern'));
    await t.pump();
    await t.tap(find.byKey(const Key('culture-save')));
    await t.pumpAndSettle();
    expect(sent, {'diet': ['halal'], 'observances': ['ramadan_fasting'], 'units': 'imperial', 'hemisphere': 'south'});
    expect(find.text('Preferences saved'), findsOneWidget);
  });

  testWidgets('loads saved values and clear-all asks first, then sends empty lists and nulls', (t) async {
    tall(t);
    Map<String, dynamic>? sent;
    await t.pumpWidget(host(
      load: () async => {'diet': ['vegan'], 'observances': [], 'units': 'metric', 'hemisphere': 'north'},
      save: (b) async {
        sent = b;
        return empty();
      },
    ));
    await t.pumpAndSettle();
    expect(t.widget<FilterChip>(find.byKey(const Key('culture-diet-vegan'))).selected, isTrue);
    await t.tap(find.byKey(const Key('culture-clear')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('culture-clear-cancel')));
    await t.pumpAndSettle();
    expect(sent, isNull);
    await t.tap(find.byKey(const Key('culture-clear')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('culture-clear-confirm')));
    await t.pumpAndSettle();
    expect(sent, {'diet': [], 'observances': [], 'units': null, 'hemisphere': null});
    expect(t.widget<FilterChip>(find.byKey(const Key('culture-diet-vegan'))).selected, isFalse);
  });

  testWidgets('unknown values from the server are ignored, load error retries, save error keeps the choices', (t) async {
    tall(t);
    var calls = 0;
    var fail = true;
    await t.pumpWidget(host(
      load: () async {
        calls++;
        if (calls == 1) throw Exception('x');
        return {'diet': ['carnivore', 'halal'], 'observances': ['x'], 'units': 'stone', 'hemisphere': 'east'};
      },
      save: (b) async {
        if (fail) throw Exception('x');
        return b;
      },
    ));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('culture-error')), findsOneWidget);
    await t.tap(find.byKey(const Key('culture-retry')));
    await t.pumpAndSettle();
    expect(t.widget<FilterChip>(find.byKey(const Key('culture-diet-halal'))).selected, isTrue);
    await t.tap(find.byKey(const Key('culture-diet-kosher')));
    await t.pump();
    await t.tap(find.byKey(const Key('culture-save')));
    await t.pumpAndSettle();
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    expect(t.widget<FilterChip>(find.byKey(const Key('culture-diet-kosher'))).selected, isTrue, reason: 'choices survive a failed save');
  });

  testWidgets('English only', (t) async {
    tall(t);
    await t.pumpWidget(host(load: () async => empty(), save: (b) async => b));
    await t.pumpAndSettle();
    expect(cjk.hasMatch(allText(t)), isFalse);
  });
}

VoidCallback? tester(WidgetTester t, String key) => t.widget<FilledButton>(find.byKey(Key(key))).onPressed;
