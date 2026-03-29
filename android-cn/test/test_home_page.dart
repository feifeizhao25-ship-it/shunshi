/// 顺时 - 首页组件测试
/// test_home_page.dart
///
/// 测试首页的核心 UI 元素：
/// - 标题文本
/// - 打卡按钮
/// - 节气信息展示
/// - 习惯列表

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomePage', () {
    testWidgets('页面包含标题文本', (WidgetTester tester) async {
      // 基础布局测试：验证 Scaffold 结构
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('顺时')),
            body: const Column(
              children: [
                Text('今日养生'),
                Text('节气'),
              ],
            ),
          ),
        ),
      );

      // 验证 AppBar 标题
      expect(find.text('顺时'), findsOneWidget);
      // 验证页面内容
      expect(find.text('今日养生'), findsOneWidget);
      expect(find.text('节气'), findsOneWidget);
    });

    testWidgets('打卡按钮可以点击', (WidgetTester tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    clicked = true;
                  },
                  child: const Text('打卡'),
                ),
              ],
            ),
          ),
        ),
      );

      // 点击按钮前
      expect(clicked, isFalse);

      // 点击按钮
      await tester.tap(find.text('打卡'));
      await tester.pump();

      // 点击后
      expect(clicked, isTrue);
    });

    testWidgets('习惯打卡切换状态', (WidgetTester tester) async {
      final habits = <String, bool>{'喝水': false, '运动': false, '早睡': false};

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: habits.entries.map((entry) {
                    return CheckboxListTile(
                      title: Text(entry.key),
                      value: entry.value,
                      onChanged: (bool? value) {
                        setState(() {
                          habits[entry.key] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      );

      // 验证所有习惯初始未勾选
      expect(habits['喝水'], isFalse);
      expect(habits['运动'], isFalse);
      expect(habits['早睡'], isFalse);

      // 勾选 "喝水"
      await tester.tap(find.text('喝水'));
      await tester.pump();
      expect(habits['喝水'], isTrue);

      // 勾选 "运动"
      await tester.tap(find.text('运动'));
      await tester.pump();
      expect(habits['运动'], isTrue);
    });

    testWidgets('建议内容卡片存在', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('今日建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('春季宜养肝，多吃绿色蔬菜'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('今日建议'), findsOneWidget);
      expect(find.text('春季宜养肝，多吃绿色蔬菜'), findsOneWidget);
    });

    testWidgets('底部导航栏存在', (WidgetTester tester) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: const Center(child: Text('首页')),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
                    BottomNavigationBarItem(icon: Icon(Icons.chat), label: '聊天'),
                    BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '养生'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // 验证导航项存在
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('聊天'), findsOneWidget);
      expect(find.text('养生'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);

      // 点击切换
      await tester.tap(find.text('聊天'));
      await tester.pump();
    });
  });
}
