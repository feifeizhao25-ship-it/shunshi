// test/widget/widgets/soft_card_test.dart
// 柔和卡片测试

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/components/soft_card.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('SoftCard widget', () {
    testWidgets('显示子组件', (tester) async {
      await pumpApp(
        tester,
        child: const SoftCard(
          child: Text('卡片内容'),
        ),
      );

      expect(find.text('卡片内容'), findsOneWidget);
    });

    testWidgets('点击触发回调', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        child: SoftCard(
          onTap: () => tapped = true,
          child: const Text('可点击卡片'),
        ),
      );

      await tester.tap(find.text('可点击卡片'));
      expect(tapped, isTrue);
    });

    testWidgets('无 onTap 时不崩溃', (tester) async {
      await pumpApp(
        tester,
        child: const SoftCard(
          child: Text('静态卡片'),
        ),
      );

      expect(find.text('静态卡片'), findsOneWidget);
    });

    testWidgets('自定义 padding', (tester) async {
      await pumpApp(
        tester,
        child: const SoftCard(
          padding: EdgeInsets.all(24),
          child: SizedBox(width: 50, height: 50),
        ),
      );

      expect(find.byType(SoftCard), findsOneWidget);
    });

    testWidgets('自定义颜色', (tester) async {
      await pumpApp(
        tester,
        child: const SoftCard(
          color: Colors.red,
          child: Text('红色卡片'),
        ),
      );

      expect(find.text('红色卡片'), findsOneWidget);
    });
  });
}
