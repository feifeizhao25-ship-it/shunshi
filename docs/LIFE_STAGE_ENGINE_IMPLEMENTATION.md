# 顺时 Life Stage Engine 实施计划

> 从概念到产品：18-80岁用户生命周期系统真正落地

---

## 一、数据库更新

### 1.1 User 表新增字段

```sql
-- users 表新增字段
ALTER TABLE users ADD COLUMN life_stage VARCHAR(20) DEFAULT 'exploration';
ALTER TABLE users ADD COLUMN age_group VARCHAR(20) DEFAULT 'young_adult';
ALTER TABLE users ADD COLUMN family_role VARCHAR(20) DEFAULT 'self';
ALTER TABLE users ADD COLUMN birth_date DATE;
ALTER TABLE users ADD COLUMN onboarding_age INT;  -- 用户首次使用时填写的年龄

-- 家庭关系表
CREATE TABLE family_relations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  relation_type VARCHAR(20),  -- parent/child/spouse
  related_user_id UUID REFERENCES users(id),
  care_level VARCHAR(20) DEFAULT 'normal',  -- normal/intensive
  notification_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 1.2 Prisma Schema

```prisma
// schema.prisma

model User {
  id              String   @id @default(cuid())
  lifeStage       LifeStage @default(EXPLORATION)
  ageGroup        AgeGroup   @default(YOUNG_ADULT)
  familyRole      FamilyRole @default(SELF)
  birthDate       DateTime?
  onboardingAge   Int?
  
  familyRelations FamilyRelation[] @relation("userRelations")
  relatedTo       FamilyRelation[] @relation("relatedTo")
  
  // ... existing fields
}

enum LifeStage {
  EXPLORATION   // 18-25 探索期
  STRESS        // 25-40 压力期
  HEALTH        // 40-60 健康期
  COMPANIONSHIP // 60+ 陪伴期
}

enum AgeGroup {
  YOUNG_ADULT   // 18-25
  MID_ADULT     // 26-40
  MIDDLE_AGED   // 41-60
  SENIOR        // 61-80
  ELDERLY       // 80+
}

enum FamilyRole {
  SELF
  PARENT
  CHILD
  SPOUSE
}

model FamilyRelation {
  id              String   @id @default(cuid())
  userId          String
  user            User     @relation("userRelations", fields: [userId], references: [id])
  relatedUserId   String
  relatedUser     User     @relation("relatedTo", fields: [relatedUserId], references: [id])
  relationType   String   // parent/child/spouse
  careLevel      String   @default("normal")
  notificationEnabled Boolean @default(true)
  
  createdAt       DateTime @default(now())
}
```

---

## 二、后端 API

### 2.1 用户阶段识别服务

```typescript
// app/services/life-stage.engine.ts

import { User, LifeStage, AgeGroup } from '@prisma/client';

export class LifeStageEngine {
  
  /**
   * 根据年龄计算用户阶段
   */
  static calculateLifeStage(age: number): LifeStage {
    if (age < 25) return 'EXPLORATION';
    if (age < 40) return 'STRESS';
    if (age < 60) return 'HEALTH';
    return 'COMPANIONSHIP';
  }
  
  /**
   * 根据年龄计算年龄组
   */
  static calculateAgeGroup(age: number): AgeGroup {
    if (age <= 25) return 'YOUNG_ADULT';
    if (age <= 40) return 'MID_ADULT';
    if (age <= 60) return 'MIDDLE_AGED';
    if (age <= 80) return 'SENIOR';
    return 'ELDERLY';
  }
  
  /**
   * 获取用户配置
   */
  static getStageConfig(lifeStage: LifeStage) {
    const configs = {
      EXPLORATION: {
        name: '探索阶段',
        careLevel: 'LIGHT',
        maxDailyContacts: 2,
        quietHours: { start: '09:00', end: '18:00' },
        features: ['sleep_tracking', 'emotion_chat', 'circadian'],
        homeModules: ['today_rhythm', 'chat', 'sleep'],
        aiTone: '活泼',
        pushStrategy: 'minimal',  // 一天最多1条
      },
      STRESS: {
        name: '压力阶段',
        careLevel: 'MEDIUM',
        maxDailyContacts: 3,
        quietHours: { start: '09:00', end: '20:00' },
        features: ['health_plan', 'weekly_summary', 'emotion_log', 'stress_relief', 'deep_context'],
        homeModules: ['today_wellness', 'chat', 'health_trends'],
        aiTone: '温暖',
        pushStrategy: 'balanced',  // 一天2-3条
      },
      HEALTH: {
        name: '健康阶段',
        careLevel: 'HEAVY',
        maxDailyContacts: 4,
        quietHours: { start: '07:00', end: '22:00' },
        features: ['constitution调理', 'solar_terms', 'diet_therapy', 'acupoint'],
        homeModules: ['solar_terms', 'constitution', 'diet_therapy'],
        aiTone: '专业',
        pushStrategy: 'active',  // 一天3-4条
      },
      COMPANIONSHIP: {
        name: '陪伴阶段',
        careLevel: 'INTENSIVE',
        maxDailyContacts: 5,
        quietHours: { start: '21:00', end: '07:00' },
        features: ['daily_chat', 'simple_advice', 'emotional_support', 'medication_reminder'],
        homeModules: ['chat', 'daily_advice', 'voice'],
        aiTone: '耐心',
        pushStrategy: 'intensive',  // 多次主动关怀
      },
    };
    
    return configs[lifeStage];
  }
}
```

### 2.2 AI Router 升级

```typescript
// app/services/ai-router.ts

interface AIRequest {
  userId: string;
  message: string;
  context?: {
    lifeStage: LifeStage;
    ageGroup: AgeGroup;
    familyRole: FamilyRole;
    recentEmotions?: string[];
    sleepTrend?: string;
    healthData?: any;
  };
}

interface AIResponse {
  content: string;
  actions?: AIAction[];
  suggestedModules?: string[];
}

class AIRouter {
  
  async route(request: AIRequest): Promise<AIResponse> {
    const { lifeStage, ageGroup } = request.context;
    
    // 1. 根据 lifeStage 选择 AI 角色
    const aiPersona = this.getPersona(lifeStage);
    
    // 2. 根据 ageGroup 调整回答策略
    const responseStrategy = this.getStrategy(ageGroup);
    
    // 3. 构建增强 prompt
    const enhancedPrompt = this.buildPrompt(request, aiPersona, responseStrategy);
    
    // 4. 调用 AI
    const content = await this.callAI(enhancedPrompt);
    
    // 5. 根据阶段返回推荐模块
    const suggestedModules = this.getSuggestedModules(lifeStage, request.message);
    
    return {
      content,
      suggestedModules,
    };
  }
  
  private getPersona(lifeStage: LifeStage) {
    const personas = {
      EXPLORATION: {
        name: '小顺',
        description: '年轻活力的生活节律助手',
        traits: ['活泼', '简短', '轻松'],
        example: '熬夜伤身体哦~早点睡吧！',
      },
      STRESS: {
        name: '顺时',
        description: '温暖的健康顾问',
        traits: ['温暖', '关心', '实用'],
        example: '听起来你最近压力很大。先深呼吸三次？',
      },
      HEALTH: {
        name: '顺时顾问',
        description: '专业的养生专家',
        traits: ['专业', '细致', '系统'],
        example: '根据您的体质，建议调理方案如下...',
      },
      COMPANIONSHIP: {
        name: '顺时陪伴',
        description: '耐心的生活伴侣',
        traits: ['耐心', '简单', '关怀'],
        example: '今天天气不错，可以出去走走。记得按时吃药。',
      },
    };
    return personas[lifeStage];
  }
  
  private getStrategy(ageGroup: AgeGroup) {
    const strategies = {
      YOUNG_ADULT: {
        responseLength: '短',
        format: '轻松',
        includeEmoji: true,
      },
      MID_ADULT: {
        responseLength: '中',
        format: '实用',
        includeEmoji: false,
      },
      MIDDLE_AGED: {
        responseLength: '详尽',
        format: '专业',
        includeReferences: true,
      },
      SENIOR: {
        responseLength: '短',
        format: '简单',
        preferVoice: true,
      },
      ELDERLY: {
        responseLength: '极简',
        format: '语音优先',
        largeFont: true,
      },
    };
    return strategies[ageGroup];
  }
  
  private getSuggestedModules(lifeStage: LifeStage, message: string): string[] {
    // 根据用户消息和阶段推荐功能模块
    const suggestions = {
      EXPLORATION: ['sleep', 'emotion', 'circadian'],
      STRESS: ['health_plan', 'emotion_log', 'weekly_summary'],
      HEALTH: ['constitution', 'solar_terms', 'diet_therapy'],
      COMPANIONSHIP: ['chat', 'medication', 'voice'],
    };
    
    // 简单的关键词匹配
    const keywords = {
      sleep: ['睡', '失眠', '熬夜', '困'],
      emotion: ['心情', '烦', '压力', '焦虑'],
      health_plan: ['健康', '计划', '体检'],
      constitution: ['体质', '调理'],
      solar_terms: ['节气', '养生'],
      diet_therapy: ['食疗', '饮食', '吃什么'],
      medication: ['药', '服用'],
    };
    
    const result = [];
    for (const [module, words] of Object.entries(keywords)) {
      if (words.some(w => message.includes(w))) {
        result.push(module);
      }
    }
    
    return result.length > 0 ? result : suggestions[lifeStage];
  }
}
```

---

## 三、Flutter 动态首页

### 3.1 首页模块配置

```dart
// lib/models/home_module.dart

enum LifeStage { exploration, stress, health, companionship }

enum AgeGroup { youngAdult, midAdult, middleAged, senior, elderly }

class HomeModule {
  final String id;
  final String title;
  final String icon;
  final ModuleType type;
  final int priority;
  
  static List<HomeModule> getModulesForStage(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return [
          HomeModule(id: 'today_rhythm', title: '今日节律', icon: '🌱', type: ModuleType.rhythm, priority: 1),
          HomeModule(id: 'chat', title: '聊天', icon: '💬', type: ModuleType.chat, priority: 2),
          HomeModule(id: 'sleep', title: '睡眠', icon: '🌙', type: ModuleType.sleep, priority: 3),
        ];
      case LifeStage.stress:
        return [
          HomeModule(id: 'today_wellness', title: '今日养生', icon: '✨', type: ModuleType.wellness, priority: 1),
          HomeModule(id: 'chat', title: '聊天', icon: '💬', type: ModuleType.chat, priority: 2),
          HomeModule(id: 'health_trends', title: '健康趋势', icon: '📈', type: ModuleType.trends, priority: 3),
        ];
      case LifeStage.health:
        return [
          HomeModule(id: 'solar_terms', title: '节气养生', icon: '🌞', type: ModuleType.solarTerms, priority: 1),
          HomeModule(id: 'constitution', title: '体质调理', icon: '🔄', type: ModuleType.constitution, priority: 2),
          HomeModule(id: 'diet_therapy', title: '食疗方案', icon: '🍵', type: ModuleType.diet, priority: 3),
        ];
      case LifeStage.companionship:
        return [
          HomeModule(id: 'chat', title: '聊天', icon: '💬', type: ModuleType.chat, priority: 1),
          HomeModule(id: 'daily_advice', title: '每日建议', icon: '📝', type: ModuleType.advice, priority: 2),
          HomeModule(id: 'voice', title: '语音', icon: '🎤', type: ModuleType.voice, priority: 3),
        ];
    }
  }
}
```

### 3.2 动态首页 Widget

```dart
// lib/screens/home_screen.dart

class HomeScreen extends StatelessWidget {
  final LifeStage lifeStage;
  final AgeGroup ageGroup;
  
  @override
  Widget build(BuildContext context) {
    final modules = HomeModule.getModulesForStage(lifeStage);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting(lifeStage)),
        actions: [
          if (lifeStage == LifeStage.companionship)
            IconButton(icon: Icon(Icons.volume_up), onPressed: _openVoice),
        ],
      ),
      body: ListView.builder(
        itemCount: modules.length,
        itemBuilder: (context, index) {
          return _buildModuleCard(modules[index], context);
        },
      ),
    );
  }
  
  String _getGreeting(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return '今天过得怎么样？';
      case LifeStage.stress:
        return '辛苦了，喝杯茶休息一下';
      case LifeStage.health:
        return '今日养生建议';
      case LifeStage.companionship:
        return '我在陪你';
    }
  }
  
  Widget _buildModuleCard(HomeModule module, BuildContext context) {
    // 根据模块类型和年龄组渲染不同样式的卡片
    final cardStyle = _getCardStyle(ageGroup);
    
    return Card(
      margin: EdgeInsets.all(cardStyle.margin),
      child: Container(
        padding: EdgeInsets.all(cardStyle.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(module.icon, style: TextStyle(fontSize: cardStyle.iconSize)),
                SizedBox(width: 8),
                Text(
                  module.title,
                  style: TextStyle(
                    fontSize: cardStyle.titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildModuleContent(module, cardStyle),
          ],
        ),
      ),
    );
  }
  
  CardStyle _getCardStyle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.youngAdult:
        return CardStyle(margin: 12, padding: 16, iconSize: 24, titleSize: 18, contentSize: 14);
      case AgeGroup.midAdult:
        return CardStyle(margin: 12, padding: 16, iconSize: 24, titleSize: 18, contentSize: 14);
      case AgeGroup.middleAged:
        return CardStyle(margin: 12, padding: 20, iconSize: 28, titleSize: 20, contentSize: 16);
      case AgeGroup.senior:
      case AgeGroup.elderly:
        return CardStyle(margin: 16, padding: 24, iconSize: 32, titleSize: 24, contentSize: 18);
    }
  }
}

class CardStyle {
  final double margin;
  final double padding;
  final double iconSize;
  final double titleSize;
  final double contentSize;
  
  CardStyle({
    required this.margin,
    required this.padding,
    required this.iconSize,
    required this.titleSize,
    required this.contentSize,
  });
}
```

---

## 四、家庭系统

### 4.1 家庭关系服务

```typescript
// app/services/family.service.ts

interface FamilyMember {
  userId: string;
  name: string;
  relation: 'parent' | 'child' | 'spouse';
  lifeStage: LifeStage;
  healthStatus: string;
  lastActive: Date;
  careLevel: 'normal' | 'intensive';
}

class FamilyService {
  
  /**
   * 绑定家庭成员
   */
  async bindFamilyMember(
    userId: string,
    relatedUserId: string,
    relation: 'parent' | 'child' | 'spouse'
  ): Promise<FamilyRelation> {
    // 验证对方同意
    // 创建关系
    return prisma.familyRelation.create({
      data: {
        userId,
        relatedUserId,
        relationType: relation,
      },
    });
  }
  
  /**
   * 获取家庭成员健康状态
   */
  async getFamilyHealthStatus(userId: string): Promise<FamilyMember[]> {
    const relations = await prisma.familyRelation.findMany({
      where: { userId },
      include: { relatedUser: true },
    });
    
    return relations.map(r => ({
      userId: r.relatedUserId,
      name: r.relatedUser.name,
      relation: r.relationType,
      lifeStage: r.relatedUser.lifeStage,
      healthStatus: r.relatedUser.healthStatus,
      lastActive: r.relatedUser.lastActive,
      careLevel: r.careLevel,
    }));
  }
  
  /**
   * 发送关怀提醒
   */
  async sendCareReminder(parentId: string, childId: string, message: string) {
    // 子女端推送通知
    await this.sendPushNotification(childId, {
      title: '关怀提醒',
      body: message,
      data: { type: 'care_reminder', parentId },
    });
  }
  
  /**
   * 获取需要关注的家庭成员
   */
  async getFamilyMembersNeedingAttention(userId: string): Promise<FamilyMember[]> {
    const members = await this.getFamilyHealthStatus(userId);
    
    return members.filter(m => {
      // 7天未活跃
      const daysSinceActive = (Date.now() - m.lastActive.getTime()) / (1000 * 60 * 60 * 24);
      return daysSinceActive > 7 || m.careLevel === 'intensive';
    });
  }
}
```

### 4.2 Flutter 家庭页面

```dart
// lib/screens/family_screen.dart

class FamilyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('家庭健康')),
      body: FutureBuilder<List<FamilyMember>>(
        future: FamilyService().getFamilyHealthStatus(currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final members = snapshot.data;
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              return _buildFamilyMemberCard(members[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBindDialog,
        child: Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildFamilyMemberCard(FamilyMember member) {
    final statusColor = _getStatusColor(member.healthStatus);
    final statusIcon = _getStatusIcon(member.lifeStage);
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(statusIcon),
        ),
        title: Text(member.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getRelationText(member.relation)),
            Text(
              _getActivityText(member.lastActive),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: member.careLevel == 'intensive'
            ? Icon(Icons.warning, color: Colors.orange)
            : null,
        onTap: () => _showMemberDetail(member),
      ),
    );
  }
}
```

---

## 五、完整版提示词

### 5.1 AI 角色提示词

```markdown
你是顺时 AI养生陪伴助手。

根据用户的 life_stage，你的角色和回答方式如下：

## EXPLORATION（18-25岁探索阶段）
- 角色：年轻活力的生活节律助手"小顺"
- 语气：活泼、轻松、简短
- 特点：回答要简短，多用emoji，不说教
- 示例："熬夜伤身体哦~早点睡吧！"

## STRESS（25-40岁压力阶段）
- 角色：温暖的健康顾问"顺时"
- 语气：温暖、关心、实用
- 特点：理解用户压力，提供实用建议
- 示例："听起来你最近压力很大。先深呼吸三次？"

## HEALTH（40-60岁健康阶段）
- 角色：专业的养生顾问
- 语气：专业、细致、系统
- 特点：提供完整的调理方案，引经据典
- 示例："根据您的体质，建议调理方案如下..."

## COMPANIONSHIP（60+岁陪伴阶段）
- 角色：耐心的生活伴侣
- 语气：耐心、简单、关怀
- 特点：语速慢（文字简短），语音优先，避免复杂操作
- 示例："今天天气不错，可以出去走走。记得按时吃药。"
```

### 5.2 系统提示词

```markdown
# 顺时 AI 核心系统提示词

## 身份
你是顺时，一个 AI 养生陪伴助手。你的目标是通过智慧和关怀，让用户的每一天都更加健康、舒适。

## 用户理解
你需要理解并适应不同年龄段用户的需求：

### 18-25岁（探索期）
- 关注：睡眠、情绪、生活节律
- 特点：轻度陪伴，避免打扰
- UI：极简风格

### 25-40岁（压力期）
- 关注：健康管理、压力缓解、周总结
- 特点：中度关怀，实用建议
- UI：今日节律+趋势洞察

### 40-60岁（健康期）
- 关注：体质调理、节气养生、食疗
- 特点：专业系统方案
- UI：节气养生+体质调理

### 60+岁（陪伴期）
- 关注：日常陪伴、用药提醒、语音交互
- 特点：高频关怀，语音优先
- UI：超大字体，语音为主

## 家庭系统
- 支持子女绑定父母，查看健康状态
- 异常时发送关怀提醒
- 尊重用户隐私，只在必要时通知家人

## 安全边界
- 检测到自伤倾向：立即建议求助心理援助热线
- 持续负面情绪：增加关怀频率
- 医学建议：始终建议咨询专业医生

## 输出格式
根据 age_group 调整：
- young_adult: 简短文字
- mid_adult: 实用建议
- middle_aged: 详细方案
- senior/elderly: 极简+语音优先
```

---

## 六、实施路线图

### Phase 1: 基础建设（1周）
- [ ] 数据库字段添加
- [ ] Life Stage Engine 服务
- [ ] 基础 API

### Phase 2: AI 集成（1周）
- [ ] AI Router 升级
- [ ] 动态 prompt 构建
- [ ] 多角色测试

### Phase 3: Flutter UI（2周）
- [ ] 动态首页
- [ ] 阶段切换动画
- [ ] 字体/样式适配

### Phase 4: 家庭系统（1周）
- [ ] 家庭绑定流程
- [ ] 健康状态查看
- [ ] 关怀提醒

### Phase 5: 优化（持续）
- [ ] 用户反馈收集
- [ ] A/B 测试
- [ ] 持续迭代

---

## 七、关键指标

| 指标 | 目标 |
|------|------|
| 阶段识别准确率 | >95% |
| 用户留存率（30天） | +20% |
| 家庭绑定率 | >30% |
| 用户满意度 | >4.5星 |
| 付费转化率 | +15% |
