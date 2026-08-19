# 顺时 Flutter 双端迁移架构文档（Part 2: E~H）

---

## E. 关键页面与组件清单

### E1. 聊天页（ChatPage）

```
ChatPage
├── AppBar（会话标题 + 安全状态指示灯）
├── MessageList（ListView.builder）
│   ├── MessageBubble（用户/AI 气泡）
│   │   ├── TextContent（Markdown 渲染）
│   │   ├── ContentCardWidget（穴位/食谱/运动卡片列表）
│   │   │   ├── AcupointCard（穴位名 + 图 + 位置 + 按法）
│   │   │   ├── RecipeCard（食谱名 + 图 + 材料 + 禁忌⚠️）
│   │   │   └── MovementCard（运动名 + 视频缩略图 + 时长）
│   │   └── FollowUpChips（快捷跟进问题）
│   ├── SystemNoticeCard（SafeMode 触发时显示）
│   │   ├── 图标：🛡️
│   │   ├── 文案："当前已进入安全模式..."
│   │   ├── 心理援助热线按钮
│   │   └── ❌ 不显示任何促销/付费引导
│   └── ShimmerLoading（AI 思考中骨架屏）
├── SuggestionBar（横滑建议问题条）
└── InputBar
    ├── TextField
    └── SendButton（disabled 状态管理）
```

**关键实现**：
```dart
// lib/presentation/pages/chat/chat_page.dart

class ChatPage extends ConsumerStatefulWidget { ... }

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final safetyFlag = ref.watch(currentSafetyFlagProvider);
    final isSafeMode = safetyFlag == SafetyFlag.red;

    return Scaffold(
      appBar: _buildAppBar(isSafeMode),
      body: Column(
        children: [
          if (isSafeMode) const SafeModeBanner(),  // 顶部安全模式横幅
          Expanded(
            child: messages.when(
              data: (msgs) => _MessageList(messages: msgs),
              loading: () => const ShimmerLoading(),
              error: (e, _) => ErrorFallbackWidget(
                message: '消息加载失败',
                onRetry: () => ref.invalidate(chatMessagesProvider),
              ),
            ),
          ),
          const SuggestionBar(),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
```

**Schema 渲染 & 降级**：
```dart
// lib/core/utils/json_utils.dart

class AIResponseParser {
  static AIResponse parse(Map<String, dynamic> json) {
    try {
      return AIResponse.fromJson(json);  // 严格 Schema 解析
    } catch (e) {
      Logger.warn('AI Response Schema parse failed', error: e);
      // 降级：取 text 字段或整个 rawText
      final rawText = json['text'] as String? ?? json.toString();
      return AIResponse.fallback(rawText);
    }
  }
}
```

### E2. 今日计划页（TodayPlanSection — 嵌入 Home）

```
TodayPlanSection
├── PlanHeader（日期 + 节气名 + 问候语）
├── PlanStepList（折叠/展开）
│   ├── PlanStepTile × N
│   │   ├── 时间标签（07:00）
│   │   ├── 标题 + 描述
│   │   ├── 维度图标（🍵饮食 / 🧘运动 / 😌情志 / 🌿穴位）
│   │   └── 完成勾选（可选）
│   └── "展开全部" / "收起" 按钮
├── PlanFailureFallback（生成失败时降级）
│   └── 静态文案："今日计划生成中，先看看节气养生建议吧"
└── PlanActions（可选）
    ├── 保存按钮
    └── 分享按钮（share_plus 插件）
```

**设计约束**：
- **一屏读完**：默认折叠模式展示最多 4 步，超出显示"展开"
- **失败降级**：AI 超时 5s 后显示本地 fallback 内容
- **缓存策略**：每日首次生成后缓存到本地，当日内不重复请求

```dart
// lib/presentation/providers/home_providers.dart

final dailyPlanProvider = FutureProvider.autoDispose<DailyPlan>((ref) async {
  final isPremium = ref.watch(isPremiumProvider);
  final useCase = ref.watch(generateDailyPlanUseCaseProvider);

  // 先查本地缓存
  final cached = await ref.watch(localStorageProvider).getDailyPlan(today);
  if (cached != null) return cached;

  // 请求 AI Router
  return useCase.execute(isPremium: isPremium).timeout(
    const Duration(seconds: 5),
    onTimeout: () => DailyPlan.fallback(), // 降级
  );
});
```

### E3. 节气页（SolarTermPage）

```
SolarTermPage
├── SolarTermHeader
│   ├── 节气名（大字）+ 英文 + 拼音
│   ├── 三候指示器（当前候高亮）
│   ├── 节气诗词卡片
│   └── 养生原则摘要
├── SolarTermJourney（7天行动游程）
│   ├── DayCard × 7
│   │   ├── Day N 标签
│   │   ├── 行动标题
│   │   ├── 行动描述
│   │   └── 完成状态
│   └── 水平滚动 / PageView
├── WellnessAdviceSection
│   ├── 饮食宜忌
│   ├── 起居建议
│   ├── 运动建议
│   └── 穴位推荐
└── CustomsSection（民俗 + 养生故事）
```

### E4. 内容库（ContentLibraryPage）

```
ContentLibraryPage
├── SearchBar（搜索框 + 语音输入可选）
├── CategoryTabs（穴位 / 食谱 / 运动）
├── ContentGrid / ContentList
│   ├── ContentTile × N
│   │   ├── 缩略图
│   │   ├── 标题
│   │   ├── 标签（节气/体质）
│   │   └── 收藏图标
│   └── 加载更多（分页）
└── EmptyState / ErrorFallback

ContentDetailPage
├── HeroImage / VideoPlayer
├── 标题 + 描述
├── ContraindicationBanner（⚠️ 禁忌提醒）
├── 详细内容（图文混排）
├── 相关推荐
└── 收藏/分享操作栏
```

### E5. 我的 / 设置

```
ProfilePage
├── UserInfoCard（头像/昵称/体质/会员状态）
├── StatsSection（打卡天数/收藏数/连续天数）
├── QuickActions（体质测试/调理方案/收藏夹）
└── SettingsEntry

SettingsPage
├── CareSettingsSection
│   ├── Toggle: 早安问候 + 时间选择
│   ├── Toggle: 午间关怀 + 时间选择
│   ├── Toggle: 晚安叮嘱 + 时间选择
│   ├── Toggle: 天气感应
│   └── Toggle: 情绪共鸣
├── MemorySettingsSection
│   ├── Toggle: 阶段记忆开关 (lifePhaseEnabled)
│   ├── Button: 清空记忆（确认弹窗）
│   └── 说明文案："关闭后，顺时将不再记忆你的阶段偏好"
├── SilentPeriodSection
│   ├── Toggle: 静默时段
│   └── TimePicker: 开始/结束时间
├── NotificationSection
│   └── Toggle: 通知总开关
├── ResponsibilitySection
│   └── 责任边界说明（不医疗/不诊断/不用药）
└── AccountSection
    ├── 退出登录
    └── 注销账号
```

### E6. 订阅页（SubscriptionPage）

```
SubscriptionPage
├── HeroSection
│   ├── 大标题："连续照护，让养生不再间断"
│   ├── 副标题："不是解锁功能，而是持续的陪伴"
│   └── 动画插图
├── BenefitsList
│   ├── ✅ 高级AI顾问（72B深度模型）
│   ├── ✅ 每日个性化计划（深度洞察版）
│   ├── ✅ 阶段记忆（持续了解你的状态变化）
│   ├── ✅ 主动跟进关怀
│   └── ✅ 内容库完整访问
├── PricingCards
│   ├── MonthlyCard（¥XX/月）
│   └── AnnualCard（¥XX/年 — 推荐）
├── PurchaseButton
├── RestoreButton（恢复购买）
└── LegalLinks（隐私政策 / 服务条款 / 自动续费说明）
```

> **关键约束**：订阅页措辞强调**"连续照护"**，不使用"解锁""高级功能"等功能导向用语。

---

## F. 跟进与退让机制

### F1. FollowUpPlan 保存与调度

```dart
// lib/domain/usecases/schedule_follow_up.dart

class ScheduleFollowUp {
  final FollowUpLocalDatasource _local;
  final NotificationService _notification;

  Future<void> execute(FollowUpPlan plan) async {
    // 1. 保存到本地数据库
    await _local.saveFollowUp(plan);

    // 2. 注册本地通知
    await _notification.scheduleNotification(
      id: plan.hashCode,
      title: '顺时关怀',
      body: plan.topic,
      scheduledAt: plan.scheduledAt,
      payload: jsonEncode({'intent': plan.intent, 'topic': plan.topic}),
    );
  }

  Future<void> dismiss(String planId) async {
    await _local.markDismissed(planId);
    await _notification.cancel(planId.hashCode);
  }
}
```

**平台差异处理**：

| 能力 | iOS | Android |
|------|-----|---------|
| 本地通知 | flutter_local_notifications (UNNotification) | flutter_local_notifications (NotificationChannel) |
| 后台调度 | 通知触发即可 | workmanager 插件（精确唤醒） |
| 跟进可忽略 | ✅ 通知操作按钮 "忽略" | ✅ 同左 |

```dart
// 跟进通知带"忽略"操作
await flutterLocalNotificationsPlugin.zonedSchedule(
  id,
  '顺时关怀',
  plan.topic,
  scheduledDate,
  NotificationDetails(
    iOS: DarwinNotificationDetails(
      categoryIdentifier: 'followUp',  // 注册 dismiss action
    ),
    android: AndroidNotificationDetails(
      'follow_up_channel',
      '跟进关怀',
      actions: [AndroidNotificationAction('dismiss', '暂时不需要')],
    ),
  ),
);
```

### F2. PresencePolicy（退让机制）

```dart
// lib/domain/usecases/apply_presence_policy.dart

class ApplyPresencePolicy {
  final PresenceLocalDatasource _local;

  /// 核心规则
  Future<PresenceLevel> evaluate(String userId) async {
    final record = await _local.getPresenceRecord(userId);

    // 规则1: 用户主动开启静默 → 立即生效
    if (record.silentModeActive) return PresenceLevel.hidden;

    // 规则2: 连续3次不回应 → 降频
    if (record.consecutiveIgnores >= 3) return PresenceLevel.reduced;

    // 规则3: 稳定期隐身（CareStatus 连续7天 stable）
    if (record.stableDays >= 7) return PresenceLevel.hidden;

    return PresenceLevel.normal;
  }

  /// 记录用户回应（重置忽略计数）
  Future<void> recordUserResponse(String userId) async {
    await _local.resetIgnoreCount(userId);
    await _local.updateLastResponseTime(userId, DateTime.now());
  }

  /// 记录忽略（跟进通知被忽略 / 消息未读）
  Future<void> recordIgnore(String userId) async {
    await _local.incrementIgnoreCount(userId);
  }
}
```

**退让行为映射**：

| PresenceLevel | 行为 |
|---------------|------|
| `normal` | 正常推送跟进、正常问候 |
| `reduced` | 跟进频率减半、问候简化、不推内容卡 |
| `hidden` | 不主动推送任何内容、用户主动开启才恢复 |

### F3. 异常优先 SafeMode

```dart
// lib/presentation/widgets/system_notice_card.dart

class SystemNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            Text('安全关怀', style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          const Text(
            '听到你这么说，我很担心你。\n'
            '请记住：你并不孤单，有人愿意帮助你。',
          ),
          const SizedBox(height: 16),
          // 心理援助热线
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:400-161-9995')),
            icon: const Icon(Icons.phone),
            label: const Text('24小时心理援助热线'),
          ),
          const SizedBox(height: 8),
          Text(
            '全国：400-161-9995\n北京：010-82951332',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          // ❌ 此处绝不显示任何促销、付费引导、功能推荐
        ],
      ),
    );
  }
}
```

**SafeMode 端上规则**：

```dart
// 在 ChatPage 中
final safetyFlag = ref.watch(currentSafetyFlagProvider);

if (safetyFlag == SafetyFlag.red) {
  // 1. 显示 SystemNoticeCard
  // 2. 隐藏所有促销入口
  // 3. 禁止推内容卡
  // 4. AI 回复只能是克制、非诊断、鼓励现实支持的内容
  // 5. 不记录为"已完成互动"（不影响退让计数）
}
```

---

## G. 测试

### G1. Domain/UseCase 单测

```dart
// test/domain/usecases/send_message_test.dart

void main() {
  late SendMessage useCase;
  late MockChatRepository mockRepo;

  setUp(() {
    mockRepo = MockChatRepository();
    useCase = SendMessage(mockRepo);
  });

  group('SendMessage', () {
    test('premium 用户发送消息应传递 isPremium=true', () async {
      when(mockRepo.sendMessage(any)).thenAnswer((_) async => tAIResponse);

      final result = await useCase.execute(
        sessionId: 'test-session',
        message: '最近睡不好',
        userContext: tPremiumContext,
      );

      expect(result.text, isNotEmpty);
      verify(mockRepo.sendMessage(argThat(
        predicate<SendMessageParams>((p) => p.userContext.isPremium == true),
      )));
    });

    test('Schema 解析失败应返回 fallback', () async {
      when(mockRepo.sendMessage(any)).thenAnswer(
        (_) async => AIResponse.fallback('raw text'),
      );

      final result = await useCase.execute(
        sessionId: 'test-session',
        message: 'hello',
        userContext: tFreeContext,
      );

      expect(result.tone, 'warm');  // fallback 默认
      expect(result.safetyFlag, SafetyFlag.green);
    });
  });
}

// test/domain/usecases/generate_daily_plan_test.dart

group('GenerateDailyPlan', () {
  test('premium 计划应包含深度洞察', () async { ... });
  test('free 计划应为简洁行动建议', () async { ... });
  test('超时应返回 fallback 计划', () async { ... });
});

// test/domain/usecases/schedule_follow_up_test.dart

group('ScheduleFollowUp', () {
  test('保存后应注册本地通知', () async { ... });
  test('dismiss 后应取消通知', () async { ... });
});

// test/domain/usecases/apply_presence_policy_test.dart

group('ApplyPresencePolicy', () {
  test('连续3次忽略应返回 reduced', () async {
    when(mockLocal.getPresenceRecord(any)).thenAnswer(
      (_) async => PresenceRecord(consecutiveIgnores: 3, stableDays: 2),
    );
    final level = await useCase.evaluate('user_1');
    expect(level, PresenceLevel.reduced);
  });

  test('稳定7天应返回 hidden', () async {
    when(mockLocal.getPresenceRecord(any)).thenAnswer(
      (_) async => PresenceRecord(consecutiveIgnores: 0, stableDays: 7),
    );
    final level = await useCase.evaluate('user_1');
    expect(level, PresenceLevel.hidden);
  });

  test('静默模式应立即 hidden', () async {
    when(mockLocal.getPresenceRecord(any)).thenAnswer(
      (_) async => PresenceRecord(silentModeActive: true),
    );
    final level = await useCase.evaluate('user_1');
    expect(level, PresenceLevel.hidden);
  });
});
```

### G2. Schema 回归测试

**测试用例组织**：

```
test/fixtures/
├── ai_response/
│   ├── free/
│   │   ├── chat_normal.json           # 免费用户正常聊天
│   │   ├── daily_plan_normal.json     # 免费用户每日计划
│   │   └── chat_with_cards.json       # 含内容卡
│   ├── premium/
│   │   ├── chat_deep_context.json     # 付费用户深度对话
│   │   ├── daily_plan_enriched.json   # 付费深度计划
│   │   └── chat_with_followup.json    # 含跟进计划
│   ├── abnormal/
│   │   ├── safety_yellow.json         # 黄区
│   │   ├── safety_red.json            # 红区 SafeMode
│   │   └── escalate_care.json         # CareStatus=escalate
│   ├── presence/
│   │   ├── reduced_presence.json      # 降频回复
│   │   └── hidden_presence.json       # 隐身回复
│   └── malformed/
│       ├── missing_fields.json        # 缺少必填字段
│       ├── wrong_types.json           # 类型错误
│       ├── empty_response.json        # 空响应
│       └── invalid_json.json          # 非法 JSON 字符串
```

```dart
// test/data/models/ai_response_schema_test.dart

void main() {
  group('AIResponse Schema 回归', () {
    final testCases = {
      'free/chat_normal': SafetyFlag.green,
      'premium/chat_deep_context': SafetyFlag.green,
      'abnormal/safety_red': SafetyFlag.red,
    };

    for (final entry in testCases.entries) {
      test('解析 ${entry.key}', () {
        final json = loadFixture('ai_response/${entry.key}.json');
        final response = AIResponseParser.parse(json);
        expect(response.safetyFlag, entry.value);
        expect(response.text, isNotEmpty);
      });
    }

    group('降级', () {
      test('missing_fields 应 fallback', () {
        final json = loadFixture('ai_response/malformed/missing_fields.json');
        final response = AIResponseParser.parse(json);
        expect(response.tone, 'warm'); // fallback 默认值
      });

      test('invalid_json 应 fallback', () {
        final rawString = loadRawFixture('ai_response/malformed/invalid_json.json');
        final response = AIResponseParser.parseRaw(rawString);
        expect(response.text, isNotEmpty);
      });
    });
  });
}
```

### G3. UI Smoke Test

```dart
// test/presentation/pages/smoke_test.dart

void main() {
  group('UI Smoke Tests', () {
    testWidgets('ChatPage 可启动并渲染', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith((_) => AsyncValue.data([])),
            isPremiumProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(home: ChatPage()),
        ),
      );
      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.byType(ChatInputBar), findsOneWidget);
    });

    testWidgets('HomePage 可渲染 TodayPlanSection', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyPlanProvider.overrideWith((_) =>
              AsyncValue.data(DailyPlan.fallback())),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      expect(find.byType(TodayPlanSection), findsOneWidget);
    });

    testWidgets('ChatPage SafeMode 降级 UI', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSafetyFlagProvider.overrideWithValue(SafetyFlag.red),
            chatMessagesProvider.overrideWith((_) => AsyncValue.data([])),
          ],
          child: const MaterialApp(home: ChatPage()),
        ),
      );
      expect(find.byType(SafeModeBanner), findsOneWidget);
      expect(find.byType(SystemNoticeCard), findsOneWidget);
      // 确认无促销组件
      expect(find.text('升级'), findsNothing);
      expect(find.text('解锁'), findsNothing);
    });

    testWidgets('SubscriptionPage 措辞不含"解锁功能"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [subscriptionProductsProvider.overrideWith((_) =>
            AsyncValue.data(tProducts))],
          child: const MaterialApp(home: SubscriptionPage()),
        ),
      );
      expect(find.textContaining('连续照护'), findsWidgets);
      expect(find.textContaining('解锁'), findsNothing);
    });
  });
}
```

---

## H. 发布与运维

### H1. 双端打包流程

```
┌──────────────────────────────────────────────────┐
│                CI/CD Pipeline                     │
│            (GitHub Actions / Codemagic)            │
│                                                    │
│  ┌─────────┐    ┌──────────┐    ┌──────────────┐  │
│  │ flutter  │ →  │  flutter │ →  │   fastlane   │  │
│  │  test    │    │  build   │    │  upload      │  │
│  └─────────┘    └──────────┘    └──────────────┘  │
│                      │                             │
│         ┌────────────┴────────────┐                │
│    iOS (ipa)              Android (aab)            │
│    flutter build ipa      flutter build appbundle   │
│    fastlane pilot         fastlane supply           │
│   (TestFlight)            (Play Console 内测)       │
└──────────────────────────────────────────────────┘
```

**fastlane 配置**：

```ruby
# fastlane/Fastfile

platform :ios do
  desc "Deploy to TestFlight"
  lane :beta do
    setup_ci
    match(type: "appstore", readonly: true)
    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
    )
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end
end

platform :android do
  desc "Deploy to Play Console Internal Testing"
  lane :beta do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "android/",
    )
    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
    )
  end
end
```

### H2. 环境变量与密钥管理

| 密钥类型 | 存储位置 | 绝不存放 |
|----------|----------|----------|
| AI Router API Key | 服务端环境变量 | ❌ 客户端代码 |
| Supabase Anon Key | .env 文件（CI 注入） | ❌ Git 仓库 |
| StoreKit 共享密钥 | Apple App Store Connect | ❌ 客户端 |
| Google Play 签名密钥 | GitHub Secrets / Vault | ❌ Git 仓库 |
| LLM Model API Key | AI Router 服务端 | ❌ 客户端任何位置 |

```yaml
# .github/workflows/build.yml (密钥注入示例)
env:
  SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
  SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  AI_ROUTER_BASE_URL: ${{ secrets.AI_ROUTER_BASE_URL }}
```

```dart
// 客户端通过 --dart-define 注入环境变量
// flutter build --dart-define=ENV=prod \
//   --dart-define=SUPABASE_URL=$SUPABASE_URL \
//   --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

### H3. 监控指标

| 类别 | 指标 | 采集方式 | 告警阈值 |
|------|------|----------|----------|
| **稳定性** | 崩溃率 | Firebase Crashlytics / Sentry | > 0.5% |
| **稳定性** | ANR 率 (Android) | Firebase Performance | > 0.2% |
| **API** | API 成功率 | 服务端 + 端上上报 | < 99% |
| **API** | API P99 延迟 | 服务端 metrics | > 3s |
| **AI** | LLM 超时率 | AI Router 日志 | > 5% |
| **AI** | Schema 失败率 | AI Router 日志 | > 3% |
| **AI** | safety_flag=red 分布 | AI Router 日志 | 异常增长告警 |
| **AI** | Token 消耗 | AI Router 日志 | 日预算上限 |
| **订阅** | 订阅校验失败率 | 服务端收据验证 | > 1% |
| **订阅** | 购买成功率 | 端上 + 服务端 | < 95% |
| **业务** | 每日计划生成成功率 | 端上上报 | < 95% |
| **业务** | SafeMode 触发频次 | AI Router 日志 | 监控趋势 |
| **业务** | 退让（hidden）占比 | 端上上报 | 仅监控趋势 |

**日志审计字段（每次 AI 调用必须记录）**：

```json
{
  "timestamp": "2026-03-05T09:30:00Z",
  "user_id": "u_123",
  "session_id": "sess_456",
  "request_type": "chat",
  "prompt_version": {
    "core": "core_v1.2",
    "policy": "policy_v1.0",
    "task": "chat_v2.1"
  },
  "model": "qwen2.5-72b-instruct",
  "tokens": {
    "prompt": 1200,
    "completion": 350,
    "total": 1550
  },
  "latency_ms": 2340,
  "safety_flag": "green",
  "care_status": "stable",
  "user_tier": "premium",
  "schema_valid": true,
  "fallback_used": false,
  "presence_level": "normal"
}
```

---

## 附录：核心 pubspec.yaml 依赖

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # 网络
  dio: ^5.4.0
  connectivity_plus: ^6.0.0

  # 本地存储
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  drift: ^2.15.0                    # SQLite ORM（聊天记录持久化）

  # 订阅
  in_app_purchase: ^3.2.0

  # 通知 & 后台
  flutter_local_notifications: ^17.0.0
  workmanager: ^0.5.2               # Android 后台任务

  # 路由
  go_router: ^14.0.0

  # UI 组件
  shimmer: ^3.0.0                   # 骨架屏
  cached_network_image: ^3.3.0      # 图片缓存
  flutter_markdown: ^0.7.0          # Markdown 渲染
  video_player: ^2.8.0

  # 工具
  freezed_annotation: ^2.4.0        # 不可变类
  json_annotation: ^4.9.0           # JSON 序列化
  share_plus: ^9.0.0                # 分享
  url_launcher: ^6.2.0              # 打开电话/链接
  intl: ^0.19.0                     # 国际化/日期格式

  # 监控
  firebase_crashlytics: ^3.5.0
  firebase_analytics: ^10.8.0
  firebase_performance: ^0.10.0
  sentry_flutter: ^8.0.0            # 可选，备选 Crashlytics

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  integration_test:
    sdk: flutter
```

---

> **下一步行动建议**：
> 1. `flutter create shunshi_flutter` 初始化项目
> 2. 按 A 部分目录结构建立骨架
> 3. 先实现 `domain/entities/` 全部数据模型（B 部分）
> 4. 配置环境 + DI（A3/A4）
> 5. 实现 AI Router Client + Schema 解析（C 部分）
> 6. 集成订阅层（D 部分）
> 7. 逐页搭建 UI（E 部分）
> 8. 实现跟进/退让/SafeMode（F 部分）
> 9. 补全测试（G 部分）
> 10. 配置 CI/CD 与监控（H 部分）
