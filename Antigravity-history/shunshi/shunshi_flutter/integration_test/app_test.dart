import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shunshi_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整核心链路集成测试：启动、导航切换、发送消息', (WidgetTester tester) async {
    // 启动应用
    app.main();
    
    // 等待初始化及第一帧渲染完成（包括各种异步加载）
    await tester.pumpAndSettle(const Duration(seconds: 5));
    
    // 验证底部导航栏是否成功加载
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('咨询'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // --- 在首页等待一下 ---
    await Future.delayed(const Duration(seconds: 1));
    
    // --- 切换到咨询（Chat）页面 ---
    await tester.tap(find.text('咨询'));
    await tester.pumpAndSettle();
    
    // 验证聊天页加载成功
    expect(find.text('顺时咨询'), findsOneWidget);
    
    // 查找输入框
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    
    // 输入文字测试
    await tester.enterText(textField, '我最近睡眠不好，应该吃点什么？');
    await Future.delayed(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    
    // 点击发送按钮 (Icons.send_rounded)
    final sendButton = find.byIcon(Icons.send_rounded);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // 验证消息气泡出现在界面上
    expect(find.text('我最近睡眠不好，应该吃点什么？'), findsOneWidget);
    
    // 等待一下以便观察 (在实际 CI 中不需要，只是为了确保操作平滑)
    await Future.delayed(const Duration(seconds: 2));
    
    // --- 切换到我的 (Profile) 页面 ---
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    
    // 验证个人中心加载成功
    expect(find.text('打卡天数'), findsOneWidget);
    expect(find.text('连续'), findsOneWidget);
    
    // 测试完成
  });
}
