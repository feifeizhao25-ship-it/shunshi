# 顺时 ShunShi 家庭系统设计

## 家庭系统架构

```
家庭系统
├── 家庭组 (Family Group)
├── 家庭成员 (Family Members)
├── 家庭动态 (Family Digest)
├── 关怀消息 (Care Messages)
└── 权限管理 (Permissions)
```

---

## 家庭角色

```python
# 家庭角色定义
FAMILY_ROLES = {
    "owner": {
        "name": "家长",
        "permissions": [
            "manage_family",
            "invite_members",
            "remove_members",
            "view_all_members",
            "send_care",
            "receive_care"
        ],
        "description": "创建家庭者，拥有全部权限"
    },
    "parent": {
        "name": "父母",
        "permissions": [
            "view_family",
            "send_care",
            "receive_care",
            "manage_own_profile"
        ],
        "description": "被子女邀请的长辈"
    },
    "spouse": {
        "name": "配偶",
        "permissions": [
            "view_family",
            "send_care",
            "receive_care",
            "manage_own_profile"
        ],
        "description": "夫妻关系"
    },
    "child": {
        "name": "子女",
        "permissions": [
            "view_family",
            "send_care",
            "receive_care",
            "manage_own_profile"
        ],
        "description": "晚辈"
    }
}

# 照护关系
CARE_RELATIONSHIP = {
    "care_giver": "照护者（子女）",
    "care_recipient": "被照护者（父母）"
}
```

---

## 家庭创建流程

```python
# 创建家庭
CREATE_FAMILY_FLOW = {
    "step_1": "用户点击创建家庭",
    "step_2": "输入家庭名称（可选）",
    "step_3": "生成邀请码",
    "step_4": "邀请家庭成员",
    "step_5": "完成设置"
}

# 邀请家庭成员
INVITE_FLOW = {
    "step_1": "选择邀请方式（手机号/邀请码）",
    "step_2": "选择成员角色",
    "step_3": "发送邀请",
    "step_4": "对方确认",
    "step_5": "加入成功"
}

# 子女为父母开通
PARENT_ONBOARDING = {
    "scenario": "子女为父母注册并开通订阅",
    "flow": [
        "子女在应用中创建家庭",
        "选择为父母开通",
        "填写父母手机号",
        "选择订阅套餐",
        "完成支付",
        "父母收到短信引导",
        "父母下载App并登录"
    ],
    "benefits": [
        "子女可查看父母状态",
        "子女可为父母设置提醒",
        "家庭共享订阅"
    ]
}
```

---

## 家庭动态 (Family Digest)

```python
# 家庭动态类型
DIGEST_TYPES = {
    "daily_summary": "每日摘要",
    "care_received": "收到关怀",
    "care_sent": "发出关怀",
    "habit_completed": "习惯打卡",
    "milestone": "里程碑",
    "alert": "提醒"
}

# 每日家庭摘要内容
DAILY_DIGEST = {
    "date": "2026-03-08",
    "family_id": "xxx",
    "members_summary": [
        {
            "member_id": "xxx",
            "nickname": "爸爸",
            "status": "good",
            "highlights": [
                "完成3次习惯打卡",
                "睡眠时长7小时"
            ]
        }
    ],
    "family_highlights": [
        "家庭成员全部完成打卡",
        "今天还没有关怀消息"
    ],
    "suggestions": [
        "给爸爸发个问候吧"
    ]
}
```

---

## 关怀消息 (Care Message)

```python
# 关怀消息类型
CARE_TYPES = {
    "reminder": {
        "name": "提醒",
        "icon": "🔔",
        "template": "记得 {action}"
    },
    "greeting": {
        "name": "问候",
        "icon": "👋",
        "template": "早上好/晚安"
    },
    "care": {
        "name": "关怀",
        "icon": "💚",
        "template": "在想你"
    },
    "health": {
        "name": "健康提醒",
        "icon": "🏥",
        "template": "今天记得 {action}"
    },
    "custom": {
        "name": "自定义",
        "icon": "💬",
        "template": null
    }
}

# 关怀消息卡片
CARE_MESSAGE = {
    "id": "xxx",
    "type": "care",
    "sender_id": "xxx",
    "sender_name": "女儿",
    "receiver_id": "xxx",
    "content": "妈妈，记得多休息",
    "timestamp": "2026-03-08T10:30:00Z",
    "is_read": false,
    "can_reply": true,
    "can_forward": false
}
```

---

## 家庭权限管理

```python
# 权限定义
PERMISSIONS = {
    "view_family": "查看家庭成员",
    "view_member_detail": "查看成员详情",
    "send_care": "发送关怀",
    "receive_care": "接收关怀",
    "manage_family": "管理家庭设置",
    "invite_members": "邀请成员",
    "remove_members": "移除成员",
    "view_member_health": "查看成员健康数据"
}

# 权限检查
class PermissionChecker:
    def can_view_member_detail(self, viewer, target_member) -> bool:
        # 家长可以查看所有成员
        if viewer.role == "owner":
            return True
        
        # 其他成员只能查看自己的详情
        if viewer.id == target_member.user_id:
            return True
        
        return False
    
    def can_view_health_data(self, viewer, target_member) -> bool:
        # 家长可以查看被照护者的健康数据
        if viewer.role == "owner" and target_member.is_care_recipient:
            return True
        
        return False
```

---

## 家庭数据库表

```sql
-- 家庭组
CREATE TABLE family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    owner_id UUID NOT NULL REFERENCES users(id),
    invite_code VARCHAR(20) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 家庭成员
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL 
        CHECK (role IN ('owner', 'parent', 'spouse', 'child')),
    nickname VARCHAR(100),
    is_care_recipient BOOLEAN DEFAULT FALSE,
    notification_preferences JSONB DEFAULT '{
        "care_messages": true,
        "daily_digest": true,
        "alerts": true
    }',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- 家庭动态摘要
CREATE TABLE family_digests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    digest_date DATE NOT NULL,
    summary_data JSONB NOT NULL,
    member_updates JSONB DEFAULT '[]',
    care_alerts JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, digest_date)
);

-- 家庭邀请
CREATE TABLE family_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES users(id),
    invitee_phone VARCHAR(20),
    role VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'expired', 'rejected')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 关怀消息
CREATE TABLE care_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    receiver_id UUID NOT NULL REFERENCES users(id),
    message_type VARCHAR(30) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 家庭 API

```python
# API 接口

# 获取家庭信息
GET /api/v1/family

# 创建家庭
POST /api/v1/family
{
    "name": "我的家"
}

# 更新家庭设置
PUT /api/v1/family/settings

# 邀请成员
POST /api/v1/family/invite
{
    "phone": "138xxxx",
    "role": "parent"
}

# 使用邀请码加入
POST /api/v1/family/join
{
    "invite_code": "ABC123"
}

# 接受邀请
POST /api/v1/family/invitations/{id}/accept

# 移除成员
DELETE /api/v1/family/members/{id}

# 获取家庭动态
GET /api/v1/family/digest
GET /api/v1/family/digest/{date}

# 发送关怀
POST /api/v1/family/care
{
    "receiver_id": "xxx",
    "message_type": "care",
    "content": "记得多休息"
}

# 获取关怀消息
GET /api/v1/family/care/messages
GET /api/v1/family/care/messages/unread

# 标记已读
PUT /api/v1/family/care/messages/{id}/read
```

---

## 家庭前端页面

```dart
// 页面结构
FAMILY_PAGES = {
    "family_page": {
        "title": "家庭",
        "sections": [
            "家庭头像/名称",
            "成员列表",
            "家庭动态",
            "关怀消息"
        ]
    },
    "family_group_page": {
        "title": "家庭成员",
        "sections": [
            "家长",
            "父母",
            "配偶",
            "子女"
        ]
    },
    "family_invite_page": {
        "title": "邀请家人",
        "sections": [
            "邀请码展示",
            "手机号邀请",
            "邀请方式选择"
        ]
    },
    "family_digest_page": {
        "title": "家庭动态",
        "sections": [
            "今日摘要",
            "成员动态",
            "关怀记录"
        ]
    },
    "care_message_page": {
        "title": "关怀消息",
        "sections": [
            "消息列表",
            "发送关怀"
        ]
    }
}
```

---

## 家庭增长模型

```
家庭网络效应

用户A (子女)
    │
    ├──► 为父母开通 ──► 用户B (父亲)
    │                      │
    │                      └──► 用户C (母亲)
    │
    └──► 伴侣加入 ──► 用户D (配偶)
                          │
                          └──► 家庭群组 (4人)

增长系数: 1个用户平均带来 2-4 个家庭成员
```
