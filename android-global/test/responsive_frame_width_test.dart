import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/responsive_frame.dart';

void main() {
  testWidgets('N06: 1440x900 keeps a <= 720 dp reading column, phones are untouched', (t) async {
    double? w;
    Widget app() => MaterialApp(home: ResponsiveFrame(child: Builder(builder: (c) { w = MediaQuery.of(c).size.width; return const SizedBox.expand(); })));
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1440, 900);
    await t.pumpWidget(app());
    expect(w, 720);
    t.view.physicalSize = const Size(390, 844);
    await t.pumpWidget(app());
    expect(w, 390);
    addTearDown(t.view.reset);
  });
}
