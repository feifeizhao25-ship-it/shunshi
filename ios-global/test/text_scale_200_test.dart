import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/seasons_visual.dart';

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
        home: const Scaffold(body: SingleChildScrollView(child: SgHeroBanner(asset: 'assets/none.webp', title: 'Your wellness journey', subtitle: 'Badges unlock as you chat, journal and check in.'))),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
