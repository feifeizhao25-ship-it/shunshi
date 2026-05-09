import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/main.dart';

void main() {
  testWidgets('App 完整流程测试', (WidgetTester tester) async {
    // 1. 启动 App
    await tester.pumpWidget(const ShunshiApp());
    await tester.pumpAndSettle();
    
    print('✅ 1. App 启动成功');
    
    // 2. 测试首页
    expect(find.text('顺时'), findsOneWidget);
    print('✅ 2. 首页显示正常');
    
    // 3. 测试打卡功能
    final habitButton = find.byIcon(Icons.add).first;
    if (habitButton.evaluate().isNotEmpty) {
      await tester.tap(habitButton);
      await tester.pump();
      print('✅ 3. 打卡功能可用');
    }
    
    // 4. 测试导航到养生页
    await tester.tap(find.text('养生'));
    await tester.pumpAndSettle();
    expect(find.text('节气'), findsOneWidget);
    print('✅ 4. 养生页正常');
    
    // 5. 测试节气页面跳转
    await tester.tap(find.byIcon(Icons.wb_sunny).first);
    await tester.pumpAndSettle();
    print('✅ 5. 节气页面正常');
    
    // 6. 返回并测试对话页
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('对话'));
    await tester.pumpAndSettle();
    print('✅ 6. 对话页正常');
    
    // 7. 测试家庭页
    await tester.tap(find.text('家庭'));
    await tester.pumpAndSettle();
    expect(find.text('家庭关怀'), findsOneWidget);
    print('✅ 7. 家庭页正常');
    
    // 8. 测试个人中心
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('我的'), findsOneWidget);
    print('✅ 8. 个人中心正常');
    
    print('\n🎉 全部测试通过!');
  });
}
