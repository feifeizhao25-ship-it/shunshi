// test/widget/widgets/empty_state_test.dart
// 空状态组件测试 — 扩充版

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/components/empty_state.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('EmptyState widget', () {
    testWidgets('显示消息文本', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState(message: '暂无内容'),
      );

      expect(find.text('暂无内容'), findsOneWidget);
    });

    testWidgets('显示图标', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState(
          message: '暂无内容',
          icon: Icons.inbox_outlined,
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('无图标时不显示图标', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState(message: '暂无内容'),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('显示副标题', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState(
          message: '暂无内容',
          subtitle: '下拉刷新试试',
        ),
      );

      expect(find.text('下拉刷新试试'), findsOneWidget);
    });

    testWidgets('无副标题时不显示', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState(message: '暂无内容'),
      );

      // 只有一个 Text widget（message）
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('带操作按钮时显示', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        child: EmptyState(
          message: '暂无内容',
          actionText: '重试',
          onAction: () => tapped = true,
        ),
      );

      expect(find.text('重试'), findsOneWidget);
      await tester.tap(find.text('重试'));
      expect(tapped, isTrue);
    });

    testWidgets('无操作按钮时不显示', (tester) async {
      await pumpApp(
        tester,
        child: const EmptyState(message: '暂无内容'),
      );

      expect(find.text('重试'), findsNothing);
    });
  });
}
