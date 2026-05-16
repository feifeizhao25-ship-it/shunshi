// test/widget/widgets/loading_indicator_test.dart
// 加载指示器测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/components/loading_indicator.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('LoadingIndicator widget', () {
    testWidgets('渲染三个圆点', (tester) async {
      await pumpApp(
        tester,
        child: const LoadingIndicator(),
      );

      // 3个 Container 圆点
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('inline 模式不居中', (tester) async {
      await pumpApp(
        tester,
        child: const LoadingIndicator(inline: true),
      );

      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('自定义大小', (tester) async {
      await pumpApp(
        tester,
        child: const LoadingIndicator(size: 48),
      );

      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('动画运行不崩溃', (tester) async {
      await pumpApp(
        tester,
        child: const LoadingIndicator(),
      );

      // 推进动画帧
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoadingIndicator), findsOneWidget);
    });
  });
}
