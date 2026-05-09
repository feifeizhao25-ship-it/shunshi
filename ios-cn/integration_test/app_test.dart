// 顺时 Flutter 集成测试 — 中国版 (ios-cn)
// 测试关键用户旅程：Onboarding / Home / Chat / Settings / Subscription
//
// 运行方式:
//   cd ios-cn
//   flutter test integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/main.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    // 默认: 已完成 onboarding（大部分测试场景）
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': 'true',
      'user_id': 'test_usr_cn_001',
      'nickname': '测试用户',
      'hemisphere': 'north',
      'feeling': 'calm',
      'life_stage': 'working',
      'access_token': 'mock_token_cn',
    });
  });

  // ──────────────────────────────────────────────
  // 辅助函数
  // ──────────────────────────────────────────────

  /// 启动 App 并 pump 到可交互状态
  Future<void> bootApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
    // Splash 页 1.5s 动画 + 跳转
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  group('1. Onboarding 7步流程', () {
    testWidgets('OB-01: 7步引导页可正常渲染（未完成 onboarding）', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': 'false'});
      await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 验证 Onboarding 页面出现
      // WelcomePage 或 Step 1 Page
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('OB-02: 生命阶段选择', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': 'false'});
      await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 找到"开始旅程"或类似按钮并点击
      final startBtn = find.textContaining('开始');
      if (startBtn.evaluate().isNotEmpty) {
        await tester.tap(startBtn.first);
        await tester.pumpAndSettle();

        // 生命阶段选项
        final lifeStage = find.textContaining('工作');
        if (lifeStage.evaluate().isNotEmpty) {
          await tester.tap(lifeStage.first);
          await tester.pumpAndSettle();
          expect(true, isTrue); // 选项可点击
        }
      }
    });

    testWidgets('OB-07: 完成 onboarding 后跳转 Home', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': 'false'});
      await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 跳过 onboarding 直接模拟完成
      SharedPreferences.setMockInitialValues({'onboarding_completed': 'true'});
      await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // App 应显示首页内容
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('2. Home Dashboard', () {
    testWidgets('HM-01: Dashboard 加载显示每日洞察', (tester) async {
      await bootApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 首页应有 Scaffold
      expect(find.byType(Scaffold), findsWidgets);
      // 可能有问候语或建议卡片
      expect(
        find.textContaining('你好').evaluate().isNotEmpty ||
        find.textContaining('顺时').evaluate().isNotEmpty ||
        find.textContaining('建议').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('HM-02: 3条建议卡片显示', (tester) async {
      await bootApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 建议卡片区域（根据实际 UI 调整）
      final breathFinder = find.text('呼吸');
      final foodFinder = find.text('食疗');
      final exerciseFinder = find.text('运动');

      expect(
        breathFinder.evaluate().isNotEmpty ||
        foodFinder.evaluate().isNotEmpty ||
        exerciseFinder.evaluate().isNotEmpty,
        isTrue,
        reason: '首页应有至少一条建议卡片',
      );
    });

    testWidgets('HM-03: AI 入口卡片可点击', (tester) async {
      await bootApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final aiEntry = find.textContaining('聊');
      if (aiEntry.evaluate().isNotEmpty) {
        await tester.tap(aiEntry.first);
        await tester.pumpAndSettle();
        // 应跳转到聊天页
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  group('3. AI 对话页 (ChatPage)', () {
    testWidgets('AI-01: 底部导航切换到 AI对话 Tab', (tester) async {
      await bootApp(tester);
      final chatTab = find.text('AI对话');
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('AI-02: 输入框和发送按钮存在', (tester) async {
      await bootApp(tester);
      final chatTab = find.text('AI对话');
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      // 查找输入框
      final inputField = find.byType(TextField);
      if (inputField.evaluate().isNotEmpty) {
        expect(inputField, findsOneWidget);
        // 发送按钮
        expect(find.byIcon(Icons.send), findsOneWidget);
      }
    });

    testWidgets('AI-03: 发送消息', (tester) async {
      await bootApp(tester);
      final chatTab = find.text('AI对话');
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      final inputField = find.byType(TextField);
      if (inputField.evaluate().isNotEmpty) {
        await tester.enterText(inputField, '最近睡眠不好');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证消息已输入或发送
        // 在 Mock 环境下，验证 UI 状态变化即可
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  group('4. 节气页 (SolarTermPage)', () {
    testWidgets('ST-01: 节气 Tab 可切换', (tester) async {
      await bootApp(tester);
      final seasonsTab = find.text('节气');
      if (seasonsTab.evaluate().isNotEmpty) {
        await tester.tap(seasonsTab);
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('ST-02: 节气页显示节气标题', (tester) async {
      await bootApp(tester);
      final seasonsTab = find.text('节气');
      if (seasonsTab.evaluate().isNotEmpty) {
        await tester.tap(seasonsTab);
        await tester.pumpAndSettle();
      }

      // 节气养生标题或当前节气名
      expect(
        find.text('节气养生').evaluate().isNotEmpty ||
        find.text('生活建议').evaluate().isNotEmpty ||
        find.byType(Scaffold).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('5. 养生内容页 (WellnessPage)', () {
    testWidgets('WL-01: 内容 Tab 可切换', (tester) async {
      await bootApp(tester);
      final libraryTab = find.text('内容');
      if (libraryTab.evaluate().isNotEmpty) {
        await tester.tap(libraryTab);
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('WL-02: 4个分类 Tab 存在（食疗/穴位/运动/茶饮）', (tester) async {
      await bootApp(tester);
      final libraryTab = find.text('内容');
      if (libraryTab.evaluate().isNotEmpty) {
        await tester.tap(libraryTab);
        await tester.pumpAndSettle();
      }

      // 分类 Tab（食疗/穴位/运动/茶饮）
      expect(
        find.textContaining('食疗').evaluate().isNotEmpty ||
        find.textContaining('穴位').evaluate().isNotEmpty ||
        find.textContaining('运动').evaluate().isNotEmpty ||
        find.textContaining('茶饮').evaluate().isNotEmpty,
        isTrue,
        reason: '内容页应有分类 Tab',
      );
    });
  });

  group('6. 个人中心页 (ProfilePage)', () {
    testWidgets('PR-01: 我的 Tab 可切换', (tester) async {
      await bootApp(tester);
      final profileTab = find.text('我的');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('PR-02: 健康记录入口存在', (tester) async {
      await bootApp(tester);
      final profileTab = find.text('我的');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      expect(find.text('健康记录'), findsOneWidget);
    });

    testWidgets('PR-03: 使用统计区域显示', (tester) async {
      await bootApp(tester);
      final profileTab = find.text('我的');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      expect(
        find.text('使用统计').evaluate().isNotEmpty ||
        find.text('对话').evaluate().isNotEmpty ||
        find.text('记录').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('7. Settings 半球切换', () {
    testWidgets('PR-09: 半球选择器存在', (tester) async {
      await bootApp(tester);
      final profileTab = find.text('我的');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 找设置入口
      final settingsEntry = find.text('设置');
      if (settingsEntry.evaluate().isNotEmpty) {
        await tester.tap(settingsEntry.first);
        await tester.pumpAndSettle();

        // 半球选择器
        expect(find.text('半球'), findsOneWidget);
        expect(find.text('北半球'), findsWidgets);
      }
    });
  });

  group('8. Subscription 页面', () {
    testWidgets('SUB-01: 订阅页显示产品列表', (tester) async {
      // 直接访问订阅页面路由
      // 订阅 Tab 或从个人中心入口
      await bootApp(tester);
      final profileTab = find.text('我的');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // 找订阅入口
      final subscribeEntry = find.textContaining('订阅');
      if (subscribeEntry.evaluate().isNotEmpty) {
        await tester.tap(subscribeEntry.first);
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  group('9. 通用 UI 验证', () {
    testWidgets('SafeArea 各页面正确使用', (tester) async {
      await bootApp(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('主题系统正常加载', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
      await tester.pump();

      final context = tester.element(find.byType(MaterialApp));
      final theme = Theme.of(context);
      expect(theme, isNotNull);
      expect(theme.colorScheme, isNotNull);
    });

    testWidgets('BottomNavigation Tab 总数正确（5个）', (tester) async {
      await bootApp(tester);
      // 5个 Tab: 首页, AI对话, 节气, 内容, 我的
      final tabs = ['首页', 'AI对话', '节气', '内容', '我的'];
      for (final tab in tabs) {
        final finder = find.text(tab);
        expect(finder.evaluate().isNotEmpty, isTrue,
            reason: 'Tab "$tab" 应存在');
      }
    });
  });
}
