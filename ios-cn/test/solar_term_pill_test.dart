import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/home/ultimate_home_page.dart';

/// The Today hero puts this chip in a [Column], not a [Row]. A [Flexible]
/// directly inside the chip's [Container] is what profile/web reports as
/// `BoxParentData is not a subtype of FlexParentData` while painting the page
/// grey. Debug builds swallow that mismatch, which is why the iOS debug
/// screenshot still showed the title.
void main() {
  testWidgets('season chip lays out under a column without flex parent data', (tester) async {
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
    expect(find.descendant(of: find.byType(SolarTermPill), matching: find.byType(Flexible)), findsNothing);
    expect(find.descendant(of: find.byType(SolarTermPill), matching: find.byType(Expanded)), findsNothing);

    final text = tester.widget<Text>(find.descendant(of: find.byType(SolarTermPill), matching: find.byType(Text)));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);

    final paragraph = tester.renderObject<RenderBox>(
      find.descendant(of: find.byType(SolarTermPill), matching: find.byType(RichText)),
    );
    expect(paragraph.hasSize, isTrue);
    expect(paragraph.parentData, isA<BoxParentData>());
    expect(paragraph.parentData, isNot(isA<FlexParentData>()));

    final pill = tester.renderObject<RenderBox>(find.byType(SolarTermPill));
    expect(pill.size.width, lessThanOrEqualTo(160));
    expect(pill.size.height, greaterThan(0));
  });
}
