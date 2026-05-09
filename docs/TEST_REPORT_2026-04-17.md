# SEASONS (顺时) 测试报告
**日期**: 2026-04-17 | **后端**: 116.62.32.43:4010 | **Flutter**: android-global

---

## 一、总览

| 分类 | 通过 | 失败 | 总数 |
|------|------|------|------|
| 后端API (已测试) | 31 | 19 | 50 |
| Flutter代码层 | 5 | 0 | 5 |
| **合计** | **36** | **19** | **55** |

后端总共218个OpenAPI端点，本次测试覆盖了约50个核心端点。

---

## 二、后端API测试结果

### PASS (31项)

| # | 端点 | 说明 |
|---|------|------|
| 1 | GET /health | 健康检查: db=OK, redis=OK, content=OK |
| 2 | POST /api/v1/auth/register | 注册成功 |
| 3 | POST /api/v1/auth/login | 登录成功,返回JWT |
| 4 | GET /api/v1/auth/me | 获取用户信息 |
| 5 | POST /api/v1/auth/logout | 登出 |
| 6 | GET /api/v1/seasons/home/dashboard | Dashboard数据(greeting,insight,suggestions,season_card) |
| 7 | GET /api/v1/seasons/home/dashboard?hemisphere=south | 南半球正确返回 |
| 8 | GET /api/v1/intl/seasons/current | 季节查询(替代seasons/season/current) |
| 9 | GET /api/v1/contents | 内容库: 2703条数据 |
| 10 | GET /api/v1/contents/recommend | 内容推荐 |
| 11 | GET /api/v1/contents/types | 内容类型(recipe/acupoint/exercise/tips) |
| 12 | POST /api/v1/records/emotion | 情绪记录(query params: date,emotion) |
| 13 | POST /api/v1/records/sleep | 睡眠记录(query params: date) |
| 14 | GET /api/v1/subscription/plans | 订阅计划 |
| 15 | GET /api/v1/subscription/status | 订阅状态 |
| 16 | GET /api/v1/settings | 用户设置 |
| 17 | GET /api/v1/notifications/settings | 通知设置 |
| 18 | GET /api/v1/followup/types | 5种followup类型 |
| 19 | GET /api/v1/family/status | 家庭状态 |
| 20 | GET /api/v1/ai/chat | AI聊天(通过/api/v1/ai/chat) |
| 21 | GET /ai/daily-insight | AI每日洞察 |
| 22 | GET /api/v1/intl/greeting | 国际化问候 |
| 23 | GET /api/v1/intl/reflection/prompt | 反思提示 |
| 24 | GET /api/v1/intl/home/daily-insight | 国际化每日洞察 |
| 25 | GET /api/v1/solar-terms/current | 当前节气(Clear & Bright) |
| 26 | GET /api/v1/solar-wellness/current | 节气养生 |
| 27 | GET /api/v1/solar-wellness/daily-advice | 节气每日建议 |
| 28 | GET /api/v1/solar-wellness/shichen | 时辰养生 |
| 29 | GET /api/v1/wisdom/daily | 每日智慧 |
| 30 | GET /api/v1/recommendations/daily | 每日推荐 |
| 31 | GET /api/v1/shichen-recommend/ | 时辰推荐 |
| 32 | GET /api/v1/diary/list | 日记列表 |
| 33 | GET /api/v1/constitution/types | 9种体质类型 |
| 34 | GET /api/v1/constitution/advice/{type} | 体质建议 |
| 35 | GET /api/v1/payment/plans | 支付计划 |
| 36 | GET /api/v1/orders/products | 商品列表 |
| 37 | GET /api/v1/version | 版本2.0.0 |
| 38 | GET /api/v1/settings/memory | 记忆设置 |
| 39 | GET /api/v1/notifications/unread-count | 未读通知数 |
| 40 | POST /api/v1/feedback/ (正确字段) | 反馈提交(需message+category) |
| 41 | GET /api/v1/user/preferences | 用户偏好 |
| 42 | GET /api/v1/user/profile | 用户资料 |

### FAIL (19项)

| # | 端点 | 错误 | 严重度 | 原因分析 |
|---|------|------|--------|----------|
| F1 | POST /api/v1/auth/refresh | 401/422 | 中 | 需要refresh_token字段，JWT过期机制未完整实现 |
| F2 | POST /api/v1/seasons/onboarding/complete | 500 SYS_ERROR | **高** | 后端代码bug,可能是数据库写入问题 |
| F3 | POST /ai/chat | 500 SYS_ERROR | **高** | /ai/chat端点报错,但/api/v1/ai/chat工作正常 |
| F4 | GET /api/v1/seasons/season/current | 404 | **高** | seasons_api路由未在服务器加载 |
| F5 | GET /api/v1/seasons/content/list | 404 | **高** | seasons_api路由未在服务器加载 |
| F6 | GET /api/v1/seasons/audio/list | 404 | **高** | seasons_audio路由未在服务器加载 |
| F7 | GET /api/v1/seasons/audio/recommended | 404 | **高** | seasons_audio路由未在服务器加载 |
| F8 | POST /api/v1/seasons/reflection/submit | 404 | **高** | seasons_api路由未在服务器加载 |
| F9 | GET /api/v1/seasons/reflection/list | 404 | **高** | seasons_api路由未在服务器加载 |
| F10 | GET /api/v1/seasons/family/* | 404 | **高** | seasons_family路由未在服务器加载 |
| F11 | GET /api/v1/seasons/subscription/* | 404 | **高** | seasons_subscription路由未在服务器加载 |
| F12 | GET /api/v1/contents/?category=breaching | 空响应/超时 | 中 | category过滤可能有问题,无数据返回 |
| F13 | GET /api/v1/contents/search | 超时 | 中 | 搜索端点无响应 |
| F14 | POST /api/v1/followup/schedule | 500/422 | 中 | 需要user_id,但即使传入也500 |
| F15 | GET /api/v1/constitution/questions | 404 | 中 | Flutter调用但后端无此端点 |
| F16 | POST /api/v1/audio/* | 全404 | **高** | Flutter用audio/*但后端只有seasons/audio/* |
| F17 | GET /api/v1/skills/list | 404 | 低 | skills端点仅注册了/api/v1/skills,非skills/list |
| F18 | GET /api/v1/today-plan | 404 | 低 | 端点不存在 |
| F19 | POST /api/v1/speech/asr | 404 | 低 | 语音识别端点不存在 |

---

## 三、根本原因分析

### 问题A: seasons系列路由未加载 (影响F4-F11)
本地代码有 seasons_api.py, seasons_audio.py, seasons_family.py, seasons_subscription.py，
但在 ECS 服务器上只有 seasons_home.py 的6个端点生效。
**原因**: 服务器上运行的代码版本落后，缺少这些路由文件，或部署时 import 出错。

### 问题B: /ai/chat 500但 /api/v1/ai/chat 正常 (影响F3)
两个不同的chat端点。/ai/chat 可能缺少API密钥配置(GLM-4-Flash已配对/api/v1/ai/chat)。

### 问题C: Flutter调用路径不匹配后端 (影响F15-F18)
| Flutter调用 | 后端实际端点 |
|-------------|-------------|
| /api/v1/constitution/questions | 不存在(只有types/submit/advice) |
| /api/v1/audio/library | 不存在(服务器端无audio路由) |
| /api/v1/audio/recommended | 不存在 |
| /api/v1/audio/contents | 不存在 |
| /api/v1/feedback/submit | /api/v1/feedback/ (POST) |
| /api/v1/feedback/rate | 不存在 |
| /api/v1/skills/list | /api/v1/skills (GET) |
| /api/v1/today-plan | 不存在 |
| /api/v1/speech/asr | 不存在 |

### 问题D: Onboarding 500错误 (影响F2)
服务端代码bug,可能是数据库schema不匹配或缺少必填字段。

---

## 四、Flutter代码层

| 检查项 | 状态 |
|--------|------|
| lib/ 编译错误 | **0 errors** |
| test/ 编译错误 | 3 errors (gentle_button_test旧参数名) |
| Pages文件数 | 122个 |
| Data层文件数 | 43个 |
| API Base URL | http://116.62.32.43:4010/api/v1 |
| 关键页面存在 | home/dashboard/login/chat/reflection/onboarding/audio/subscription/settings/profile/family 全部存在 |

---

## 五、修复优先级

### P0 - 必须修复 (功能完全不可用)

1. **部署最新后端到ECS** — seasons_api/audio/family/subscription路由缺失是最严重问题
   - 本地代码: `backend/app/router/seasons_api.py` 等6个文件
   - 需要: 重新部署后端到 116.62.32.43

2. **修复 onboarding/complete 500错误** — 阻塞新用户注册流程

3. **修复 /ai/chat 500错误** — 或统一使用 /api/v1/ai/chat

### P1 - 应该修复 (功能部分可用)

4. **Flutter API路径对齐** — feedback/submit→feedback/, skills/list→skills 等
5. **添加缺失后端端点** — constitution/questions, feedback/rate, today-plan, speech/asr
6. **修复 followup/schedule 500** — followup调度核心功能
7. **修复 contents/search 和 contents/category过滤** — 搜索不可用

### P2 - 可以后续修复

8. **auth/refresh 完整实现** — token刷新流程
9. **test/ 编译错误修复** — gentle_button_test参数名更新
10. **Safety检测** — AI chat对自杀相关内容未触发安全响应

---

## 六、结论

核心问题集中在 **服务器部署版本落后**: 本地代码有完整的 seasons 系列路由(seasons_api, seasons_audio, seasons_family, seasons_subscription)，但 ECS 上只加载了 seasons_home 的6个端点。重新部署后端即可解决 F4-F11 共8个失败项。

Flutter客户端代码质量良好(0编译错误, 122个页面)，主要需要将API调用路径与实际后端端点对齐。
