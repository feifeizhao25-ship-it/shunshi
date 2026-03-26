# 顺时 ShunShi 订阅系统设计

## 订阅产品矩阵

| 产品 | 代码 | 价格 | 周期 | 核心功能 |
|------|------|------|------|----------|
| 免费版 | free | ¥0 | 永久 | 基础对话、节气查询、基础习惯 |
| 养心版 | yangxin | ¥28 | 月 | 深记忆(+30天)、家庭1人、AI优先 |
| 颐养版 | yiyang | ¥68 | 月 | 完整记忆(+90天)、家庭3人、全部Skills |
| 家he版 | jiahe | ¥128 | 月 | 无限记忆、家庭无限、专属客服 |

---

## 订阅价值对比

```python
SUBSCRIPTION_TIERS = {
    "free": {
        "name": "免费版",
        "price": 0,
        "features": {
            "ai_chat": True,
            "solar_terms": True,
            "basic_habits": True,
            "memory_days": 7,
            "family_members": 0,
            "skills_access": ["daily_rhythm_plan", "solar_term_guide"],
            "priority": "low",
            "ads": False
        }
    },
    "yangxin": {
        "name": "养心版",
        "price": 28,
        "monthly": True,
        "features": {
            "ai_chat": True,
            "solar_terms": True,
            "basic_habits": True,
            "advanced_habits": True,
            "memory_days": 30,
            "family_members": 1,
            "skills_access": "basic",
            "priority": "medium",
            "ads": False,
            "ai_response_time": "fast"
        }
    },
    "yiyang": {
        "name": "颐养版",
        "price": 68,
        "monthly": True,
        "features": {
            "ai_chat": True,
            "solar_terms": True,
            "all_habits": True,
            "memory_days": 90,
            "family_members": 3,
            "skills_access": "all",
            "priority": "high",
            "ads": False,
            "ai_response_time": "fastest",
            "custom_reminders": True
        }
    },
    "jiahe": {
        "name": "家和版",
        "price": 128,
        "monthly": True,
        "features": {
            "ai_chat": True,
            "solar_terms": True,
            "all_habits": True,
            "memory_days": -1,  # unlimited
            "family_members": -1,  # unlimited
            "all",
            "skills_access": "priority": "highest",
            "ads": False,
            "ai_response_time": "fastest",
            "custom_reminders": True,
            "priority_support": True,
            "family_management": True
        }
    }
}
```

---

## 订阅状态机

```
┌─────────────┐     支付成功      ┌─────────────┐
│   pending   │ ───────────────► │   active    │
└─────────────┘                  └─────────────┘
                                       │
                                       │ 到期/取消
                                       ▼
                                ┌─────────────┐
                                │   expired   │
                                └─────────────┘
                                       │
                                       │ 续费
                                       ▼
                                ┌─────────────┐
                                │   active    │
                                └─────────────┘
```

---

## 订阅购买流程

```python
# 购买流程
PURCHASE_FLOW = {
    "step_1": "选择套餐",
    "step_2": "选择支付方式",
    "step_3": "确认支付",
    "step_4": "支付成功",
    "step_5": "激活订阅"
}

# 支付方式
PAYMENT_METHODS = [
    {"id": "alipay", "name": "支付宝"},
    {"id": "wechat", "name": "微信支付"},
    {"id": "apple_iap", "name": "Apple IAP"},
    {"id": "card", "name": "银行卡"}
]

# 恢复购买
RESTORE_FLOW = {
    "step_1": "用户登录",
    "step_2": "点击恢复购买",
    "step_3": "验证支付凭证",
    "step_4": "恢复订阅状态"
}
```

---

## 礼物订阅

```python
# 礼物场景
GIFT_SUBSCRIPTION = {
    "templates": [
        {
            "id": "birthday",
            "name": "生日祝福",
            "default_duration": 365,
            "price": 268,
            "message_template": "祝您健康长寿"
        },
        {
            "id": "mothers_day",
            "name": "母亲节",
            "default_duration": 180,
            "price": 168,
            "message_template": "妈妈辛苦了"
        },
        {
            "id": "fathers_day",
            "name": "父亲节",
            "default_duration": 180,
            "price": 168,
            "message_template": "爸爸辛苦了"
        },
        {
            "id": "spring_festival",
            "name": "春节",
            "default_duration": 365,
            "price": 268,
            "message_template": "新年快乐"
        },
        {
            "id": "mid_autumn",
            "name": "中秋节",
            "default_duration": 180,
            "price": 168,
            "message_template": "中秋快乐"
        }
    ],
    
    "gift_card": {
        "price": 268,
        "duration": 365,
        "features": [
            "365天 premium 会员",
            "专属祝福语",
            "可定制实体卡/电子卡"
        ]
    }
}
```

---

## 订阅数据库表

```sql
-- 订阅产品表
CREATE TABLE subscription_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    description TEXT,
    monthly_price DECIMAL(10, 2) NOT NULL,
    yearly_price DECIMAL(10, 2),
    duration_days INT NOT NULL,
    features JSONB NOT NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户订阅表
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES subscription_products(id),
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active' 
        CHECK (status IN ('active', 'expired', 'cancelled', 'refunded')),
    payment_method VARCHAR(20),
    transaction_id VARCHAR(100),
    apple_transaction_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 礼物订阅表
CREATE TABLE gift_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    giver_id UUID NOT NULL REFERENCES users(id),
    receiver_phone VARCHAR(20) NOT NULL,
    product_id UUID NOT NULL REFERENCES subscription_products(id),
    start_at TIMESTAMP WITH TIME ZONE,
    end_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending', 'claimed', 'expired')),
    claimed_by_user_id UUID REFERENCES users(id),
    claimed_at TIMESTAMP WITH TIME ZONE,
    gift_message TEXT,
    gift_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 订阅 API

```python
# API 接口

# 获取订阅产品列表
GET /api/v1/subscription/products

# 获取当前订阅状态
GET /api/v1/subscription/current

# 购买订阅
POST /api/v1/subscription/purchase
{
    "product_id": "xxx",
    "payment_method": "alipay"
}

# 取消订阅
POST /api/v1/subscription/cancel

# 恢复订阅
POST /api/v1/subscription/restore

# 验证订阅 (客户端调用)
POST /api/v1/subscription/verify
{
    "receipt": "xxx",
    "platform": "ios"
}

# 礼物订阅 - 创建
POST /api/v1/subscription/gift/create

# 礼物订阅 - 领取
POST /api/v1/subscription/gift/claim
{
    "gift_code": "xxx"
}

# 礼物订阅 - 赠送
POST /api/v1/subscription/gift/send
{
    "receiver_phone": "138xxxx",
    "product_id": "xxx",
    "gift_message": "xxx"
}
```

---

## 订阅前端页面

```dart
// 页面结构
SUBSCRIPTION_PAGES = {
    "subscription_page": {
        "title": "订阅顺时",
        "sections": [
            "当前状态",
            "产品对比",
            "选择套餐",
            "常见问题"
        ]
    },
    "subscription_detail_page": {
        "title": "套餐详情",
        "sections": [
            "套餐介绍",
            "功能列表",
            "价格说明",
            "立即订阅"
        ]
    },
    "gift_page": {
        "title": "送礼物",
        "sections": [
            "选择礼物",
            "填写祝福",
            "支付"
        ]
    }
}
```
