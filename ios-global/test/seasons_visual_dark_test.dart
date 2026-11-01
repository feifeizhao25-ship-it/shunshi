import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/seasons_visual.dart';
import 'package:seasons/design_system/app_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  testWidgets('N05: stat chip text/icon are readable on the dark card (>= 4.5:1)', (t) async {
    late Color card;
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: Builder(builder: (c) {
          card = AppColors.card(c);
          return const Row(children: [SgStatChip(icon: Icons.favorite_border, label: 'Saved', value: '7')]);
        }),
      ),
    ));
    final value = t.widget<Text>(find.text('7'));
    final label = t.widget<Text>(find.text('Saved'));
    final icon = t.widget<Icon>(find.byIcon(Icons.favorite_border));
    expect(_contrast(value.style!.color!, card), greaterThanOrEqualTo(4.5));
    expect(_contrast(label.style!.color!, card), greaterThanOrEqualTo(4.5));
    expect(_contrast(icon.color!, card), greaterThanOrEqualTo(4.5));
  });

  testWidgets('N05: empty state text is readable on the dark page', (t) async {
    late Color bg;
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: Builder(builder: (c) { bg = AppColors.background(c); return const SgEmptyState(asset: 'assets/none.png', title: 'Nothing yet', message: 'Write a diary entry'); })),
    ));
    final title = t.widget<Text>(find.text('Nothing yet'));
    final msg = t.widget<Text>(find.text('Write a diary entry'));
    expect(_contrast(title.style!.color!, bg), greaterThanOrEqualTo(4.5));
    expect(_contrast(msg.style!.color!, bg), greaterThanOrEqualTo(4.5));
  });
}
