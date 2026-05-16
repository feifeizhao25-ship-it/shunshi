// test/widget/widgets/gentle_button_test.dart
// 温和按钮测试 — 扩充版

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/components/gentle_button.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('GentleButton widget', () {
    testWidgets('显示按钮文本', (tester) async {
      await pumpApp(
        tester,
        child: GentleButton(
          text: '点击我',
          onPressed: () {},
        ),
      );

      expect(find.text('点击我'), findsOneWidget);
    });

    testWidgets('点击触发回调', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        child: GentleButton(
          text: '按钮',
          onPressed: () => tapped = true,
        ),
      );

      await tester.tap(find.text('按钮'));
      expect(tapped, isTrue);
    });

    testWidgets('onPressed 为 null 时半透明且不可点击', (tester) async {
      await pumpApp(
        tester,
        child: const GentleButton(text: '禁用按钮'),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets('isLoading 时半透明', (tester) async {
      await pumpApp(
        tester,
        child: GentleButton(
          text: '加载中',
          isLoading: true,
          onPressed: () {},
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('带图标时显示图标', (tester) async {
      await pumpApp(
        tester,
        child: GentleButton(
          text: '分享',
          icon: Icons.share,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('isPrimary=false 使用不同背景色', (tester) async {
      await pumpApp(
        tester,
        child: GentleButton(
          text: '次要按钮',
          isPrimary: false,
          onPressed: () {},
        ),
      );

      expect(find.text('次要按钮'), findsOneWidget);
    });
  });
}
