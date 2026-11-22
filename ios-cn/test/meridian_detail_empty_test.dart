import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/meridian/meridian_detail_page.dart';

void main() {
  testWidgets('不带经络 id 打开时显示说明和入口，不是两个空标题', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MeridianDetailPage(meridianId: '')));
    await tester.pump();
    expect(find.text('还没有选具体的经络'), findsOneWidget);
    expect(find.text('去看穴位按揉列表'), findsOneWidget);
    expect(find.text('经络概述'), findsNothing);
    expect(find.text('按揉步骤'), findsNothing);
  });
}
