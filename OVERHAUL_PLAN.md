# 顺时/SEASONS 大改造计划

## 目标
4个产品全部生产部署上线：
- android-cn（顺时 国内版 Android）
- ios-cn（顺时 国内版 iOS）
- android-global（SEASONS 国际版 Android）
- ios-global（SEASONS 国际版 iOS）

## 设计系统

### 色彩
- Primary: #144227 (墨绿)
- Secondary: #74593c (暖棕)
- Background: #FDF9F4 (宣纸米白)
- Surface: #F7F3EE
- Gold/Tertiary: #4C3605 / #E4C285
- Error: #BA1A1A

### 字体
- 标题: NotoSerifSC (中文) / serif
- 正文: Manrope (中英通用)
- 标签: Manrope tracking-widest uppercase

### 组件风格
- 卡片: 圆角 20-24px, 白底 + 微阴影
- 毛玻璃: BackdropFilter blur(20) + 白色半透明
- 导航栏: 毛玻璃底栏 + 圆角高亮选中项
- Bento Grid: 2-3列不等高

## 页面架构（10个核心页面）

### 主导航 — 4 Tab
1. **首页/十二时辰** — 时辰Hero + Bento行动 + AI毛玻璃 + 节气卡片
2. **社区/Community** — 搜索 + 筛选Tab(精选/动态/挑战/食疗) + Feed流 + FAB
3. **挑战/Achievements** — 成就勋章 + 进度 + 徽章
4. **我的/Profile** — 头像 + 积分/优惠券/收藏 + 功能列表 + 邀请Banner

### 二级页面
5. **设置** — 账号安全 + 通知开关 + 老年模式 + 清除缓存
6. **食疗详情** — Hero图 + AI洞察(毛玻璃) + 食材配比 + 步骤 + 营养
7. **功法详情** — 视频播放 + 呼吸节拍 + 步骤 + Bento要点
8. **家庭管理** — 成员卡片 + 季节养生建议 + 亲情提醒
9. **AI聊天** — 已有 chat_page.dart
10. **节气详情** — 已有 solar-term-detail

## 实施顺序

### Phase 1: 设计系统 & 导航框架（当前）
- [ ] 更新 theme.dart 完善 ShunShiColors/ShunShiTypography
- [ ] 改造 MainShell 底部导航为参考设计风格（4 tab: 十二时辰/社区/挑战/我的）
- [ ] 更新 app_router.dart 路由结构

### Phase 2: 核心页面改造
- [ ] 首页 home_page.dart（已完成初版）
- [ ] 社区页 community_page.dart
- [ ] 成就页 achievements_page.dart
- [ ] 个人中心 profile_page.dart

### Phase 3: 二级页面
- [ ] 设置页 settings_page.dart
- [ ] 食疗详情页 food_detail_page.dart
- [ ] 功法详情页 exercise_detail_page.dart
- [ ] 家庭管理页 family_page.dart

### Phase 4: 国际版适配
- [ ] android-global 英文文案 + Material 3 风格
- [ ] ios-global 英文文案 + Cupertino 风格
- [ ] iOS 国内版适配

### Phase 5: 生产部署
- [ ] Android 签名 + APK/AAB
- [ ] iOS Xcode 配置 + Archive
- [ ] 后端 API 对接测试
- [ ] App Store / Google Play 提审

## 国际版差异
| 维度 | 国内版(顺时) | 国际版(SEASONS) |
|------|-------------|----------------|
| 语言 | 中文 | 英文 |
| 养生体系 | 中医十二时辰 + 24节气 | 四季 Wellness |
| AI人设 | 养生顾问 | Calm Lifestyle Companion |
| 社区 | 养生圈 | Community |
| 签到 | 时辰打卡 | Daily Check-in |
| 底部导航 | 十二时辰/社区/挑战/我的 | Seasons/Community/Challenges/Profile |
