# 顺时万亿级技术架构

> 从第一天就按 1 亿用户设计的系统架构

---

## 一、总体架构（6 层）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           顺时技术架构                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                     用户层 (Users)                               │      │
│   │         Flutter App (iOS/Android)  │  Web  │  Watch            │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                    客户端层 (Client Layer)                      │      │
│   │     UI  │  用户输入  │  通知  │  本地缓存  │  离线支持        │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│                           ┌────────┴────────┐                              │
│                           ▼                 ▼                              │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                     API Gateway                                 │      │
│   │         鉴权  │  限流  │  日志  │  灰度  │  监控              │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                    AI Router (顺时大脑)                         │      │
│   │   Prompt管理  │  模型路由  │  安全检测  │  Schema校验         │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                    核心服务层 (Core Services)                   │      │
│   │   AI Service  │  Care Engine  │  Life Stage  │  Content  │ Family│      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                    数据层 (Data Layer)                          │      │
│   │    PostgreSQL  │  Redis  │  Vector DB  │  S3  │  Analytics      │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、客户端层（Flutter）

### 2.1 架构设计

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Flutter 客户端架构                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐        │
│   │                        App Shell                                │        │
│   │   ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐  │        │
│   │   │  ChatPage │  │ DailyPlan│  │SolarTerm  │  │  Profile │  │        │
│   │   └───────────┘  └───────────┘  └───────────┘  └───────────┘  │        │
│   │         │              │              │              │          │        │
│   │         └──────────────┴──────────────┴──────────────┘          │        │
│   │                            │                                       │        │
│   │   ┌───────────────────────┴───────────────────────┐              │        │
│   │   │              State Management                 │              │        │
│   │   │    (Riverpod / Bloc / GetX)                   │              │        │
│   │   └───────────────────────┬───────────────────────┘              │        │
│   │                            │                                       │        │
│   │   ┌───────────────────────┴───────────────────────┐              │        │
│   │   │              Service Layer                    │              │        │
│   │   │  ┌─────────┐  ┌─────────┐  ┌─────────┐       │              │        │
│   │   │  │  Chat  │  │  User  │  │ Content │       │              │        │
│   │   │  │ Service│  │ Service│  │ Service │       │              │        │
│   │   │  └─────────┘  └─────────┘  └─────────┘       │              │        │
│   │   └───────────────────────┬───────────────────────┘              │        │
│   │                            │                                       │        │
│   └────────────────────────────┼───────────────────────────────────────┘        │
│                                │                                           │
│                                ▼                                           │
│                    ┌───────────────────────┐                              │
│                    │    API Gateway        │                              │
│                    │   (Kong / Nginx)     │                              │
│                    └───────────────────────┘                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 核心模块代码

```dart
// lib/core/services/api_client.dart

class ApiClient {
  final Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: 30.seconds,
      receiveTimeout: 30.seconds,
    ));
    
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      RetryInterceptor(),
    ]);
  }
  
  // 所有 AI 请求必须通过这个
  Future<AIResponse> sendMessage(ChatRequest request) async {
    return _dio.post('/chat/send', data: request.toJson());
  }
  
  Future<DailyPlan> generateDailyPlan(DailyPlanRequest request) async {
    return _dio.post('/daily-plan/generate', data: request.toJson());
  }
  
  Future<SolarTermInfo> getTodaySolarTerm() async {
    return _dio.get('/solar-term/today');
  }
  
  Future<List<Content>> getRecommendedContent(ContentRecommendRequest req) async {
    return _dio.get('/content/recommend', queryParameters: req.toJson());
  }
}
```

### 2.3 页面路由（根据 Life Stage 动态）

```dart
// lib/screens/home/home_screen.dart

class HomeScreen extends StatelessWidget {
  final LifeStage lifeStage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildDynamicContent(lifeStage),
    );
  }
  
  Widget _buildDynamicContent(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return ExplorationHome();    // 18-25岁
      case LifeStage.stress:
        return StressHome();         // 25-40岁
      case LifeStage.health:
        return HealthHome();          // 40-60岁
      case LifeStage.companionship:
        return CompanionshipHome();  // 60+岁
    }
  }
}
```

---

## 三、API Gateway

### 3.1 技术选型

| 方案 | 优点 | 缺点 | 推荐场景 |
|------|------|------|----------|
| **Kong** | 功能全、插件多 | 资源消耗大 | 中大型 |
| **Nginx** | 高性能、简单 | 限流需额外配置 | 小型/高性能需求 |
| **AWS API Gateway** | 托管、无运维 | 成本较高 | AWS 环境 |
| **Traefik** | 云原生、易配置 | 功能较新 | K8s 环境 |

**推荐**: Kong (功能全) 或 Nginx (高性能)

### 3.2 核心配置

```yaml
# kong.yaml 示例

services:
  # AI Chat API
  - name: shunshi-chat
    url: http://ai-router:3000
    routes:
      - name: chat-route
        paths: ["/api/chat"]
        methods: ["POST"]
    plugins:
      - name: rate-limiting
        config:
          minute: 60
          policy: local
      - name: jwt

  # Daily Plan API
  - name: shunshi-daily-plan
    url: http://core-service:3001
    routes:
      - name: daily-plan-route
        paths: ["/api/daily-plan"]
    plugins:
      - name: rate-limiting
        config:
          minute: 10

  # Content API
  - name: shunshi-content
    url: http://content-service:3002
    routes:
      - name: content-route
        paths: ["/api/content"]
    plugins:
      - name: rate-limiting
        config:
          minute: 100
```

### 3.3 API 列表

```typescript
// API 路由定义

export const API_ROUTES = {
  // Chat
  'POST /chat/send': '发送消息',
  'GET /chat/history': '获取历史',
  
  // Daily Plan
  'POST /daily-plan/generate': '生成每日计划',
  'GET /daily-plan/today': '获取今日计划',
  
  // Solar Terms
  'GET /solar-term/today': '今日节气',
  
  // Content
  'GET /content/recommend': '推荐内容',
  
  // User
  'POST /user/onboarding': '用户初始化',
  'GET /user/profile': '用户资料',
  'GET /user/life-stage': '用户阶段',
  
  // Family
  'GET /family/members': '家庭成员',
  'POST /family/bind': '绑定家人',
  'GET /family/health/:userId': '家人健康状态',
};
```

---

## 四、AI Router（顺时大脑）

### 4.1 系统架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AI Router 架构                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    User Request                                                             │
│         │                                                                    │
│         ▼                                                                    │
│   ┌─────────────┐  ┌─────────────────────────────────────────┐             │
│   │  Request   │  │  1. 请求验证                              │             │
│   │  Validator │  │     • JSON Schema 校验                    │             │
│   └─────────────┘  │     • 内容安全检查                        │             │
│         │          └─────────────────────────────────────────┘             │
│         ▼                                                                    │
│   ┌─────────────┐  ┌─────────────────────────────────────────┐             │
│   │   Intent   │  │  2. Intent Detection                     │             │
│   │   Detector │  └─────────────────────────────────────────┘             │
│   └─────────────┘                                                           │
│         │                                                                    │
│         ▼                                                                    │
│   ┌─────────────┐  ┌─────────────────────────────────────────┐             │
│   │   Prompt   │  │  3. Prompt Builder                       │             │
│   │   Builder  │  │     • Core + Policy + Task                │             │
│   └─────────────┘  └─────────────────────────────────────────┘             │
│         │                                                                    │
│         ▼                                                                    │
│   ┌─────────────┐  ┌─────────────────────────────────────────┐             │
│   │   Model    │  │  4. Model Router                         │             │
│   │   Router   │  │     • 7B: 普通聊天                        │             │
│   └─────────────┘  │     • 72B: 复杂问题                       │             │
│         │          └─────────────────────────────────────────┘             │
│         ▼                                                                    │
│   ┌─────────────┐  ┌─────────────────────────────────────────┐             │
│   │    LLM     │  │  5. Schema Validation                    │             │
│   └─────────────┘  └─────────────────────────────────────────┘             │
│         │                                                                    │
│         ▼                                                                    │
│   ┌─────────────┐  ┌─────────────────────────────────────────┐             │
│   │  Response  │  │  6. Response Builder + Follow-up         │             │
│   └─────────────┘  └─────────────────────────────────────────┘             │
│         │                                                                    │
│         ▼                                                                    │
│      Response                                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 核心代码实现

```typescript
// ai-router/index.ts

export class AIRouter {
  private promptManager: PromptManager;
  private modelRouter: ModelRouter;
  private schemaValidator: SchemaValidator;
  private safetyDetector: SafetyDetector;
  private careEngine: CareEngine;
  
  async route(request: AIRouteRequest): Promise<AIRouteResponse> {
    const startTime = Date.now();
    
    try {
      // 1. 请求验证
      await this.validateRequest(request);
      
      // 2. 安全检测
      const safetyResult = await this.safetyDetector.detect(request.message);
      if (safetyResult.blocked) {
        return this.buildSafeResponse(safetyResult);
      }
      
      // 3. Intent Detection
      const intent = await this.detectIntent(request);
      
      // 4. Prompt Builder
      const prompt = await this.promptManager.build({
        core: 'SS_CORE_v1.0',
        policy: request.isPremium ? 'SS_POLICY_PREMIUM' : 'SS_POLICY_FREE',
        task: intent.task,
        context: {
          lifeStage: request.user.lifeStage,
          ageGroup: request.user.ageGroup,
          careStatus: await this.careEngine.getStatus(request.userId),
        },
      });
      
      // 5. Model Router - 选择模型
      const model = this.modelRouter.select(intent, {
        isPremium: request.isPremium,
        complexity: intent.complexity,
      });
      
      // 6. 调用 LLM
      const llmResponse = await model.complete(prompt);
      
      // 7. Schema Validation
      const validated = this.schemaValidator.validate(llmResponse);
      
      // 8. 生成 Follow-up
      const followUp = await this.generateFollowUp(intent, validated);
      
      // 9. 记录日志
      await this.log({
        request, intent, model: model.name,
        tokens: llmResponse.tokens,
        latency: Date.now() - startTime,
      });
      
      return {
        content: validated.text,
        intent: intent.type,
        followUp,
        careStatus: validated.careStatus,
      };
      
    } catch (error) {
      return this.handleError(error, startTime);
    }
  }
}
```

### 4.3 Prompt 管理

```typescript
// ai-router/prompt-manager.ts

class PromptManager {
  private prompts: Map<string, string> = new Map();
  
  constructor() {
    this.loadPrompts();
  }
  
  private loadPrompts() {
    this.prompts.set('SS_CORE_v1.0', `
你是顺时，一个 AI 养生陪伴助手。
你的目标是通过智慧和关怀，让用户的每一天都更加健康、舒适。

用户信息：
- 年龄段: {{ageGroup}}
- 人生阶段: {{lifeStage}}
- 关怀状态: {{careStatus}}

核心原则：
1. 记住用户之前说过的话
2. 主动关心用户的状态
3. 回答简洁温暖，不过度说教
4. 知道什么时候不打扰用户
    `);
    
    this.prompts.set('SS_POLICY_PREMIUM', `
尊享版用户权益：更详细的健康建议、深度上下文记忆、优先响应
    `);
    
    this.prompts.set('SS_POLICY_FREE', `
免费版用户：提供基础陪伴、简化建议
    `);
    
    this.prompts.set('TASK_CHAT', `
当前任务：日常聊天。请用温暖的方式回应用户，保持简短（不超过100字）。
    `);
    
    this.prompts.set('TASK_SLEEP', `
当前任务：睡眠咨询。请提供实用的睡眠建议。
    `);
  }
  
  async build(config: PromptConfig): Promise<string> {
    let prompt = this.prompts.get(config.core) || '';
    const policy = this.prompts.get(config.policy);
    const task = this.prompts.get(config.task);
    
    if (policy) prompt += '\n\n' + policy;
    if (task) prompt += '\n\n' + task;
    
    // 替换变量
    prompt = prompt.replace('{{lifeStage}}', config.context.lifeStage);
    prompt = prompt.replace('{{ageGroup}}', config.context.ageGroup);
    prompt = prompt.replace('{{careStatus}}', JSON.stringify(config.context.careStatus));
    
    return prompt;
  }
}
```

### 4.4 Model Router（成本控制）

```typescript
// ai-router/model-router.ts

class ModelRouter {
  private models = {
    'gpt-4o': { size: 'large', cost: 0.005, latency: 1000 },
    'gpt-4o-mini': { size: '7b', cost: 0.00015, latency: 500 },
    'claude-3-haiku': { size: '7b', cost: 0.00025, latency: 500 },
  };
  
  select(intent: Intent, userTier: { isPremium: boolean; complexity: string }) {
    // 成本控制：70% 请求使用小模型
    const useSmallModel = !userTier.isPremium || 
      (intent.complexity === 'low' && Math.random() < 0.7);
    
    if (useSmallModel) {
      return intent.task === 'TASK_HEALTH' ? 'claude-3-haiku' : 'gpt-4o-mini';
    }
    
    return intent.complexity === 'high' ? 'gpt-4o' : 'gpt-4o-mini';
  }
}
```

---

## 五、核心服务层

### 5.1 服务架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          核心服务层架构                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │                      AI Service                                  │      │
│   │   • AI 调用  │  Prompt 管理  │  模型路由  │  响应缓存           │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│   ┌─────────────────────────────────┴─────────────────────────────────┐      │
│   │                                                                     │      │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │      │
│   │   │ Care Engine │  │Life Stage  │  │Content Eng. │              │      │
│   │   │ • 关怀状态  │  │ • 年龄计算  │  │ • 内容推荐  │              │      │
│   │   │ • 跟进任务  │  │ • 首页配置  │  │ • 搜索      │              │      │
│   │   │ • 触达策略  │  │ • AI 角色  │  │ • 审核      │              │      │
│   │   └─────────────┘  └─────────────┘  └─────────────┘              │      │
│   │                                                                     │      │
│   │   ┌─────────────┐                                                  │      │
│   │   │Family Engine│                                                  │      │
│   │   │ • 家庭绑定  │                                                  │      │
│   │   │ • 健康查看  │                                                  │      │
│   │   │ • 关怀提醒  │                                                  │      │
│   │   └─────────────┘                                                  │      │
│   │                                                                     │      │
│   └─────────────────────────────────────────────────────────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Care Engine（顺时独有）

```typescript
// services/care-engine.ts

class CareEngine {
  async getStatus(userId: string): Promise<CareStatus> {
    const status = await this.db.careStatus.findUnique({ where: { userId } });
    return status || this.getDefaultStatus();
  }
  
  async update(userId: string, update: Partial<CareStatus>): Promise<void> {
    const current = await this.getStatus(userId);
    const trend = this.calculateTrend(current, update);
    
    await this.db.careStatus.upsert({
      where: { userId },
      update: { ...update, trend },
      create: { userId, ...update, trend: 'stable' },
    });
  }
  
  async shouldReach(userId: string): Promise<ReachDecision> {
    const status = await this.getStatus(userId);
    const user = await this.db.user.findUnique({ where: { id: userId } });
    
    if (this.isQuietHours(user.timezone)) {
      return { shouldReach: false, reason: 'quiet_hours' };
    }
    
    const todayContacts = await this.getTodayContactCount(userId);
    if (todayContacts >= this.getMaxContacts(user.lifeStage)) {
      return { shouldReach: false, reason: 'daily_limit_reached' };
    }
    
    if (status.trend === 'declining' || status.overall === 'high') {
      return { shouldReach: true, reason: 'care_needed' };
    }
    
    return { shouldReach: false, reason: 'no_need' };
  }
}
```

### 5.3 Life Stage Engine

```typescript
// services/life-stage-engine.ts

class LifeStageEngine {
  
  calculateLifeStage(age: number): LifeStage {
    if (age < 25) return 'EXPLORATION';
    if (age < 40) return 'STRESS';
    if (age < 60) return 'HEALTH';
    return 'COMPANIONSHIP';
  }
  
  getStageConfig(stage: LifeStage) {
    return {
      EXPLORATION: {
        name: '探索阶段', careLevel: 'LIGHT', maxDailyContacts: 2,
        features: ['sleep_tracking', 'emotion_chat', 'circadian'],
        homeModules: ['today_rhythm', 'chat', 'sleep'],
        aiPersona: { name: '小顺', tone: '活泼' },
      },
      STRESS: {
        name: '压力阶段', careLevel: 'MEDIUM', maxDailyContacts: 3,
        features: ['health_plan', 'weekly_summary', 'emotion_log'],
        homeModules: ['today_wellness', 'chat', 'health_trends'],
        aiPersona: { name: '顺时', tone: '温暖' },
      },
      HEALTH: {
        name: '健康阶段', careLevel: 'HEAVY', maxDailyContacts: 4,
        features: ['constitution', 'solar_terms', 'diet_therapy'],
        homeModules: ['solar_terms', 'constitution', 'diet_therapy'],
        aiPersona: { name: '顺时顾问', tone: '专业' },
      },
      COMPANIONSHIP: {
        name: '陪伴阶段', careLevel: 'INTENSIVE', maxDailyContacts: 5,
        features: ['daily_chat', 'simple_advice', 'medication_reminder'],
        homeModules: ['chat', 'daily_advice', 'voice'],
        aiPersona: { name: '顺时陪伴', tone: '耐心' },
      },
    }[stage];
  }
}
```

---

## 六、数据层设计

### 6.1 数据库架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          数据层架构                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐        │
│   │                    PostgreSQL (主数据库)                        │        │
│   │   User │ Conversation │ CareStatus │ FollowUp │ Family │ Content│        │
│   └─────────────────────────────────────────────────────────────────┘        │
│                                    │                                        │
│         ┌──────────────────────────┼──────────────────────────┐            │
│         ▼                          ▼                          ▼            │
│   ┌─────────────┐          ┌─────────────┐          ┌─────────────┐      │
│   │    Redis    │          │  Vector DB  │          │      S3      │      │
│   │  (缓存/会话) │          │ (记忆存储)  │          │  (媒体存储)  │      │
│   └─────────────┘          └─────────────┘          └─────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 核心表结构

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20),
    email VARCHAR(255),
    name VARCHAR(100),
    
    -- 生命周期字段
    birth_date DATE,
    age INT,
    life_stage VARCHAR(20) DEFAULT 'exploration',
    age_group VARCHAR(20) DEFAULT 'young_adult',
    family_role VARCHAR(20) DEFAULT 'self',
    
    -- 订阅
    subscription_tier VARCHAR(20) DEFAULT 'free',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 对话表
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    role VARCHAR(10) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 关怀状态表
CREATE TABLE care_status (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    overall VARCHAR(20) DEFAULT 'low',
    emotion INT DEFAULT 50,
    energy INT DEFAULT 50,
    health INT DEFAULT 50,
    trend VARCHAR(20) DEFAULT 'stable',
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Follow-up 任务表
CREATE TABLE follow_ups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    intent VARCHAR(100),
    message TEXT,
    schedule_time TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

-- 家庭关系表
CREATE TABLE family_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    related_user_id UUID REFERENCES users(id),
    relation_type VARCHAR(20) NOT NULL,
    care_level VARCHAR(20) DEFAULT 'normal',
    created_at TIMESTAMP DEFAULT NOW()
);

-- 内容表
CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    title VARCHAR(500) NOT NULL,
    summary TEXT,
    body TEXT,
    tags TEXT[],
    suitable_age_groups VARCHAR(20)[],
    created_at TIMESTAMP DEFAULT NOW()
);

-- AI 日志表
CREATE TABLE ai_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    prompt_version VARCHAR(50),
    model VARCHAR(50),
    intent VARCHAR(100),
    input_tokens INT,
    output_tokens INT,
    latency_ms INT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_conversations_user ON conversations(user_id, created_at DESC);
CREATE INDEX idx_follow_ups_schedule ON follow_ups(schedule_time, status);
CREATE INDEX idx_ai_logs_user ON ai_logs(user_id, created_at DESC);
```

---

## 七、AI 成本控制（关键）

### 7.1 三层控制

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       AI 成本控制策略                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │  第一层：小模型优先 (70% 请求)                                    │      │
│   │  ─────────────────────────────────────────────                   │      │
│   │  普通聊天 → 7B 模型 (GPT-4o-mini / Claude-Haiku)                │      │
│   │  响应快、成本低                                                   │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│   ┌─────────────────────────────────┴─────────────────────────────────┐      │
│   │  第二层：大模型只用于关键节点 (30% 请求)                          │      │
│   │  ─────────────────────────────────────────────                   │      │
│   │  • 每日计划生成                                                   │      │
│   │  • 复杂养生问题                                                   │      │
│   │  • 首次深度咨询                                                   │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                    │                                        │
│   ┌─────────────────────────────────┴─────────────────────────────────┐      │
│   │  第三层：缓存系统                                                 │      │
│   │  ─────────────────────────────────────────────                   │      │
│   │  • 相似问题直接返回缓存                                           │      │
│   │  • 节气内容、通用养生建议缓存 24h                                 │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                                                             │
│   成本目标：                                                                │
│   • 单次请求成本 < ¥0.001                                                │
│   • 日活用户成本 < ¥0.01/天                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 八、日志与安全

### 8.1 日志系统

```typescript
// 必记录的日志字段

interface AILog {
  userId: string;
  promptVersion: string;  // SS_CORE_v1.0
  model: string;          // gpt-4o-mini
  intent: string;        // sleep / emotion / chat
  inputTokens: number;
  outputTokens: number;
  latency: number;        // ms
  safetyFlag: string;    // none / warning / blocked
  error?: string;
}
```

### 8.2 安全系统

```typescript
// 安全检测

class SafetyDetector {
  private riskKeywords = {
    critical: ['自杀', '轻生', '不想活'],
    warning: ['抑郁', '绝望', '崩溃'],
    elevated: ['失眠', '吃不下', '不想动'],
  };
  
  detect(message: string): SafetyResult {
    for (const keyword of this.riskKeywords.critical) {
      if (message.includes(keyword)) {
        return { level: 'critical', blocked: true, response: this.getCrisisResponse() };
      }
    }
    // ...
    return { level: 'none', blocked: false };
  }
}
```

---

## 九、1 亿用户技术目标

| 指标 | 目标 |
|------|------|
| **同时在线** | 100 万 |
| **日活跃** | 1000 万 |
| **AI 请求量** | 5000 万/天 |
| **响应延迟** | P99 < 2s |
| **可用性** | 99.9% |
| **AI 成本** | < ¥0.01/DAU/天 |

---

## 十、总结

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     顺时万亿级技术公式                                       │
│                                                                             │
│     稳定 = 6层架构 × AI Router × 成本控制 × 缓存                           │
│                                                                             │
│     ┌───────────────┐                                                       │
│     │   6层架构     │ 用户→客户端→Gateway→AI Router→服务→数据              │
│     └───────┬───────┘                                                       │
│             │                                                               │
│     ┌───────┴───────┐                                                       │
│     │   AI Router   │ 顺时大脑：Prompt管理+模型路由+安全+Schema            │
│     └───────┬───────┘                                                       │
│             │                                                               │
│     ┌───────┴───────┐                                                       │
│     │   成本控制    │ 70%小模型+30%大模型+缓存                             │
│     └───────┬───────┘                                                       │
│             │                                                               │
│     ┌───────┴───────┐                                                       │
│     │   数据护城河   │ 积累用户数据，AI越学越懂                            │
│     └───────────────┘                                                       │
│                                                                             │
│     技术架构决定能否支撑 1 亿用户                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

下一步是否继续做**《顺时 1 亿用户产品 UI 系统》**？
