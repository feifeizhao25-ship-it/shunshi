import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/home/ultimate_home_page.dart';

/// The season chip's dot and label share a [Row], so [Flexible] is valid and
/// the label's parent data is [FlexParentData]. Moving that [Flexible] up into
/// the [Container] is the parent-data error that turns the Today page grey on
/// profile/web (`BoxParentData is not a subtype of FlexParentData`).
void main() {
  testWidgets('season chip keeps flex parent data on the row, not the container', (tester) async {
    const label = '霜降 · 深秋，把作息放慢一点，晚上早点休息，不要把入睡时间一直往后拖';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('9:00 - 11:00'),
                Text('巳时 · 脾经当令'),
                SolarTermPill(label: label, color: Color(0xFF74593C)),
              ],
            ),
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('9:00 - 11:00'), findsOneWidget);
    expect(find.text('巳时 · 脾经当令'), findsOneWidget);
    expect(find.text(label), findsOneWidget);
    expect(find.descendant(of: find.byType(SolarTermPill), matching: find.byType(Flexible)), findsOneWidget);

    final text = tester.widget<Text>(find.descendant(of: find.byType(SolarTermPill), matching: find.byType(Text)));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);

    final paragraph = tester.renderObject<RenderBox>(
      find.descendant(of: find.byType(SolarTermPill), matching: find.byType(RichText)),
    );
    expect(paragraph.hasSize, isTrue);
    expect(paragraph.parentData, isA<FlexParentData>());
    expect(paragraph.parent, isA<RenderFlex>());

    final pill = tester.renderObject<RenderBox>(find.byType(SolarTermPill));
    expect(pill.size.width, lessThanOrEqualTo(160));
    expect(pill.size.height, greaterThan(0));
  });
}
