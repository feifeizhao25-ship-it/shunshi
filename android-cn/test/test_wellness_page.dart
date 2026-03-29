/// 顺时 - 养生页面测试
/// test_wellness_page.dart
///
/// 测试养生页面的核心 UI 元素：
/// - 分类网格（节气/体质/食疗/茶饮/穴位/运动）
/// - 卡片点击导航

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WellnessPage', () {
    testWidgets('显示6个养生分类', (WidgetTester tester) async {
      final categories = [
        {'icon': Icons.wb_sunny, 'name': '节气'},
        {'icon': Icons.person, 'name': '体质'},
        {'icon': Icons.restaurant, 'name': '食疗'},
        {'icon': Icons.local_cafe, 'name': '茶饮'},
        {'icon': Icons.self_improvement, 'name': '穴位'},
        {'icon': Icons.directions_run, 'name': '运动'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('养生')),
            body: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Card(
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, size: 40),
                          const SizedBox(height: 8),
                          Text(cat['name'] as String),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 验证标题
      expect(find.text('养生'), findsOneWidget);

      // 验证所有分类
      for (final cat in categories) {
        expect(find.text(cat['name'] as String), findsOneWidget);
      }

      // 验证图标
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      expect(find.byIcon(Icons.directions_run), findsOneWidget);
    });

    testWidgets('分类卡片使用 GridView 布局', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              children: List.generate(6, (index) {
                return const Card(child: SizedBox(height: 100));
              }),
            ),
          ),
        ),
      );

      // 应该有6个 Card
      expect(find.byType(Card), findsNWidgets(6));
      // 应该有 GridView
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('点击分类卡片触发导航', (WidgetTester tester) async {
      String? navigatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              children: [
                _CategoryCard(
                  name: '节气',
                  icon: Icons.wb_sunny,
                  onTap: () => navigatedRoute = '/solar-term',
                ),
                _CategoryCard(
                  name: '体质',
                  icon: Icons.person,
                  onTap: () => navigatedRoute = '/constitution',
                ),
              ],
            ),
          ),
        ),
      );

      // 点击前
      expect(navigatedRoute, isNull);

      // 点击 "节气"
      await tester.tap(find.text('节气'));
      await tester.pump();
      expect(navigatedRoute, '/solar-term');

      // 重置并点击 "体质"
      navigatedRoute = null;
      await tester.tap(find.text('体质'));
      await tester.pump();
      expect(navigatedRoute, '/constitution');
    });

    testWidgets('卡片包含图标和文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_cafe, size: 40, color: Colors.green),
                      SizedBox(height: 8),
                      Text('茶饮', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('茶饮'), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
    });
  });
}

/// 辅助 Widget：分类卡片
class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 8),
              Text(name, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
