# 顺时 API 文档

> 版本: 1.0  
> 日期: 2026-03-13

---

## 一、基础信息

### Base URL

```
开发环境: http://localhost:4000
生产环境: https://api.shunshi.com
```

### 认证方式

```
Authorization: Bearer <token>
```

### 公共响应格式

```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "code": 200
}
```

---

## 二、用户接口

### 2.1 用户注册

**POST** `/api/v1/auth/register`

**请求体**

```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "用户名"
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user-001",
      "email": "user@example.com",
      "name": "用户名",
      "life_stage": "exploration"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### 2.2 用户登录

**POST** `/api/v1/auth/login`

**请求体**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user-001",
      "email": "user@example.com",
      "name": "用户名",
      "is_premium": false,
      "subscription_plan": "free"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### 2.3 获取用户信息

**GET** `/api/v1/auth/me`

**响应**

```json
{
  "success": true,
  "data": {
    "id": "user-001",
    "email": "user@example.com",
    "name": "用户名",
    "life_stage": "exploration",
    "is_premium": false,
    "subscription_plan": "free",
    "birthday": "1990-01-01",
    "gender": "unknown",
    "created_at": "2026-01-01T00:00:00Z"
  }
}
```

---

## 三、聊天接口

### 3.1 发送消息

**POST** `/api/v1/chat`

**请求体**

```json
{
  "message": "今天感觉有点累",
  "conversation_id": "conv-001"
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "message_id": "msg-001",
    "conversation_id": "conv-001",
    "text": "今天辛苦了，适当的休息对身体很重要...",
    "tone": "gentle",
    "care_status": "stable",
    "follow_up": {
      "in_days": 1,
      "intent": "sleep_check"
    },
    "offline_encouraged": true,
    "presence_level": "normal",
    "safety_flag": "none"
  }
}
```

---

## 四、今日计划接口

### 4.1 获取今日计划

**GET** `/api/v1/today-plan`

**响应**

```json
{
  "success": true,
  "data": {
    "id": "plan-20260313",
    "date": "2026-03-13",
    "insights": [
      {
        "id": "insight-1",
        "title": "早安",
        "content": "新的一天开始了，记得喝一杯温水",
        "icon": "🌅",
        "type": "general"
      }
    ],
    "tasks": [
      {
        "id": "task-1",
        "title": "喝一杯温水",
        "description": "帮助身体排毒",
        "status": "pending",
        "priority": "normal",
        "category": "health"
      }
    ],
    "recommendations": [
      {
        "id": "rec-1",
        "title": "春季养生食谱",
        "description": "适合春季的养生美食",
        "type": "recipe"
      }
    ],
    "solar_term": {
      "name": "春分",
      "emoji": "🌸",
      "description": "阴阳平衡，昼夜相等",
      "suggestions": ["适当运动", "调理脾胃"],
      "date": "2026-03-13"
    }
  }
}
```

---

### 4.2 更新任务状态

**PATCH** `/api/v1/today-plan/tasks/{task_id}`

**请求体**

```json
{
  "status": "completed"
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "id": "task-1",
    "status": "completed",
    "completed_at": "2026-03-13T10:30:00Z"
  }
}
```

---

## 五、内容接口

### 5.1 获取内容列表

**GET** `/api/v1/contents`

**查询参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| type | string | 内容类型: recipe/acupoint/exercise/tips/solar_term |
| category | string | 分类 |
| page | int | 页码 |
| limit | int | 每页数量 |

**响应**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "content-001",
        "title": "春季养肝茶",
        "description": "枸杞菊花茶，清肝明目",
        "type": "recipe",
        "category": "茶饮",
        "media_url": "https://...",
        "tags": ["春季", "养肝", "茶饮"],
        "view_count": 100
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

---

### 5.2 获取内容详情

**GET** `/api/v1/contents/{id}`

**响应**

```json
{
  "success": true,
  "data": {
    "id": "content-001",
    "title": "春季养肝茶",
    "description": "枸杞菊花茶，清肝明目",
    "type": "recipe",
    "category": "茶饮",
    "media_url": "https://...",
    "thumbnail_url": "https://...",
    "tags": ["春季", "养肝", "茶饮"],
    "view_count": 100,
    "like_count": 10,
    "created_at": "2026-01-01T00:00:00Z"
  }
}
```

---

## 六、家庭接口

### 6.1 获取家庭信息

**GET** `/api/v1/family`

**响应**

```json
{
  "success": true,
  "data": {
    "family_id": "family-001",
    "family_name": "我的家庭",
    "members": [
      {
        "id": "member-001",
        "name": "爸爸",
        "relation": "father",
        "age": 55,
        "status": "normal",
        "last_active_at": "2026-03-13T08:00:00Z"
      }
    ]
  }
}
```

---

### 6.2 添加家庭成员

**POST** `/api/v1/family/members`

**请求体**

```json
{
  "name": "妈妈",
  "relation": "mother",
  "age": 52
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "id": "member-002",
    "name": "妈妈",
    "relation": "mother",
    "age": 52,
    "status": "normal"
  }
}
```

---

### 6.3 生成邀请码

**POST** `/api/v1/family/invite`

**请求体**

```json
{
  "relation": "father"
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "code": "ABC123",
    "expires_at": "2026-03-20T00:00:00Z"
  }
}
```

---

## 七、订阅接口

### 7.1 获取订阅状态

**GET** `/api/v1/subscription`

**响应**

```json
{
  "success": true,
  "data": {
    "plan": "free",
    "status": "active",
    "expires_at": null,
    "features": {
      "unlimited_chat": false,
      "today_plan": false,
      "deep_suggestions": false,
      "family": false
    }
  }
}
```

---

### 7.2 订阅

**POST** `/api/v1/subscription/subscribe`

**请求体**

```json
{
  "plan": "premium",
  "receipt": "base64_encoded_receipt"
}
```

**响应**

```json
{
  "success": true,
  "data": {
    "plan": "premium",
    "status": "active",
    "expires_at": "2027-03-13T00:00:00Z"
  }
}
```

---

## 八、错误码

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 429 | 请求过于频繁 |
| 500 | 服务器错误 |
| 503 | 服务不可用 |

---

*文档结束*
