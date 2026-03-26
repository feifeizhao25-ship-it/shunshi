# 顺时 Widget Tree + Design System（可直接开工落地）

---

## 一、Widget Tree：全站 UI 组件树

### 1.1 App 根结构

```dart
// lib/app/app.dart

class ShunShiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => UserContextProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp.router(
        title: '顺时',
        theme: ShunShiTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => HomeTodayHubPage()),
          GoRoute(path: '/chat', builder: (_, __) => ChatPage()),
          GoRoute(path: '/wellness', builder: (_, __) => WellnessHubPage()),
          GoRoute(path: '/family', builder: (_, __) => FamilyHubPage()),
          GoRoute(path: '/me', builder: (_, __) => MePage()),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(children: [...], index: currentTab),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), label: '对话'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), label: '养生'),
          NavigationDestination(icon: Icon(Icons.family_restroom), label: '家庭'),
          NavigationDestination(icon: Icon(Icons.person_outlined), label: '我的'),
        ],
      ),
    );
  }
}
```

---

## 二、首页 Tab

### 2.1 HomeTodayHubPage（首页总览）

```dart
class HomeTodayHubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShunShiScaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Banner：问候 + 节气
          SliverToBoxAdapter(child: _buildGreetingBanner(context)),
          
          // 2. 今日节律卡片
          SliverToBoxAdapter(child: RhythmSummaryCard(
            insight: '最近你睡得越来越晚，身体会吃不消哦',
            actions: ['7:30 起床', '23:00 前睡觉', '睡前1小时不看手机'],
          )),
          
          // 3. AI 关怀一句
          SliverToBoxAdapter(child: CareMessageCard(
            message: '今天过得怎么样？',
          )),
          
          // 4. 今日养生
          SliverToBoxAdapter(child: TodayWellnessCard()),
          
          // 5. 习惯快速打卡
          SliverToBoxAdapter(child: HabitQuickGrid()),
          
          // 6. 家庭动态（若绑定）
          if (user.familyBound) SliverToBoxAdapter(child: FamilyDigestMiniCard()),
          
          // 7. 底部进度
          SliverToBoxAdapter(child: SoftProgressFooter(completed: 2, total: 3)),
        ],
      ),
    );
  }
}
```

### 2.2 RhythmSummaryCard（今日节律卡片）

```dart
class RhythmSummaryCard extends StatelessWidget {
  final String insight;
  final List<String> actions;
  
  @override
  Widget build(BuildContext context) {
    return SSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(ShunShiIcons.rhythm, color: ShunShiColors.primary),
            SizedBox(width: 8),
            Text('今日节律', style: ShunShiTypography.subtitle),
          ]),
          SizedBox(height: 16),
          Text('💡 $insight', style: ShunShiTypography.body),
          SizedBox(height: 16),
          ...actions.asMap().entries.map((e) => 
            _buildActionItem(e.key + 1, e.value)
          ),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: SSButton.primary(label: '加入计划')),
            SizedBox(width: 8),
            Expanded(child: SSButton.secondary(label: '开始计时')),
          ]),
        ],
      ),
    );
  }
}
```

---

## 三、对话 Tab

### 3.1 ChatPage（主聊天页）

```dart
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Text('🌱 '), Text('顺时'),
          Container(padding: EdgeInsets.symmetric(4,2), child: Text('在线')),
        ]),
      ),
      body: Column(children: [
        // 快捷 chips
        _buildQuickChips(),
        
        // 消息列表
        Expanded(child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, i) => _buildMessage(messages[i]),
        )),
        
        // 输入框
        _buildInputBar(),
      ]),
    );
  }
  
  Widget _buildQuickChips() {
    final chips = ['睡眠', '情绪', '饮食', '节气', '穴位', '办公室'];
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        itemBuilder: (context, i) => SSChip(label: chips[i]),
        separatorBuilder: (_,__) => SizedBox(width: 8),
      ),
    );
  }
  
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(children: [
        IconButton(icon: Icon(Icons.mic)),
        IconButton(icon: Icon(Icons.image)),
        Expanded(child: TextField(
          decoration: InputDecoration(hintText: '输入想和顺时聊的...'),
        )),
        IconButton(icon: Icon(Icons.send)),
      ]),
    );
  }
}
```

### 3.2 AIMessageBubble

```dart
class AIMessageBubble extends StatelessWidget {
  final ChatMessage message;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, child: Text('🌱')),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShunShiColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(message.content),
              ),
              if (message.cards != null)
                ...message.cards!.map((card) => 
                  ContentCardWidget(card: card)
                ),
            ],
          )),
        ],
      ),
    );
  }
}
```

---

## 四、养生 Tab

### 4.1 WellnessHubPage

```dart
class WellnessHubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShunShiScaffold(
      title: '养生',
      body: CustomScrollView(slivers: [
        // 搜索栏
        SliverToBoxAdapter(child: _buildSearchBar()),
        
        // 分类网格
        SliverToBoxAdapter(child: _buildCategoryGrid()),
        
        // 今日推荐
        SliverToBoxAdapter(child: _buildTodayRecommended()),
      ]),
    );
  }
  
  Widget _buildCategoryGrid() {
    final categories = [
      ('节气', Icons.wb_sunny),
      ('体质', Icons.person),
      ('食疗', Icons.restaurant),
      ('茶饮', Icons.local_cafe),
      ('穴位', Icons.self_improvement),
      ('运动', Icons.directions_run),
      ('睡眠', Icons.bedtime),
      ('情绪', Icons.mood),
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) => Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: ShunShiColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(categories[i].$2, color: ShunShiColors.primary),
        ),
        SizedBox(height: 4),
        Text(categories[i].$1, style: ShunShiTypography.caption),
      ]),
    );
  }
}
```

---

## 五、家庭 Tab

### 5.1 FamilyHubPage

```dart
class FamilyHubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShunShiScaffold(
      title: '家庭',
      actions: [IconButton(icon: Icon(Icons.person_add))],
      body: CustomScrollView(slivers: [
        // 绑定入口
        SliverToBoxAdapter(child: _buildBindPrompt()),
        
        // 成员列表
        SliverList(delegate: SliverChildBuilderDelegate(
          (context, i) => _buildMemberCard(members[i]),
          childCount: members.length,
        )),
      ]),
    );
  }
  
  Widget _buildBindPrompt() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          ShunShiColors.primary, ShunShiColors.primaryLight,
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Text('绑定家人', style: ShunShiTypography.titleWhite),
        SizedBox(height: 8),
        Text('让家人也感受到你的关怀', style: ShunShiTypography.bodyWhite),
        SizedBox(height: 16),
        SSButton.primary(label: '绑定家人'),
      ]),
    );
  }
  
  Widget _buildMemberCard(member) {
    return SSCard(child: ListTile(
      leading: CircleAvatar(child: Text(member.name[0])),
      title: Text(member.name),
      subtitle: Row(children: [
        Icon(member.status=='stable'?Icons.check_circle:Icons.warning,
          size: 14, color: member.status=='stable'?Colors.green:Colors.orange),
        SizedBox(width: 4),
        Text(member.status=='stable'?'状态稳定':'需要关注'),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: Icon(Icons.favorite_outline)),
        IconButton(icon: Icon(Icons.chevron_right)),
      ]),
    ));
  }
}
```

---

## 六、我的 Tab

### 6.1 MePage

```dart
class MePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShunShiScaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildProfileHeader()),
        SliverToBoxAdapter(child: _buildMenuSection()),
      ]),
    );
  }
  
  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(children: [
        CircleAvatar(radius: 48, child: Text('🌱', style: TextStyle(fontSize: 36))),
        SizedBox(height: 16),
        Text(user.name, style: ShunShiTypography.title),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('免费版', style: TextStyle(color: Colors.green)),
        ),
      ]),
    );
  }
  
  Widget _buildMenuSection() {
    final menus = [
      ('会员', Icons.crown),
      ('养生档案', Icons.person),
      ('我的习惯', Icons.check_circle),
      ('养生日记', Icons.book),
      ('收藏', Icons.favorite),
      ('提醒设置', Icons.notifications),
      ('隐私与数据', Icons.security),
      ('帮助与反馈', Icons.help),
    ];
    
    return Column(children: menus.map((m) => ListTile(
      leading: Icon(m.$2),
      title: Text(m.$1),
      trailing: Icon(Icons.chevron_right),
    )).toList());
  }
}
```

---

## 七、Design System 设计系统

### 7.1 Design Tokens

```dart
// 颜色
class ShunShiColors {
  static const primary = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFF81C784);
  static const secondary = Color(0xFFFF9800);
  static const background = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const success = Color(0xFF66BB6A);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE57373);
}

// 字体
class ShunShiTypography {
  static const display = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
  static const title = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const subtitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 14, height: 1.5);
  static const caption = TextStyle(fontSize: 12, color: ShunShiColors.textSecondary);
}

// 间距
class ShunShiSpacing {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
}

// 圆角
class ShunShiRadius {
  static const card = 16.0, button = 12.0, chip = 999.0;
}
```

### 7.2 通用组件

```dart
// SSCard
class SSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(ShunShiRadius.card),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: child,
    );
  }
}

// SSButton
class SSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? ShunShiColors.primary : Colors.transparent,
        foregroundColor: isPrimary ? Colors.white : ShunShiColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShunShiRadius.button),
          side: isPrimary ? BorderSide.none : BorderSide(color: ShunShiColors.primary),
        ),
      ),
      child: Text(label),
    );
  }
}

// SSChip
class SSChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: ShunShiColors.surface,
      side: BorderSide(color: ShunShiColors.primary.withOpacity(0.3)),
    );
  }
}
```

### 7.3 ContentCard 组件

```dart
class ContentCardWidget extends StatelessWidget {
  final ContentCard card;
  
  @override
  Widget build(BuildContext context) {
    return SSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_getIcon(card.type), style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(child: Text(card.title, style: ShunShiTypography.subtitle)),
          ]),
          if (card.subtitle != null) ...[
            SizedBox(height: 4),
            Text(card.subtitle!, style: ShunShiTypography.caption),
          ],
          if (card.steps != null) ...[
            SizedBox(height: 12),
            ...card.steps!.take(4).map((s) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: ShunShiTypography.caption),
                  Expanded(child: Text(s, style: ShunShiTypography.body)),
                ],
              ),
            )),
          ],
          if (card.contraindications != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ShunShiColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('禁忌: ${card.contraindications!.join(", ")}',
                style: ShunShiTypography.caption.copyWith(color: ShunShiColors.warning)),
            ),
          ],
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: SSButton.primary(label: '开始计时')),
            SizedBox(width: 8),
            SSButton.secondary(label: '收藏'),
          ]),
        ],
      ),
    );
  }
  
  String _getIcon(String type) {
    return {'food':'🍵','tea':'☕','acupoint':'💆','movement':'🏃','sleep':'🌙','solar_term':'🌞'}[type] ?? '📝';
  }
}
```

---

## 八、设计原则（写进产品宪章）

1. **不焦虑**: 不做评分榜单，不使用"危险/警告"措辞
2. **一屏价值**: 首页/方案页一屏读完
3. **温和克制**: AI只说观察与建议，不下结论
4. **可忽略**: 跟进/关怀永远可忽略
5. **可达性**: 老年友好，语音优先，大字号不破版

---

## 九、总结

```
Widget Tree = 70+ 页面组件树
Design System = 统一组件库
- SSCard / SSButton / SSChip
- ShunShiColors / ShunShiTypography
- ShunShiSpacing / ShunShiRadius

落地规则：
- 5 Tab 永远不变
- 生命周期只改模块顺序/权重
- 组件统一封装，Theme 只改 token
```

---

## 顺时完整文档清单

| # | 文档 | 内容 |
|---|------|------|
| 1 | LIFE_STAGE_ENGINE | 生命周期 |
| 2 | ULTIMATE_FEATURE_MAP | 10年路线 |
| 3 | TECHNICAL_ARCHITECTURE | 技术架构 |
| 4 | UI_SYSTEM | UI设计 |
| 5 | SKILLS_SYSTEM | Skills体系 |
| 6 | SKILLS_IMPLEMENTATION | Skills实施 |
| 7 | AI_TEST_ITERATION | 测试迭代 |
| 8 | AI_EVALUATION_SYSTEM | 自动化测试 |
| 9 | AI_ROUTER_ARCHITECTURE | Router代码 |
| 10 | GAP_ANALYSIS | 补全清单 |
| 11 | MOAT_STRUCTURE | 护城河 |
| 12 | FINAL_UI_STRUCTURE | 最终UI |
| 13 | DATABASE_STRUCTURE | 数据库SQL |
| 14 | UI_WIREFRAMES | 线框图 |
| 15 | WIDGET_TREE_DESIGN_SYSTEM | Widget Tree + Design System |

---

**顺时已完成从概念到可开发落地的完整产品设计，覆盖全部 UI 组件树与 Design System。**
