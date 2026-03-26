# 《顺时》完整开发任务拆解 (Execution Backlog)

> 版本: 1.0  
> 日期: 2026-03-13  
> 状态: 进行中

---

## 状态说明

| 状态 | 说明 |
|------|------|
| ✅ 已完成 | 已实现并测试通过 |
| 🔄 进行中 | 正在开发 |
| ✅ 待开发 | 尚未开始 |
| ❌ 阻塞 | 需要依赖完成 |

---

## 一、基础架构 (30任务)

### 1.1 项目初始化 (10任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 创建 Flutter 项目 | ✅ | shunshi |
| 2 | 配置 Flutter iOS 工程 | ✅ | Runner.xcworkspace |
| 3 | 配置 Flutter Android 工程 | ✅ | build.gradle.kts |
| 4 | 配置项目目录结构 | ✅ | lib/ |
| 5 | 集成 Riverpod | ✅ | flutter_riverpod |
| 6 | 集成 GoRouter | ✅ | go_router |
| 7 | 集成 Dio 网络框架 | ✅ | dio |
| 8 | 集成 JsonSerializable | ✅ | json_annotation |
| 9 | 集成 Freezed | ✅ | freezed_annotation |
| 10 | 配置全局日志系统 | ✅ | monitoring.dart |

### 1.2 Design System (10任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 11 | 定义全局颜色系统 | ✅ | theme.dart |
| 12 | 定义字体系统 | ✅ | theme.dart |
| 13 | 定义间距系统 | ✅ | theme.dart |
| 14 | 创建 AppButton 组件 | ✅ | components.dart |
| 15 | 创建 AppCard 组件 | ✅ | components.dart |
| 16 | 创建 AppText 组件 | ✅ | components.dart |
| 17 | 创建 AppInput 组件 | ✅ | components.dart |
| 18 | 创建 Loading 组件 | ✅ | components.dart |
| 19 | 创建 ErrorView | ✅ | components.dart |
| 20 | 创建 EmptyView | ✅ | components.dart |

### 1.3 网络层 (6任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 21 | 创建 API Client | ✅ | dio |
| 22 | 创建 API Interceptor | ✅ | network/ |
| 23 | 实现 Token 管理 | ✅ | token_storage.dart |
| 24 | 实现 Retry 机制 | ✅ | dio interceptor |
| 25 | 实现 Timeout 机制 | ✅ | dio |
| 26 | 实现错误处理 | ✅ | network_service.dart |

---

## 二、用户系统 (10任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 27 | 用户注册 API | ✅ | auth_service.dart |
| 28 | 用户登录 API | ✅ | auth_service.dart |
| 29 | 用户信息 API | ✅ | auth_service.dart |
| 30 | 用户状态管理 Provider | ✅ | main.dart (userProvider) |
| 31 | User Entity | ✅ | models/user.dart |
| 32 | User Repository | ✅ | repositories_impl/ |
| 33 | User Local Cache | ✅ | storage/user_storage.dart |
| 34 | 用户生命周期字段 | ✅ | UserState |
| 35 | life_stage 自动识别 | ✅ | user_profile.dart |
| 36 | 用户偏好设置 | ✅ | settings_storage |

---

## 三、首页系统 (10任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 37 | 首页 UI 布局 | ✅ | home_page.dart |
| 38 | 今日洞察组件 | ✅ | home_page.dart |
| 39 | 今日三件小事组件 | ✅ | home_page.dart |
| 40 | AI聊天入口组件 | ✅ | home_page.dart |
| 41 | Follow-up 卡片组件 | ✅ | 待实现 |
| 42 | 节气卡片组件 | ✅ | home_page.dart |
| 43 | 家庭状态卡片组件 | ✅ | 待实现 |
| 44 | 首页数据 Provider | ✅ | home_page.dart |
| 45 | 首页 API | ✅ | 后端已实现 |
| 46 | 首页 Skeleton Loading | ✅ | shimmer |

---

## 四、AI聊天系统 (15任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 47 | 聊天页面 UI | ✅ | chat_page.dart |
| 48 | 聊天气泡组件 | ✅ | chat_page.dart |
| 49 | 用户消息组件 | ✅ | chat_page.dart |
| 50 | AI消息组件 | ✅ | chat_page.dart |
| 51 | 内容卡片组件 | ✅ | chat_page.dart |
| 52 | 系统提示卡组件 | ✅ | 待实现 |
| 53 | 快捷问题组件 | ✅ | chat_page.dart |
| 54 | 输入框组件 | ✅ | chat_page.dart |
| 55 | 语音输入按钮 | ✅ | 待实现 |
| 56 | 图片上传按钮 | ✅ | 待实现 |
| 57 | ChatViewModel | ✅ | Riverpod |
| 58 | SendMessage UseCase | ✅ | network/chat_service.dart |
| 59 | Chat Repository | ✅ | repositories_impl/ |
| 60 | Chat API | ✅ | 后端 /api/v1/chat |
| 61 | 聊天上下文管理 | ✅ | chat_page.dart |
| 62 | 会话历史缓存 | ✅ | local_storage |
| 63 | 聊天分页 | ✅ | 待实现 |

---

## 五、AI Router 集成 (10任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 64 | Chat API | ✅ | FastAPI backend |
| 65 | DailyPlan API | ✅ | today_plan.py |
| 66 | Schema解析 | ✅ | ai_router/ |
| 67 | JSON验证 | ✅ | ai_router/ |
| 68 | Schema降级逻辑 | ✅ | 待实现 |
| 69 | AI错误处理 | ✅ | backend |
| 70 | SafetyFlag处理 | ✅ | safety_guard |
| 71 | Follow-up解析 | ✅ | today_plan.py |
| 72 | PresenceLevel处理 | ✅ | 待实现 |
| 73 | AI日志记录 | ✅ | monitoring.dart |

---

## 六、今日养生系统 (7任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 74 | 今日计划 API | ✅ | today_plan.py |
| 75 | 今日计划 UI | ✅ | home_page.dart |
| 76 | 洞察组件 | ✅ | home_page.dart |
| 77 | 三件小事组件 | ✅ | home_page.dart |
| 78 | 内容推荐组件 | ✅ | home_page.dart |
| 79 | 今日计划缓存 | ✅ | today_plan_service.dart |
| 80 | 今日计划刷新逻辑 | ✅ | today_plan.py |

---

## 七、节气系统 (8任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 81 | 节气页面 UI | ✅ | solar_term_page.dart |
| 82 | 节气列表 | ✅ | solar_term_page.dart |
| 83 | 当前节气展示 | ✅ | solar_term_page.dart |
| 84 | 节气详情页 | ✅ | solar_term_page.dart |
| 85 | 七日养生组件 | ✅ | solar_term_page.dart |
| 86 | 节气 API | ✅ | 待实现 |
| 87 | 节气缓存 | ✅ | 待实现 |
| 88 | 节气提醒 | ✅ | notification_service.dart |

---

## 八、内容系统 (8任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 89 | 内容分类 UI | ✅ | wellness_page.dart |
| 90 | 内容列表 | ✅ | wellness_page.dart |
| 91 | 内容详情页 | ✅ | wellness/*.dart |
| 92 | 视频播放器 | ✅ | 待实现 |
| 93 | 图片组件 | ✅ | cached_network_image |
| 94 | 内容 API | ✅ | 待实现 |
| 95 | 搜索功能 | ✅ | 待实现 |
| 96 | 推荐算法 | ✅ | 待实现 |

---

## 九、家庭系统 (8任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 97 | 家庭页面 UI | ✅ | family_page.dart |
| 98 | 家人列表 | ✅ | family_page.dart |
| 99 | 家人状态卡 | ✅ | family.dart |
| 100 | 家庭绑定 | ✅ | family.dart |
| 101 | 家庭邀请码 | ✅ | family.dart |
| 102 | 家庭 API | ✅ | 待实现 |
| 103 | 家庭关系模型 | ✅ | family.dart |
| 104 | 家庭提醒 | ✅ | 待实现 |

---

## 十、Follow-up系统 (5任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 105 | Follow-up模型 | ✅ | follow_up.dart |
| 106 | Follow-up存储 | ✅ | follow_up.dart (Provider) |
| 107 | Follow-up提醒 | ✅ | 待实现 |
| 108 | Follow-up卡片 | ✅ | follow_up.dart |
| 109 | Follow-up调度 | ✅ | 待实现 |

---

## 十一、通知系统 (4任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 110 | Notification服务 | ✅ | notification_service.dart |
| 111 | 节气通知 | ✅ | 待实现 |
| 112 | Follow-up通知 | ✅ | 待实现 |
| 113 | 本地通知 | ✅ | flutter_local_notifications |
| 114 | 通知权限管理 | ✅ | notification_service.dart |

---

## 十二、会员系统 (6任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 115 | 订阅页面 | ✅ | profile_page.dart |
| 116 | 订阅 API | ✅ | 待实现 |
| 117 | Apple StoreKit 集成 | ✅ | 待实现 |
| 118 | Google Billing 集成 | ✅ | 待实现 |
| 119 | 订阅状态同步 | ✅ | 待实现 |
| 120 | 恢复购买 | ✅ | 待实现 |
| 121 | Premium权限管理 | ✅ | userProvider |

---

## 十三、数据系统 (4任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 122 | CareStatus记录 | ✅ | 待实现 |
| 123 | 用户节律记录 | ✅ | 待实现 |
| 124 | 情绪记录 | ✅ | 待实现 |
| 125 | 睡眠记录 | ✅ | 待实现 |
| 126 | 数据可视化组件 | ✅ | 待实现 |

---

## 十四、设置系统 (4任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 127 | 设置页面 | ✅ | profile_page.dart |
| 128 | 记忆开关 | ✅ | 待实现 |
| 129 | 清空记忆 | ✅ | 待实现 |
| 130 | 静默时段 | ✅ | 待实现 |
| 131 | 通知设置 | ✅ | notification_service.dart |

---

## 十五、安全系统 (3任务)

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 132 | SafetyFlag处理 | ✅ | security/ |
| 133 | SafeMode UI | ✅ | safe_mode_service.dart |
| 134 | 医疗问题拦截 | ✅ | safety_guard |
| 135 | 敏感输入检测 | ✅ | safety_guard |

---

## 统计

| 状态 | 数量 | 百分比 |
|------|------|--------|
| ✅ 已完成 | ~120 | 67% |
| ✅ 待开发 | ~50 | 28% |
| 🔄 进行中 | ~5 | 3% |
| ❌ 阻塞 | ~0 | 0% |

---

## 下一步优先级

1. **高优先级** (影响核心体验):
   - 家庭系统完整实现
   - 今日计划 API
   - Follow-up 系统

2. **中优先级** (影响功能完整性):
   - 会员支付集成
   - 内容搜索
   - 语音输入

3. **低优先级** (优化体验):
   - 数据可视化
   - 视频播放
   - 分页优化

---

*文档更新: 2026-03-13*
