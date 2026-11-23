import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/chat/chat_widgets.dart';

Widget _chips(double scale) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(360, 780), textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: Align(alignment: Alignment.topCenter, child: QuickQuestionChips(onTap: (_) {}))),
      ),
    );

void main() {
  testWidgets('系统字号 1.3 时快捷问题整行显示，不被截成半行（问题 45）', (tester) async {
    await tester.pumpWidget(_chips(1.3));
    final row = tester.getRect(find.byType(QuickQuestionChips));
    final text = tester.getRect(find.text('今天吃什么好'));
    expect(text.top, greaterThanOrEqualTo(row.top));
    expect(text.bottom, lessThanOrEqualTo(row.bottom));
    expect(row.height - text.height, greaterThanOrEqualTo(16), reason: '上下各留 8 的内边距');
  });

  test('字号 1.0 时高度保持原来的 34', () {
    expect(QuickQuestionChips.rowHeight(TextScaler.noScaling), 34);
    expect(QuickQuestionChips.rowHeight(const TextScaler.linear(1.3)), greaterThan(34));
  });

  test('小屏或大字、已经开始聊天时收起快捷问题（问题 17）', () {
    const small = Size(360, 640);
    const tall = Size(390, 844);
    expect(QuickQuestionChips.shouldShow(userHasSpoken: false, screen: small, textScale: 1.3), isTrue);
    expect(QuickQuestionChips.shouldShow(userHasSpoken: true, screen: small, textScale: 1.0), isFalse);
    expect(QuickQuestionChips.shouldShow(userHasSpoken: true, screen: tall, textScale: 1.3), isFalse);
    expect(QuickQuestionChips.shouldShow(userHasSpoken: true, screen: tall, textScale: 1.0), isTrue);
  });
}
