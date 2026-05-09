# TEST_GUIDE.md - 顺时中国版 测试指南

## 测试金字塔

```
                    集成测试 (integration_test/)
              ── 真实用户场景，完整 App 流程 ──
                    
                    单元测试 (test/)
              ── 独立函数/类/Provider 逻辑 ──
                    
                    Widget 测试 (test/)
              ── 单组件 UI 渲染与交互 ──
```

---

## 测试目录

```
ios-cn/
├── test/                          # 单元 + Widget 测试
│   ├── widget_test.dart           # widget 冒烟测试
│   ├── unit/
│   │   ├── core/
│   │   │   └── date_utils_test.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   └── domain/
│   │       └── providers/
│
├── integration_test/              # Flutter Integration Tests
│   └── app_test.dart              # 全页面 UI + 用户旅程测试
│
└── testing/
    └── qa-testing.md              # QA 测试矩阵（中国版）
```

---

## 单元测试示例

### 工具函数测试

```dart
// test/unit/core/date_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/utils/date_utils.dart';

void main() {
  group('SolarTermUtils', () {
    test('惊蛰期间返回惊蛰', () {
      final result = getSolarTerm(DateTime(2026, 3, 5));
      expect(result.name, '惊蛰');
    });

    test('春分期间返回春分', () {
      final result = getSolarTerm(DateTime(2026, 3, 20));
      expect(result.name, '春分');
    });

    test('超出24节气范围返回null', () {
      final result = getSolarTerm(DateTime(2026, 1, 1));
      expect(result, isNull);
    });
  });

  group('HemisphereUtils', () {
    test('北半球春季对应南半球秋季', () {
      expect(
        getHemisphereSeason('spring', 'south'),
        'autumn',
      );
    });

    test('北半球夏季对应南半球冬季', () {
      expect(
        getHemisphereSeason('summer', 'south'),
        'winter',
      );
    });
  });
}
```

### Repository Mock 测试

```dart
// test/unit/data/user_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shunshi/data/datasources/local/local_storage.dart';
import 'package:shunshi/data/datasources/remote/api_client.dart';
import 'package:shunshi/data/repositories/user_repository.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late UserRepository repository;
  late MockApiClient mockApi;
  late MockLocalStorage mockLocal;

  setUp(() {
    mockApi = MockApiClient();
    mockLocal = MockLocalStorage();
    repository = UserRepository(mockApi, mockLocal);
  });

  group('getProfile', () {
    test('返回缓存的用户数据', () async {
      when(() => mockLocal.getString('user_id'))
          .thenReturn('usr_123');
      when(() => mockLocal.getString('nickname'))
          .thenReturn('张三');

      final profile = await repository.getProfile();

      expect(profile.userId, 'usr_123');
      expect(profile.nickname, '张三');
      verifyNever(() => mockApi.get(any())); // 不调用 API
    });
  });
}
```

---

## Widget 测试

### 按钮组件测试

```dart
// test/widget_test.dart 中的示例
testWidgets('GradientButton renders and is tappable', (tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GradientButton(
          onPressed: () => tapped = true,
          child: const Text('下一步'),
        ),
      ),
    ),
  );

  expect(find.text('下一步'), findsOneWidget);
  await tester.tap(find.text('下一步'));
  expect(tapped, isTrue);
});
```

---

## Integration Test（用户旅程测试）

### 运行方式

```bash
cd ios-cn
flutter test integration_test/app_test.dart
```

### 关键测试用例

#### Onboarding 7步流程

```dart
// integration_test/app_test.dart
testWidgets('OB-01: 90秒内完成全部7步', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
  await tester.pump();

  // Step 1: 欢迎页
  expect(find.text('欢迎来到顺时'), findsOneWidget);
  await tester.tap(find.text('开始旅程'));
  await tester.pumpAndSettle();

  // Step 2: 生命阶段
  expect(find.text('你现在处于'), findsOneWidget);
  await tester.tap(find.text('工作压力期'));
  await tester.pumpAndSettle();

  // Step 3: 感受选择
  await tester.tap(find.text('平静'));
  await tester.pumpAndSettle();

  // Step 4: 帮助目标
  await tester.tap(find.text('改善睡眠'));
  await tester.pumpAndSettle();

  // Step 5: 支持时间
  await tester.tap(find.text('晚上'));
  await tester.pumpAndSettle();

  // Step 6: 体质
  await tester.tap(find.text('气虚质'));
  await tester.pumpAndSettle();

  // Step 7: 风格偏好
  await tester.tap(find.text('温和舒适'));
  await tester.pumpAndSettle();

  // 完成 → Home
  await tester.pumpAndSettle(const Duration(seconds: 3));
  expect(find.text('顺时'), findsWidgets);
});
```

#### Home Dashboard 加载

```dart
testWidgets('HM-01: Dashboard 显示每日洞察', (tester) async {
  SharedPreferences.setMockInitialValues({'onboarding_completed': 'true'});
  await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();

  // Dashboard 应显示
  expect(find.byType(HomePage), findsOneWidget);
  // 建议卡片
  expect(find.text('呼吸'), findsWidgets);
  expect(find.text('食疗'), findsWidgets);
});
```

#### AI Chat 对话

```dart
testWidgets('AI-01: 发送消息获取 AI 回复', (tester) async {
  SharedPreferences.setMockInitialValues({'onboarding_completed': 'true'});
  await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();

  // 切换到 Chat Tab
  final chatTab = find.text('AI对话');
  if (chatTab.evaluate().isNotEmpty) {
    await tester.tap(chatTab);
    await tester.pumpAndSettle();

    // 输入消息
    await tester.enterText(find.byType(TextField), '最近睡眠不好');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 验证回复出现
    expect(find.byType(ChatBubble), findsWidgets);
  }
});
```

#### Settings 半球切换

```dart
testWidgets('PR-09: 半球选择器存在且可切换', (tester) async {
  SharedPreferences.setMockInitialValues({'onboarding_completed': 'true'});
  await tester.pumpWidget(const ProviderScope(child: ShunshiApp()));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();

  // 切换到 Profile Tab
  final profileTab = find.text('我的');
  if (profileTab.evaluate().isNotEmpty) {
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    // 找到设置入口
    final settingsEntry = find.text('设置');
    if (settingsEntry.evaluate().isNotEmpty) {
      await tester.tap(settingsEntry);
      await tester.pumpAndSettle();

      // 半球选择器
      expect(find.text('半球'), findsOneWidget);
      expect(find.text('北半球'), findsOneWidget);
    }
  }
});
```

---

## 测试辅助函数

```dart
// integration_test/app_test.dart 顶部

/// 跳过 Splash，直接导航到目标页面
Future<void> navigateTo(WidgetTester tester, String path) async {
  await tester.pumpWidget(
    ProviderScope(
      child: ShunshiApp(),
    ),
  );
  // Splash 跳转 /onboarding 或 /home
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// 等待 API 响应（Mock 环境下直接 pump）
Future<void> pumpForApi() async {
  await Future.delayed(const Duration(milliseconds: 500));
}
```

---

## Mock 数据

Integration test 使用 `SharedPreferences.setMockInitialValues` 模拟本地存储：

```dart
setUp(() {
  SharedPreferences.setMockInitialValues({
    'onboarding_completed': 'true',
    'user_id': 'test_usr_001',
    'nickname': '测试用户',
    'hemisphere': 'north',
    'access_token': 'mock_token',
  });
});
```

---

## CI/CD 测试门禁

| 测试类型 | 通过率要求 | 超时时间 |
|----------|-----------|---------|
| 单元测试 | ≥ 80% | 60s |
| Widget 测试 | ≥ 90% | 60s |
| Integration 测试 | ≥ 80% | 300s |

---

## 测试矩阵（中国版）

完整测试矩阵见 `testing/qa-testing.md`，包含：
- **OB**: Onboarding 7步测试
- **HM**: Home Dashboard 测试
- **AI**: AI 对话测试
- **ST**: SolarTerm 节气测试
- **WL**: Wellness 内容库测试
- **RF**: Reflection 记录测试
- **SUB**: Subscription 订阅测试
- **PR**: Settings/隐私测试
