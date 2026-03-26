# SEASONS 国际版 — 生产差距分析
> 基于《SEASONS 国际版完整生产级开发与测试总文档》
> 分析日期: 2026-03-20

---

## 总体评估

| 维度 | 当前状态 | 差距 |
|------|---------|------|
| 核心功能 | 75% | 中 |
| Onboarding | 50% | 高 |
| 订阅/Paywall | 40% | 高 |
| 音频系统 | 10% | 极高 |
| 安全/合规 | 60% | 中 |
| 本地化/半球 | 20% | 极高 |
| 分享增长 | 10% | 极高 |
| 指标体系 | 0% | 极高 |

---

## 逐项差距分析

### ✅ 已具备（无需改动）
- Home 页面结构和 UI
- Seasons 四季内容（但需增加半球支持）
- Library 页面
- Reflection 模块
- AI Chat（已升级为真实 LLM）
- 订阅页面 UI（Stripe）
- Profile/Settings 页面
- 设计系统（颜色/字体/间距/动画）
- GoRouter 导航

---

### 🔴 高优先级

#### 1. Onboarding 重设计
**PRD 要求 vs 现状:**

| PRD Step | 现状 |
|----------|------|
| Step 1: How have you been feeling? (calm/stressed/tired/overwhelmed/curious) | ❌ 缺失 |
| Step 2: What would you like help with? (sleep/unwind/calm/ritual/reflect) | ✅ 存在 (goal selection) |
| Step 3: Life stage (student/working/professional/parent/midlife/retired) | ⚠️ 存在但不匹配 |
| Step 4: When would you like support? (morning/afternoon/evening) | ✅ 存在 |
| Step 5: How should SEASONS feel? (minimal/gentle/more active) | ❌ 缺失 |
| 输出: 第一份 Daily Insight | ❌ 缺失 |

**缺口:**
- 没有"情绪状态"采集
- 没有"支持风格"选择
- 完成时没有生成第一份 insight
- 没有保存到用户 profile

#### 2. Home API 化（消除硬编码）
**现状:** HomeProvider 使用硬编码的 `_getDailyInsight()` 和 `_getSuggestions()`

**需要:**
- 连接后端 `/ai/daily-insight` 端点
- 连接后端推荐 API
- 显示真实的 hemisphere-aware 季节
- onboarding 完成后生成第一份 insight

#### 3. 半球感知引擎
**现状:** `_getCurrentSeason()` 仅用北半球逻辑

**需要:**
- 支持 `hemisphere` 参数 (north/south)
- 南北半球季节相反
- 用户 profile 存储 hemisphere
- API 端点返回 hemisphere-aware 内容

#### 4. 音频系统
**现状:** `audio_player_page.dart` 存在但:
- 没有音频文件
- 没有音频内容 API
- 没有 3/5/8/15 min 音频分类
- 没有推荐音频逻辑

**需要:**
- 49+ 音频内容数据
- 音频播放 UI 完善
- 后端音频内容 API
- 推荐音频端点

#### 5. Memory/Privacy 控制
**PRD 要求:**
- Memory on/off toggle
- Clear all memory
- Export data
- Delete account
- AI disclosure
- Safety / support page

**现状:** Settings 有基础项，但缺少:
- Memory toggle（前端）
- Clear memory（前端 + 后端）
- Export data（前后端）
- Delete account（前后端）
- AI disclosure 弹窗

---

### 🟡 中优先级

#### 6. 分享与增长素材系统
**现状:** 完全没有分享功能

**需要:**
- 可分享的反思卡片（图片生成）
- 分享到 Instagram Stories/Twitter/Pinterest
- 季节内容分享
- App Store 分享链接

#### 7. 订阅实验框架
**现状:** 有固定价格，无实验机制

**需要:**
- A/B paywall 测试
- Trial 逻辑
- Intro offer 支持
- Offer code 机制
- 年付/月付切换

#### 8. 指标/Analytics 系统
**现状:** 有基础 analytics.dart，但:
- 没有事件 taxonomy
- 没有 funnel tracking
- 没有 experiment tracking
- 没有 AI cost tracking

#### 9. 合规与透明
**需要:**
- AI disclosure 首次弹窗
- Privacy policy 链接
- Terms of Service 链接
- Crisis support page
- Not medical advice 提示

#### 10. 客服与支持
**现状:** 没有 Help Center

**需要:**
- In-app support path
- Trust FAQ page
- Bug reporting
- Subscription support

---

### 🟢 低优先级（后续）

#### 11. 多语言/地区
- North America / UK / EU / Australia / Southeast Asia
- Locale-aware copy
- Region-aware notification timing

#### 12. Family Plan 仪表盘
- 4 seats
- Shared subscription management

#### 13. App Store Assets
- Screenshot system
- Preview videos

---

## 实施计划

### 第一轮（现在执行）
1. 重做 Onboarding（PRD 5步 + 第一 insight）
2. Home API 化
3. 半球感知引擎
4. Memory/Privacy 控制完善
5. AI Disclosure 弹窗
6. Backend: Home dashboard API
7. Backend: User profile 完善

### 第二轮
1. 音频系统
2. 分享素材系统
3. Analytics taxonomy
4. Subscription A/B 框架

### 第三轮
1. 多地区支持
2. App Store assets
3. Help Center
4. Family dashboard
