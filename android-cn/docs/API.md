# API.md - 顺时中国版 API 参考

## 概述

顺时后端基于 **FastAPI + PostgreSQL + Redis**，提供 RESTful API。所有接口前缀为 `/api/v1`。

> 测试服务器：`http://localhost:8000`  
> 生产服务器：`https://api.shunshi.app`（示例）

---

## 认证

| 方式 | 说明 |
|------|------|
| Bearer Token | JWT，HTTP Header `Authorization: Bearer <token>` |
| 短期 Token | 7天有效期 |
| Refresh Token | 30天有效期 |

---

## API 端点

### 1. 认证模块 `/auth`

#### POST /api/v1/auth/register
注册账号。

**Request:**
```json
{
  "phone": "13800138000",
  "nickname": "张三",
  "verify_code": "123456",
  "invite_code": "SHUNSHI2026"
}
```

**Response:**
```json
{
  "user_id": "usr_abc123",
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 604800
}
```

---

#### POST /api/v1/auth/login
短信验证码登录。

**Request:**
```json
{
  "phone": "13800138000",
  "verify_code": "123456"
}
```

**Response:**
```json
{
  "user_id": "usr_abc123",
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "is_new_user": false
}
```

---

#### POST /api/v1/auth/refresh
刷新 Token。

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

---

### 2. 用户模块 `/users`

#### GET /api/v1/users/me
获取当前用户信息。

**Response:**
```json
{
  "user_id": "usr_abc123",
  "phone": "13800138000",
  "nickname": "张三",
  "avatar_url": "https://...",
  "life_stage": "stressed",
  "feeling": "calm",
  "style_preference": "gentle",
  "hemisphere": "north",
  "is_premium": false,
  "created_at": "2026-03-01T00:00:00Z"
}
```

---

#### PATCH /api/v1/users/me
更新用户信息。

**Request:**
```json
{
  "nickname": "新昵称",
  "hemisphere": "south"
}
```

---

### 3. Onboarding 模块 `/onboarding`

#### POST /api/v1/onboarding/complete
完成 Onboarding 7步后提交。

**Request:**
```json
{
  "feeling": "stressed",
  "help_goal": "sleep_better",
  "life_stage": "working",
  "support_time": "evening",
  "style_preference": "gentle",
  "body_constitution": "qi_deficiency",
  "hemisphere": "north"
}
```

**Response:**
```json
{
  "user_id": "usr_abc123",
  "dashboard": {
    "greeting": "下午好，张三",
    "daily_insight": "惊蛰时节，春雷始鸣...",
    "suggestions": [
      {
        "type": "breathing",
        "title": "呼吸调息",
        "subtitle": "3分钟平缓呼吸",
        "action": "/library/breathing"
      },
      {
        "type": "food",
        "title": "食疗推荐",
        "subtitle": "山药枸杞粥",
        "action": "/library/food"
      },
      {
        "type": "exercise",
        "title": "运动养生",
        "subtitle": "八段锦第一式",
        "action": "/library/exercise"
      }
    ],
    "season_card": {
      "name": "惊蛰",
      "date_range": "3月5日-3月19日",
      "emoji": "⚡",
      "theme": "春醒"
    }
  }
}
```

---

### 4. 首页模块 `/home`

#### GET /api/v1/home/dashboard
获取首页 Dashboard 数据。

**Query params:**
- `user_id`: string
- `hemisphere`: `north` | `south`

**Response:** 同 `/onboarding/complete` 的 `dashboard` 字段。

---

### 5. AI 对话模块 `/chat`

#### POST /api/v1/chat/send
发送消息并获取 AI 回复。

**Request:**
```json
{
  "message": "最近睡眠不好怎么办",
  "conversation_id": "conv_abc123"
}
```

**Response:**
```json
{
  "message_id": "msg_xyz789",
  "conversation_id": "conv_abc123",
  "text": "听起来你最近休息不太好...",
  "tone": "warm",
  "care_status": "watching",
  "safety_flag": false,
  "cards": [
    {
      "type": "breathing",
      "title": "4-7-8 呼吸法",
      "steps": ["用鼻子吸气4秒", "屏住呼吸7秒", "用嘴呼气8秒"],
      "duration_min": 5
    }
  ],
  "follow_up": ["今天感觉怎么样？", "有什么心事可以聊聊"]
}
```

---

#### GET /api/v1/chat/conversations
获取对话列表。

**Response:**
```json
{
  "conversations": [
    {
      "id": "conv_abc123",
      "title": "关于睡眠的对话",
      "last_message": "祝你今晚好梦",
      "last_message_at": "2026-03-23T22:00:00Z",
      "message_count": 12
    }
  ]
}
```

---

### 6. 节气模块 `/wellness/solar-terms`

#### GET /api/v1/wellness/solar-terms/current
获取当前节气。

**Query params:**
- `hemisphere`: `north` | `south`

**Response:**
```json
{
  "name": "惊蛰",
  "start_date": "2026-03-05",
  "end_date": "2026-03-19",
  "description": "春雷始鸣，惊醒蛰虫",
  "living_guidance": "早睡早起，养肝护肝",
  "diet_recommendation": "宜清淡，多食绿色蔬菜",
  "emotional_tip": "保持心情舒畅，忌怒"
}
```

---

#### GET /api/v1/wellness/solar-terms/list
获取24节气列表。

**Response:**
```json
{
  "solar_terms": [
    {"name": "立春", "date": "2月3日-2月5日"},
    {"name": "雨水", "date": "2月18日-2月20日"},
    ...
  ]
}
```

---

### 7. 体质模块 `/wellness/constitution`

#### GET /api/v1/wellness/constitution/:user_id
获取用户体质类型。

**Response:**
```json
{
  "constitution_type": "qi_deficiency",
  "description": "气虚体质",
  "characteristics": ["容易疲劳", "气短懒言"],
  "recommendations": ["适度运动", "食补黄芪"]
}
```

---

#### POST /api/v1/wellness/constitution/test
完成体质测试。

**Request:**
```json
{
  "answers": [
    {"question_id": "q1", "answer": "often"},
    {"question_id": "q2", "answer": "rarely"}
  ]
}
```

---

### 8. 内容库模块 `/wellness/content`

#### GET /api/v1/wellness/content/list
获取养生内容列表。

**Query params:**
- `type`: `food` | `acupoint` | `exercise` | `tea`
- `limit`: int（默认20）
- `offset`: int（默认0）

**Response:**
```json
{
  "items": [
    {
      "id": "food_001",
      "type": "food",
      "title": "山药枸杞粥",
      "subtitle": "补气养血，健脾益肺",
      "image_url": "https://...",
      "tags": ["补气", "早餐", "简单"]
    }
  ],
  "total": 120,
  "has_more": true
}
```

---

#### GET /api/v1/wellness/content/:id
获取内容详情。

**Response:**
```json
{
  "id": "food_001",
  "type": "food",
  "title": "山药枸杞粥",
  "subtitle": "补气养血，健脾益肺",
  "ingredients": ["山药", "枸杞", "大米", "水"],
  "steps": ["山药去皮切块", "大米洗净", "加水煮沸", "小火熬30分钟"],
  "related_acupoints": ["足三里", "中脘"],
  "contraindications": ["糖尿病患者慎用"]
}
```

---

### 9. 每日计划 `/wellness/daily-plan`

#### GET /api/v1/wellness/daily-plan/today
获取今日养生计划。

**Response:**
```json
{
  "date": "2026-03-23",
  "solar_term": "春分",
  "items": [
    {
      "type": "habit",
      "title": "早起梳头",
      "description": "用木梳梳头100下",
      "completed": false
    },
    {
      "type": "food",
      "title": "早餐推荐",
      "description": "山药小米粥",
      "image_url": "https://..."
    },
    {
      "type": "exercise",
      "title": "八段锦",
      "duration_min": 15
    }
  ]
}
```

---

### 10. 订阅模块 `/subscription`

#### GET /api/v1/subscription/products
获取订阅产品列表。

**Response:**
```json
{
  "products": [
    {
      "id": "free",
      "name": "免费版",
      "price": 0,
      "features": ["每日洞察", "基础对话", "节气内容"]
    },
    {
      "id": "premium_monthly",
      "name": "养心计划（月付）",
      "price": 29.9,
      "original_price": 49.9,
      "features": ["全部功能", "家庭共享", "体质测试", "AI跟进"]
    },
    {
      "id": "family_yearly",
      "name": "家庭计划（年付）",
      "price": 299,
      "original_price": 599,
      "features": ["4个账号", "家庭关怀", "全部功能"]
    }
  ]
}
```

---

#### POST /api/v1/subscription/purchase
发起购买（微信支付/支付宝）。

**Request:**
```json
{
  "product_id": "premium_monthly",
  "payment_method": "wechat" | "alipay"
}
```

**Response:**
```json
{
  "order_id": "ord_abc123",
  "payment_url": "weixin://...",
  "qr_code": "https://..."
}
```

---

#### GET /api/v1/subscription/current
获取当前订阅状态。

**Response:**
```json
{
  "plan": "premium_monthly",
  "status": "active",
  "expires_at": "2026-04-23T00:00:00Z",
  "auto_renew": true,
  "member_count": 1
}
```

---

### 11. 家庭模块 `/family`

#### GET /api/v1/family
获取家庭成员列表。

**Response:**
```json
{
  "family_id": "fam_abc123",
  "members": [
    {
      "user_id": "usr_abc123",
      "nickname": "张三",
      "role": "owner",
      "feeling_today": "calm"
    }
  ],
  "is_premium": true
}
```

---

### 12. 健康记录 `/wellness/records`

#### POST /api/v1/wellness/records
提交健康记录（每日反思）。

**Request:**
```json
{
  "mood": "calm",
  "energy": "high",
  "sleep_quality": "good",
  "notes": "今天感觉不错"
}
```

---

#### GET /api/v1/wellness/records
获取健康记录列表。

**Query params:**
- `limit`: int
- `start_date`: ISO date
- `end_date`: ISO date

---

## 错误码

| HTTP Status | code | 说明 |
|-------------|------|------|
| 400 | `INVALID_PARAMS` | 参数错误 |
| 401 | `UNAUTHORIZED` | Token 无效或过期 |
| 403 | `PREMIUM_REQUIRED` | 需要 Premium 订阅 |
| 404 | `NOT_FOUND` | 资源不存在 |
| 429 | `RATE_LIMITED` | 请求过于频繁 |
| 500 | `INTERNAL_ERROR` | 服务器错误 |
