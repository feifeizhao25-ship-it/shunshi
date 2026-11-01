import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/illustrated_widgets.dart';

/// R3 matrix (200% text scale): the page hero banner grows with its text; before, a fixed height pushed the title out of
/// the banner and threw a RenderFlex overflow.
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('hero banner at ${(scale * 100).round()}% text does not overflow', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(600, 1000);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: c!),
        home: const Scaffold(body: SingleChildScrollView(child: PageHeroBanner(asset: 'assets/none.webp', title: '日积月累', subtitle: '记录您的每一次健康修行，一步一个脚印'))),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
