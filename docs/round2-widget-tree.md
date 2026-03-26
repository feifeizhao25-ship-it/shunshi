# 顺时 ShunShi Widget Tree

## 主结构

```
MainPage (5 Tab)
├── HomeTab
│   ├── HomePage
│   │   ├── GreetingCard (问候卡片)
│   │   │   ├── Avatar
│   │   │   ├── GreetingText (早上好/下午好)
│   │   │   └── LifeStageBadge (阶段标签)
│   │   │
│   │   ├── SolarTermCard (节气卡片)
│   │   │   ├── SolarTermIcon (节气图)
│   │   │   ├── SolarTermName (惊蛰)
│   │   │   ├── SolarTermDate (2.5-3.5)
│   │   │   └── SolarTermTip (今日宜清淡)
│   │   │
│   │   ├── TodayInsightCard (今日洞察)
│   │   │   ├── InsightIcon
│   │   │   └── InsightText
│   │   │
│   │   ├── ThreeThingsCard (今日三件事)
│   │   │   ├── Thing1
│   │   │   ├── Thing2
│   │   │   └── Thing3
│   │   │
│   │   ├── AICareCard (AI关怀)
│   │   │   ├── CareIcon
│   │   │   ├── CareText
│   │   │   └── FollowUpButton
│   │   │
│   │   ├── HabitChecklist (习惯打卡)
│   │   │   ├── HabitItem (喝水)
│   │   │   ├── HabitItem (散步)
│   │   │   └── HabitItem (泡脚)
│   │   │
│   │   └── FamilyEntryCard (家庭入口)
│   │       ├── FamilyIcon
│   │       ├── FamilyCount (4人)
│   │       └── FamilyDigestPreview
│   │
│   └── ScrollView
│
├── ChatTab
│   ├── ChatPage
│   │   ├── ChatListPage (对话列表)
│   │   │   └── ConversationItem
│   │   │
│   │   └── ChatDetailPage (对话详情)
│   │       ├── AppBar
│   │       │   ├── BackButton
│   │       │   ├── ChatTitle (顺时)
│   │       │   └── VoiceButton
│   │       │
│   │       ├── MessageList
│   │       │   ├── UserMessage
│   │       │   │   └── ChatBubble (user)
│   │       │   │
│   │       │   └── AIMessage
│   │       │       ├── ChatBubble (ai)
│   │       │       ├── ContentCard (食疗/穴位/茶饮)
│   │       │       └── FollowUpChips
│   │       │
│   │       └── InputArea
│   │           ├── TextField
│   │           ├── QuickReplyChips
│   │           └── VoiceInputButton
│   │
│   └── [底部 5 Tab 固定]
│
├── WellnessTab
│   ├── WellnessPage
│   │   ├── SolarTermSection
│   │   │   ├── SectionHeader
│   │   │   └── SolarTermCard
│   │   │
│   │   ├── ConstitutionSection
│   │   │   ├── SectionHeader
│   │   │   └── ConstitutionCard
│   │   │
│   │   ├── ContentGridSection
│   │   │   ├── SectionHeader
│   │   │   ├── FoodCard
│   │   │   ├── TeaCard
│   │   │   └── AcupointCard
│   │   │
│   │   └── HabitsSection
│   │       ├── SectionHeader
│   │       └── HabitList
│   │
│   └── [详细页 - 见下方]
│
├── FamilyTab
│   ├── FamilyPage
│   │   ├── FamilyHeader
│   │   │   ├── FamilyAvatar
│   │   │   ├── FamilyName
│   │   │   └── MemberCount
│   │   │
│   │   ├── FamilyDigest (家庭动态)
│   │   │   └── DigestCard
│   │   │
│   │   ├── CareMessageList
│   │   │   └── CareMessageItem
│   │   │
│   │   └── FamilyMembers
│   │       └── MemberCard
│   │
│   └── [详细页 - 见下方]
│
└── ProfileTab
    ├── ProfilePage
    │   ├── ProfileHeader
    │   │   ├── Avatar
    │   │   ├── Name
    │   │   ├── LifeStageBadge
    │   │   └── SubscriptionBadge
    │   │
    │   ├── StatsSection
    │   │   ├── DaysCount
    │   │   ├── CareScore
    │   │   └── HabitStreak
    │   │
    │   ├── MenuSection
    │   │   ├── MemorySettings
    │   │   ├── NotificationSettings
    │   │   ├── PrivacySettings
    │   │   └── AppearanceSettings
    │   │
    │   ├── SubscriptionSection
    │   │   └── SubscriptionCard
    │   │
    │   └── FooterSection
    │       ├── HelpCenter
    │       ├── Feedback
    │       └── About
    │
    └── [设置详细页 - 见下方]
```

---

## 详细页面结构

### 对话模块

```
ChatDetailPage
├── MessageList
│   ├── UserMessageBubble
│   │   ├── Avatar (user)
│   │   ├── Bubble (right aligned)
│   │   └── Time
│   │
│   ├── AIMessageBubble
│   │   ├── Avatar (顺时)
│   │   ├── Bubble (left aligned)
│   │   ├── [ContentCards - 根据类型渲染]
│   │   │   ├── AcupointCard
│   │   │   │   ├── Title (足三里)
│   │   │   │   ├── Location
│   │   │   │   ├── Steps
│   │   │   │   ├── Duration
│   │   │   │   └── CTAs (查看详情/收藏)
│   │   │   │
│   │   │   ├── FoodCard
│   │   │   │   ├── Title (山药粥)
│   │   │   │   ├── Tags (健脾/养胃)
│   │   │   │   ├── Ingredients
│   │   │   │   ├── Steps
│   │   │   │   └── CTAs
│   │   │   │
│   │   │   ├── TeaCard
│   │   │   │   ├── Title (陈皮普洱)
│   │   │   │   ├── Benefits
│   │   │   │   ├── Brewing
│   │   │   │   └── CTAs
│   │   │   │
│   │   │   ├── SolarTermCard
│   │   │   │   ├── Title (惊蛰)
│   │   │   │   ├── Dates
│   │   │   │   ├── Eat
│   │   │   │   ├── Move
│   │   │   │   └── Sleep
│   │   │   │
│   │   │   ├── SleepCard
│   │   │   │   ├── Title
│   │   │   │   ├── Duration
│   │   │   │   └── Tips
│   │   │   │
│   │   │   └── NoteCard
│   │   │       ├── Title
│   │   │       └── Content
│   │   │
│   │   └── FollowUpChips
│   │       ├── Chip 1
│   │       ├── Chip 2
│   │       └── Chip 3
│   │
│   └── SafeModeCard (条件触发)
│       ├── Icon
│       ├── Title
│       ├── Message
│       └── ActionButtons
│
└── InputArea
    ├── ExpandedTextField
    │   ├── HintText
    │   └── MaxLines: 4
    │
    ├── QuickReplyChips (可收起)
    │   ├── 睡眠
    │   ├── 情绪
    │   ├── 饮食
    │   ├── 节气
    │   ├── 穴位
    │   └── 运动
    │
    └── ActionButtons
        ├── SendButton
        └── VoiceButton
```

### 养生模块

```
SolarTermDetailPage
├── HeroHeader
│   ├── BackgroundImage
│   ├── SolarTermName
│   ├── SolarTermDate
│   └── SeasonIcon
│
├── TabBar
│   ├── 概述
│   ├── 饮食
│   ├── 运动
│   └── 养生
│
├── TabContent
│   ├── OverviewTab
│   │   ├── SolarTermIntro
│   │   ├── ThreeThings (宜/忌/注意)
│   │   └── Proverb
│   │
│   ├── FoodTab
│   │   └── FoodList
│   │
│   ├── MoveTab
│   │   ├── MovementList
│   │   └── VideoPlayer (可选)
│   │
│   └── WellnessTab
│       ├── SleepSuggestion
│       ├── MoodSuggestion
│       └── DailyRoutine
│
└── ShareButton (分享海报)
```

```
ConstitutionTestPage
├── ProgressBar
│
├── QuestionCard
│   ├── QuestionNumber
│   ├── QuestionText
│   └── OptionsList
│       ├── Option 1 (完全不像)
│       ├── Option 2 (不太像)
│       ├── Option 3 (一般)
│       ├── Option 4 (比较像)
│       └── Option 5 (非常像)
│
└── NavigationButtons
    ├── Back
    └── Next
```

```
ConstitutionResultPage
├── ResultHeader
│   ├── ConstitutionType (阳虚质)
│   ├── ScoreBar
│   └── Description
│
├── CharacteristicList
│   ├── Item 1
│   ├── Item 2
│   └── Item 3
│
├── Suggestions
│   ├── DietSuggestion
│   ├── ExerciseSuggestion
│   ├── LifestyleSuggestion
│   └── EmotionSuggestion
│
├── DisclaimerBanner
│
└── ActionButtons
    ├── SaveResult
    └── Share
```

### 家庭模块

```
FamilyInvitePage
├── InviteCodeDisplay
│   ├── QRCode
│   └── CodeText (复制)
│
├── InviteLink
│   └── CopyLinkButton
│
├── SelectMembers
│   └── MemberTypeSelector
│       ├── 父母
│       ├── 配偶
│       └── 子女
│
└── SendInviteButton
```

```
CareMessagePage
├── CareCard
│   ├── SenderAvatar
│   ├── SenderName
│   ├── CareType (提醒/关怀/问候)
│   ├── MessageContent
│   └── Timestamp
│
├── QuickReplyChips
│   ├── 谢谢关心
│   ├── 我也很好
│   └── 回一个关怀
│
└── InputArea (自定义消息)
```

### 认证模块

```
LoginPage
├── Logo
│   ├── AppIcon
│   └── AppName (顺时)
│
├── WelcomeText
│
├── PhoneInput
│   ├── CountryCodePicker
│   └── PhoneTextField
│
├── VerifyCodeInput
│   ├── CodeTextField
│   └── SendCodeButton (倒计时)
│
├── LoginButton
│
├── OtherOptions
│   ├── WeChatLogin
│   ├── AppleLogin
│   └── TermsPrivacyLinks
│
└── SwitchToRegister
```

---

## 组件状态定义

### 加载态 (Loading)
- 骨架屏 (Skeleton)
- 圆形加载 (CircularProgress)
- 线性加载 (LinearProgressIndicator)

### 空态 (Empty)
- 空图标
- 空文案
- 引导操作按钮

### 错误态 (Error)
- 错误图标
- 错误描述
- 重试按钮

### 降级态 (Degraded)
- 部分功能可用
- 提示降级信息
- 引导升级

---

## 手势与动画

| 场景 | 手势 | 动画 |
|------|------|------|
| 卡片点击 | onTap | 透明度 0.7, 150ms |
| 卡片长按 | onLongPress | 震动反馈 |
| 下拉刷新 | onRefresh | 下拉指示器 |
| 上拉加载 | onLoadMore | 底部加载 |
| 列表滑动 | - | 惯性滚动 |
| Tab 切换 | onTap | 滑动过渡 300ms |
| 弹窗出现 | - | 向上滑入 250ms |
| Toast | - | 淡入淡出 200ms |
