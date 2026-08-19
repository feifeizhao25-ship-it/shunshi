# 顺时 Flutter 工程骨架 · 完整交付文档

## 0. 总体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (iOS + Android)               │
│                   统一 Material 3 Design System              │
│  ┌────────────┐  ┌──────────┐  ┌────────────┐  ┌────────┐  │
│  │  Chat Page │  │Daily Plan│  │SolarTerm   │  │Content │  │
│  │            │  │          │  │            │  │Library │  │
│  └────────────┘  └──────────┘  └────────────┘  └────────┘  │
│  ┌────────────┐  ┌──────────────────────────────────────┐   │
│  │Me/Settings │  │           Subscribe Page              │   │
│  └────────────┘  └──────────────────────────────────────┘   │
│             go_router + ShellRoute + AppBottomNav             │
├─────────────────────────────────────────────────────────────┤
│                  Presentation Layer (Riverpod)               │
│  chatProvider · dailyPlanProvider · contentProvider          │
│  subscriptionProvider · settingsProvider · appStateProvider  │
├─────────────────────────────────────────────────────────────┤
│                     Domain Layer                             │
│  SendMessage · GenerateDailyPlan · ScheduleFollowup          │
│  ApplyPresencePolicy                                         │
│  Repositories (abstract interfaces)                          │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                              │
│  ┌─────────────┐   ┌─────────────┐   ┌──────────────────┐  │
│  │ AiRouterApi │   │  Subscription│   │ContentRepository │  │
│  │  (Dio)      │   │  Repository  │   │(Mock→API)        │  │
│  └──────┬──────┘   │  (IAP)       │   └──────────────────┘  │
│         │          └─────────────┘                           │
│  ┌──────▼──────┐   ┌─────────────┐                          │
│  │  ApiClient  │   │UserRepository│                         │
│  │  (retry×2) │   │(SharedPrefs) │                          │
│  └──────┬──────┘   └─────────────┘                          │
│         │                                                    │
├─────────┼────────────────────────────────────────────────── ┤
│         ▼           External Services                        │
│   ┌──────────────────────────────┐                          │
│   │       AI Router              │                          │
│   │  POST /chat/send             │                          │
│   │  POST /dailyPlan/generate    │                          │
│   │  (Prompt版本: core/policy/task)│                        │
│   └──────────────────────────────┘                          │
│   ┌──────────┐  ┌─────────────┐  ┌────────────────────┐    │
│   │App Store │  │Google Play  │  │LocalNotifications  │    │
│   │  (IAP)   │  │  (IAP)      │  │(flutter_local_notif)│   │
│   └──────────┘  └─────────────┘  └────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. 完整项目目录树

```
shunshi_app/
├── pubspec.yaml
├── lib/
│   ├── main.dart                          # 入口：ProviderScope + SharedPrefs
│   ├── design_system/
│   │   ├── design_system.dart             # barrel export
│   │   ├── theme.dart                     # Material3 Theme + Colors + Spacing
│   │   └── components/
│   │       ├── app_text.dart              # 统一文本组件
│   │       ├── app_button.dart            # 统一按钮（primary/outline/text/danger）
│   │       ├── app_card.dart              # 统一卡片（elevated/outlined/filled）
│   │       ├── app_topbar.dart            # 统一顶部栏
│   │       ├── app_bottom_nav.dart        # 统一底部导航
│   │       ├── app_sheet.dart             # 统一底端弹窗
│   │       └── app_notice_card.dart       # 系统通知卡片
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_context.dart (.g.dart)
│   │   │   ├── subscription_state.dart (.g.dart)
│   │   │   ├── message.dart (.g.dart)
│   │   │   ├── ai_response.dart (.g.dart) # 严格 JSON Schema + 降级
│   │   │   ├── care_status.dart           # stable/needs_attention/escalate
│   │   │   ├── follow_up_plan.dart (.g.dart)
│   │   │   ├── life_phase_summary.dart (.g.dart)
│   │   │   └── content_item.dart (.g.dart)
│   │   ├── api/
│   │   │   ├── api_client.dart            # Dio + 重试(×2) + 日志
│   │   │   └── ai_router_api.dart         # /chat/send + /dailyPlan/generate
│   │   └── repositories/
│   │       ├── ai_repository_impl.dart
│   │       ├── subscription_repository_impl.dart  # in_app_purchase
│   │       ├── content_repository_impl.dart       # mock + API ready
│   │       ├── user_repository_impl.dart
│   │       └── followup_repository_impl.dart
│   ├── domain/
│   │   ├── repositories/                  # 抽象接口
│   │   │   ├── ai_repository.dart
│   │   │   ├── subscription_repository.dart
│   │   │   ├── content_repository.dart
│   │   │   ├── user_repository.dart
│   │   │   └── followup_repository.dart
│   │   └── usecases/
│   │       ├── send_message.dart
│   │       ├── generate_daily_plan.dart
│   │       ├── schedule_followup.dart
│   │       └── apply_presence_policy.dart
│   ├── presentation/
│   │   ├── router.dart                    # GoRouter + ShellRoute
│   │   ├── shell_page.dart                # AppBottomNav 壳
│   │   ├── providers/
│   │   │   ├── infrastructure_providers.dart  # Repository providers
│   │   │   ├── app_state_provider.dart        # UserContext
│   │   │   ├── subscription_provider.dart
│   │   │   ├── chat_provider.dart             # SafeMode + Presence
│   │   │   ├── daily_plan_provider.dart
│   │   │   ├── content_provider.dart
│   │   │   └── settings_provider.dart
│   │   └── pages/
│   │       ├── chat_page.dart             # 消息/卡片/系统通知渲染
│   │       ├── daily_plan_page.dart       # 折叠/Premium展开
│   │       ├── solar_term_page.dart       # 当期七日游程
│   │       ├── content_library_page.dart  # 分类过滤+分页
│   │       ├── content_detail_page.dart   # 图/视频降级
│   │       ├── me_settings_page.dart      # 记忆/静默/边界说明
│   │       └── subscribe_page.dart        # 连续照护
│   └── core/
│       ├── safety/
│       │   ├── safety_guard.dart          # safety_flag → SafeModeState
│       │   └── system_notice_messages.dart # 人格化边界文案
│       └── notifications/
│           ├── local_notifications.dart   # flutter_local_notifications
│           └── followup_scheduler.dart    # 保存+到期+通知
└── test/
    ├── schema_parse_test.dart             # AI Schema 解析 + 降级（10 tests ✅）
    └── smoke_test.dart                    # 页面路由 + 组件渲染
```

---

## 2. AI Router 协议（写死规范）

### POST /chat/send

**Request:**
```json
{
  "user_id": "uuid-v4",
  "context": {
    "is_premium": true,
    "memory_enabled": true,
    "quiet_hours": { "enabled": false, "start": "22:00", "end": "07:00" },
    "proactive_enabled": true
  },
  "message": "用户输入的文字",
  "prompt_version": {
    "core": "SS_CORE_ALL_v1.0",
    "policy": "SS_POLICY_PREMIUM_v1.2",
    "task": "SS_TASK_CHAT_v1.0"
  }
}
```

**Response (严格 Schema):**
```json
{
  "text": "...",
  "tone": "gentle",
  "care_status": "stable",
  "follow_up": { "in_days": 2, "intent": "sleep_check" },
  "offline_encouraged": true,
  "presence_level": "normal",
  "safety_flag": "none",
  "cards": [{ "type": "acupoint", "content_id": "...", "title": "...", "media": {} }]
}
```

### POST /dailyPlan/generate

**Request:** 结构同上（无 `message` 字段）

**Response:** 结构同上

---

## 3. 运行说明

### 3.1 开发模式启动

```bash
cd shunshi_app

# 配置 AI Router 地址（必须）
flutter run \
  --dart-define=AI_ROUTER_URL=https://api.shunshi.ai/v1 \
  --dart-define=AI_ROUTER_API_KEY=your_api_key_here
```

### 3.2 Staging 环境

```bash
flutter run \
  --dart-define=AI_ROUTER_URL=https://staging-api.shunshi.ai/v1 \
  --dart-define=AI_ROUTER_API_KEY=staging_key
```

### 3.3 生产构建

```bash
# iOS
flutter build ios \
  --release \
  --dart-define=AI_ROUTER_URL=https://api.shunshi.ai/v1 \
  --dart-define=AI_ROUTER_API_KEY=prod_key

# Android
flutter build appbundle \
  --release \
  --dart-define=AI_ROUTER_URL=https://api.shunshi.ai/v1 \
  --dart-define=AI_ROUTER_API_KEY=prod_key
```

### 3.4 无后端 Mock 模式运行

`ContentRepositoryImpl` 已内置 mock 数据，可直接运行。

对于 AI 接口，可将 `AI_ROUTER_URL` 指向本地 mock 服务器（如 [json-server](https://github.com/typicode/json-server)）：

```bash
# 1. 创建 mock API 响应
cat > /tmp/db.json << 'EOF'
{
  "chat": {
    "text": "你好，今天感觉怎么样？",
    "tone": "gentle",
    "care_status": "stable",
    "offline_encouraged": false,
    "presence_level": "normal",
    "safety_flag": "none"
  }
}
EOF

# 2. 启动 json-server
npx json-server --watch /tmp/db.json --port 3001

# 3. 启动 App 指向 mock
flutter run --dart-define=AI_ROUTER_URL=http://localhost:3001
```

或修改 `AiRepositoryImpl` 使用 `MockAiRouter`：

```dart
// 在 infrastructure_providers.dart 中替换
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return MockAiRepositoryImpl(); // 返回固定 AiResponse
});
```

### 3.5 运行测试

```bash
# Schema 解析单元测试（10 tests）
flutter test test/schema_parse_test.dart

# Smoke 测试（Widget 渲染）
flutter test test/smoke_test.dart

# 全部测试
flutter test
```

---

## 4. 字体配置

NotoSansSC 需手动下载：

```bash
# 从 Google Fonts 下载
curl -o assets/fonts/NotoSansSC-Regular.otf \
  "https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
```

然后在 `pubspec.yaml` 取消字体注释，在 `theme.dart` 将 `_fontFamily = null` 改回 `'NotoSansSC'`。

---

## 5. 万亿结构落地说明

| 能力 | 实现位置 | 硬性约束 |
|-----|---------|---------|
| **CareStatus** | `AiResponse.parsedCareStatus` | 默认不外显，仅内部触发策略 |
| **FollowUpPlan** | `FollowUpScheduler` + `followup_repository_impl` | 到期显示卡片，可选本地通知 |
| **PresencePolicy** | `ApplyPresencePolicy` usecase + `chat_provider` | 连续3次未回复 → `presence_level=reduced` |
| **AbnormalFirst/SafeMode** | `SafetyGuard.evaluate()` + `AppNoticeCard.safety` | `safety_flag!=none` → 禁止促销弹窗 |
| **Memory** | `UserContext.memoryEnabled` + `clearMemory()` | 开关+清空按钮，在 MeSettingsPage |
| **Subscription** | `SubscriptionRepositoryImpl` (IAP) | `isPremium` 注入 `UserContext`，冷启动/前台/购买刷新 |

> [!IMPORTANT]
> 异常场景（`safety_flag != none`）时，`SubscribePage` 不会被路由器跳转，`chatProvider` 中的 `SafeModeState.blockPromotion=true` 在 Chat 页顶部栏隐藏"了解连续照护"入口。

> [!NOTE]
> `memory_enabled=false` 时，`clearMemory()` 仍可手动调用清空本地历史。记忆功能开关仅影响发送到 AI Router 的 `context.memory_enabled` 字段——服务端据此决定是否使用记忆摘要。
