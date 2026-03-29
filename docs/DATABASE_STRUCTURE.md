# 顺时完整数据库结构（生产级 SQL）

> 可直接开发的完整数据库设计

---

## 一、核心表结构总览

```sql
-- ============================================================
-- 顺时数据库 - 核心用户表
-- ============================================================

-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 基础信息
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(255) UNIQUE,
    name VARCHAR(100),
    avatar_url VARCHAR(500),
    password_hash VARCHAR(255),
    
    -- 生命周期（核心）
    birth_date DATE,
    age INT,
    life_stage VARCHAR(20) DEFAULT 'exploration' CHECK (life_stage IN ('exploration', 'stress', 'health', 'companionship')),
    age_group VARCHAR(20) DEFAULT 'young_adult' CHECK (age_group IN ('young_adult', 'mid_adult', 'middle_aged', 'senior', 'elderly')),
    family_role VARCHAR(20) DEFAULT 'self' CHECK (family_role IN ('self', 'parent', 'child', 'spouse', 'sibling')),
    
    -- 首次进入来源（用于阶段判断）
    initial_stage_source VARCHAR(50),  -- 'questionnaire', 'behavior', 'manual'
    onboarding_answers JSONB,  -- 首次问卷答案
    
    -- 用户设置
    timezone VARCHAR(50) DEFAULT 'Asia/Shanghai',
    language VARCHAR(10) DEFAULT 'zh-CN',
    notification_enabled BOOLEAN DEFAULT TRUE,
    quiet_hours_start TIME DEFAULT '23:00',
    quiet_hours_end TIME DEFAULT '07:00',
    memory_enabled BOOLEAN DEFAULT TRUE,
    proactive_enabled BOOLEAN DEFAULT TRUE,
    
    -- 偏好
    preferences JSONB DEFAULT '{}',
    constraints JSONB DEFAULT '{}',  -- 禁忌、过敏等
    
    -- 订阅
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'family', 'enterprise')),
    subscription_expires_at TIMESTAMP,
    subscription_auto_renew BOOLEAN DEFAULT FALSE,
    
    -- 设备
    last_device_type VARCHAR(20),
    last_login_at TIMESTAMP,
    last_active_at TIMESTAMP,
    
    -- GDPR 合规
    data_export_requested_at TIMESTAMP,
    data_deleted_at TIMESTAMP,
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 用户索引
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_life_stage ON users(life_stage);
CREATE INDEX idx_users_subscription ON users(subscription_tier);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================================
-- 用户画像表（用于快速查询）
-- ============================================================

CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- 阶段画像
    current_stage VARCHAR(20),
    stage_confidence FLOAT DEFAULT 0.5,  -- 判断置信度
    stage_updated_at TIMESTAMP,
    
    -- 偏好画像
    preferred_tone VARCHAR(20),  -- gentle, cheerful, professional
    preferred_detail_level VARCHAR(20),  -- short, medium, detailed
    preferred_response_style JSONB,
    
    -- 行为画像
    avg_response_length INT,
    avg_session_duration INT,  -- 秒
    preferred_features JSONB,  -- 功能使用偏好
    active_hours JSONB,  -- {"morning": 30, "afternoon": 20, "evening": 50}
    
    -- 累计数据
    total_conversations INT DEFAULT 0,
    total_messages INT DEFAULT 0,
    membership_days INT DEFAULT 0,
    
    -- AI 关系
    memory_summary TEXT,  -- AI 记忆摘要
    last_memory_update TIMESTAMP,
    
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 对话表
-- ============================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 对话内容
    role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'voice', 'card', 'image')),
    
    -- AI 元数据
    intent VARCHAR(50),
    skill_used VARCHAR(50),
    prompt_version JSONB,
    model_used VARCHAR(50),
    
    -- 质量指标
    tokens_in INT,
    tokens_out INT,
    latency_ms INT,
    
    -- 安全标记
    safety_flag VARCHAR(20) DEFAULT 'none' CHECK (safety_flag IN ('none', 'sensitive', 'abnormal')),
    safety_reason VARCHAR(255),
    
    -- 卡片（如有）
    cards JSONB,
    
    -- 上下文
    conversation_context JSONB,  -- 对话历史摘要
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- 对话索引
CREATE INDEX idx_conversations_user ON conversations(user_id, created_at DESC);
CREATE INDEX idx_conversations_intent ON conversations(intent);
CREATE INDEX idx_conversations_skill ON conversations(skill_used);
CREATE INDEX idx_conversations_safety ON conversations(safety_flag);

-- ============================================================
-- 记忆表（用户长记忆）
-- ============================================================

CREATE TABLE user_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 记忆内容
    memory_type VARCHAR(30) NOT NULL CHECK (memory_type IN (
        'preference',      -- 偏好
        'routine',         -- 习惯
        'trend',           -- 趋势
        'milestone',       -- 里程碑
        'relationship',     -- 关系
        '忌'               -- 禁止记录
    )),
    
    content TEXT NOT NULL,
    importance INT DEFAULT 5 CHECK (importance BETWEEN 1 AND 10),
    
    -- 来源
    source_message_id UUID REFERENCES conversations(id),
    source_context JSONB,
    
    -- 元数据
    tags JSONB,
    expires_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 记忆索引
CREATE INDEX idx_memories_user ON user_memories(user_id, memory_type);
CREATE INDEX idx_memories_importance ON user_memories(user_id, importance DESC);
CREATE INDEX idx_memories_expires ON user_memories(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================================
-- 今日节律表
-- ============================================================

CREATE TABLE daily_rhythms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    
    -- 节律数据
    sleep_data JSONB,  -- {"bedtime": "23:00", "wake_time": "07:00", "quality": 85}
    mood_data JSONB,   -- {"morning": 70, "afternoon": 65, "evening": 60}
    activity_data JSONB,  -- {"steps": 8000, "exercise_minutes": 30}
    diet_data JSONB,   -- {"meals": 3, "water_glasses": 8}
    
    -- AI 生成内容
    insight TEXT,  -- 今日洞察
    actions JSONB,  -- 今日行动建议
    generated_card JSONB,  -- 生成的卡片
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

-- 今日节律索引
CREATE INDEX idx_daily_rhythms_user_date ON daily_rhythms(user_id, date DESC);

-- ============================================================
-- 照护状态表
-- ============================================================

CREATE TABLE care_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 状态
    overall_status VARCHAR(20) DEFAULT 'stable' CHECK (overall_status IN ('stable', 'needs_attention', 'escalated')),
    emotion_score INT CHECK (emotion_score BETWEEN 0 AND 100),
    energy_score INT CHECK (energy_score BETWEEN 0 AND 100),
    health_score INT CHECK (health_score BETWEEN 0 AND 100),
    
    -- 趋势
    emotion_trend VARCHAR(20) DEFAULT 'stable' CHECK (emotion_trend IN ('improving', 'stable', 'declining')),
    energy_trend VARCHAR(20) DEFAULT 'stable',
    health_trend VARCHAR(20) DEFAULT 'stable',
    
    -- 触发因素
    triggers JSONB,  -- [{"type": "emotion", "reason": "negative_message"}]
    
    -- 风险标记
    risk_signals JSONB,
    
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_care_status_user ON care_status(user_id);

-- ============================================================
-- 照护状态历史
-- ============================================================

CREATE TABLE care_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 快照
    overall_status VARCHAR(20),
    emotion_score INT,
    energy_score INT,
    health_score INT,
    emotion_trend VARCHAR(20),
    
    -- 原因
    reason_code VARCHAR(50),
    reason_detail TEXT,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_care_status_history_user ON care_status_history(user_id, created_at DESC);

-- ============================================================
-- Follow-up 任务表
-- ============================================================

CREATE TABLE follow_up_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 任务内容
    intent VARCHAR(50) NOT NULL,  -- sleep_check, emotion_check, habit_check
    message_hint TEXT,
    
    -- 调度
    scheduled_at TIMESTAMP NOT NULL,
    max_reminders INT DEFAULT 3,
    current_reminders INT DEFAULT 0,
    
    -- 状态
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'completed', 'cancelled', 'expired')),
    
    -- 来源
    source_message_id UUID REFERENCES conversations(id),
    
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX idx_follow_up_tasks_scheduled ON follow_up_tasks(scheduled_at, status);
CREATE INDEX idx_follow_up_tasks_user ON follow_up_tasks(user_id, status);

-- ============================================================
-- 家庭关系表
-- ============================================================

CREATE TABLE family_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    related_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 关系
    relation_type VARCHAR(20) NOT NULL CHECK (relation_type IN ('parent', 'child', 'spouse', 'sibling')),
    
    -- 权限
    permission_level VARCHAR(20) DEFAULT 'view_trend' CHECK (permission_level IN ('none', 'view_trend', 'view_detail', 'manage')),
    
    -- 照护设置
    care_level VARCHAR(20) DEFAULT 'normal' CHECK (care_level IN ('normal', 'intensive')),
    notification_enabled BOOLEAN DEFAULT TRUE,
    notify_on_status_change BOOLEAN DEFAULT TRUE,
    
    -- 隐私
    can_view_conversations BOOLEAN DEFAULT FALSE,
    can_view_health_data BOOLEAN DEFAULT FALSE,
    
    -- 同意
    consent_given BOOLEAN DEFAULT FALSE,
    consent_given_at TIMESTAMP,
    
    -- 状态
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending', 'rejected')),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, related_user_id)
);

CREATE INDEX idx_family_relations_user ON family_relations(user_id);
CREATE INDEX idx_family_relations_related ON family_relations(related_user_id);

-- ============================================================
-- 家庭摘要缓存表
-- ============================================================

CREATE TABLE family_digest_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id VARCHAR(36) NOT NULL,  -- 家庭ID（主用户ID）
    
    -- 成员摘要
    members_summary JSONB NOT NULL,  -- [{"user_id": "...", "name": "...", "status": "stable", "trend": "improving"}]
    
    -- 建议
    recommendations JSONB,
    
    -- 缓存信息
    generated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    
    UNIQUE(family_id)
);

-- ============================================================
-- 订阅表
-- ============================================================

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 订阅信息
    tier VARCHAR(20) NOT NULL CHECK (tier IN ('free', 'premium', 'family', 'enterprise')),
    
    -- 计费
    billing_cycle VARCHAR(10) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
    amount DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'CNY',
    
    -- 时间
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT FALSE,
    
    -- 支付
    payment_method VARCHAR(20),
    payment_transaction_id VARCHAR(100),
    
    -- 来源
    source VARCHAR(50),  -- 'purchase', 'gift', 'trial', 'enterprise'
    gift_from_user_id UUID REFERENCES users(id),
    
    -- 状态
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'failed')),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id, status);
CREATE INDEX idx_subscriptions_end_date ON subscriptions(end_date);

-- ============================================================
-- 礼品卡表
-- ============================================================

CREATE TABLE gift_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 卡信息
    code VARCHAR(50) UNIQUE NOT NULL,
    duration_days INT NOT NULL,
    tier VARCHAR(20) DEFAULT 'premium',
    amount DECIMAL(10, 2),
    
    -- 状态
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'redeemed', 'expired', 'cancelled')),
    
    -- 领取
    redeemed_by_user_id UUID REFERENCES users(id),
    redeemed_at TIMESTAMP,
    
    -- 到期
    expires_at TIMESTAMP NOT NULL,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gift_cards_code ON gift_cards(code);
CREATE INDEX idx_gift_cards_status ON gift_cards(status);

-- ============================================================
-- Skills 表
-- ============================================================

CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Skill 信息
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(30),  -- 'daily', 'emotion', 'sleep', 'health', 'family'
    
    -- 版本
    version VARCHAR(20) NOT NULL DEFAULT 'v1.0',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Prompt
    system_prompt TEXT,
    task_prompt TEXT,
    
    -- 输出 Schema
    output_schema JSONB,
    
    -- 配置
    config JSONB DEFAULT '{}',  -- {"temperature": 0.7, "max_tokens": 1000}
    
    -- 缓存
    cacheable BOOLEAN DEFAULT FALSE,
    cache_ttl_seconds INT DEFAULT 86400,
    
    -- 付费要求
    min_tier VARCHAR(20) DEFAULT 'free',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_skills_name ON skills(name);
CREATE INDEX idx_skills_category ON skills(category);
CREATE INDEX idx_skills_active ON skills(is_active);

-- ============================================================
-- Prompt 版本表
-- ============================================================

CREATE TABLE prompt_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 版本信息
    prompt_type VARCHAR(30) NOT NULL,  -- 'core', 'policy', 'task', 'skill'
    name VARCHAR(50) NOT NULL,
    version VARCHAR(20) NOT NULL,
    
    -- 内容
    content TEXT NOT NULL,
    
    -- 状态
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'testing', 'active', 'deprecated')),
    
    -- 灰度
    rollout_percentage INT DEFAULT 0,
    target_users JSONB,  -- {"life_stages": ["exploration"], "regions": ["CN"]}
    
    -- 元数据
    changelog TEXT,
    created_by VARCHAR(50),
    
    created_at TIMESTAMP DEFAULT NOW(),
    activated_at TIMESTAMP,
    deprecated_at TIMESTAMP,
    
    UNIQUE(prompt_type, name, version)
);

CREATE INDEX idx_prompt_versions_status ON prompt_versions(status);
CREATE INDEX idx_prompt_versions_active ON prompt_versions(prompt_type, status);

-- ============================================================
-- 内容表（轻量级知识库）
-- ============================================================

CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 元数据
    type VARCHAR(30) NOT NULL CHECK (type IN ('article', 'video', 'audio', 'recipe', 'exercise', 'acupoint')),
    category VARCHAR(50) NOT NULL,
    title VARCHAR(500) NOT NULL,
    summary TEXT,
    body TEXT,
    
    -- 来源
    source VARCHAR(200),
    author VARCHAR(100),
    verified BOOLEAN DEFAULT FALSE,
    verified_by VARCHAR(50),
    
    -- 标签
    tags TEXT[],
    suitable_age_groups VARCHAR(20)[],
    suitable_constitutions VARCHAR(20)[],
    contraindications TEXT[],
    
    -- 媒体
    images TEXT[],
    video_url VARCHAR(500),
    audio_url VARCHAR(500),
    
    -- 时效
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    solar_terms VARCHAR(20)[],
    seasons VARCHAR(20)[],
    
    -- 质量
    view_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
   收藏count INT DEFAULT 0,
    
    -- 状态
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived')),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_contents_type ON contents(type, category);
CREATE INDEX idx_contents_tags ON contents USING GIN(tags);
CREATE INDEX idx_contents_status ON contents(status);

-- ============================================================
-- 用户收藏表
-- ============================================================

CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 收藏类型
    favorite_type VARCHAR(20) NOT NULL CHECK (favorite_type IN ('content', 'card', 'conversation', 'skill')),
    favorite_id VARCHAR(36) NOT NULL,
    
    -- 收藏内容快照
    snapshot JSONB,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, favorite_type, favorite_id)
);

CREATE INDEX idx_user_favorites_user ON user_favorites(user_id, favorite_type);

-- ============================================================
-- AI 日志表（审计）
-- ============================================================

CREATE TABLE ai_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 请求信息
    request_id VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id),
    
    -- 路由信息
    skill VARCHAR(50),
    intent VARCHAR(50),
    
    -- Prompt 版本
    prompt_version JSONB,
    
    -- 模型信息
    model_used VARCHAR(50),
    model_provider VARCHAR(20),
    
    -- Token 信息
    input_tokens INT,
    output_tokens INT,
    total_tokens INT GENERATED ALWAYS AS (input_tokens + output_tokens) STORED,
    
    -- 性能
    latency_ms INT,
    first_token_ms INT,
    
    -- 结果
    safety_flag VARCHAR(20) DEFAULT 'none',
    schema_valid BOOLEAN DEFAULT TRUE,
    cache_hit BOOLEAN DEFAULT FALSE,
    
    -- 错误
    error_code VARCHAR(50),
    error_message TEXT,
    
    -- 设备信息
    device_type VARCHAR(20),
    app_version VARCHAR(20),
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- 日志分区（按月）
CREATE INDEX idx_ai_logs_user ON ai_logs(user_id, created_at DESC);
CREATE INDEX idx_ai_logs_skill ON ai_logs(skill, created_at DESC);
CREATE INDEX idx_ai_logs_model ON ai_logs(model_used, created_at DESC);

-- ============================================================
-- 安全事件表
-- ============================================================

CREATE TABLE safety_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 事件信息
    event_type VARCHAR(50) NOT NULL,  -- 'crisis', 'medical', 'privacy', 'abuse'
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    
    -- 用户
    user_id UUID REFERENCES users(id),
    user_message TEXT,
    
    -- AI 响应
    ai_response TEXT,
    
    -- 处理
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'escalated')),
    reviewed_by VARCHAR(50),
    review_notes TEXT,
    
    -- 升级
    escalated_to VARCHAR(50),  -- 'family', 'emergency_contact', 'authority'
    escalation_result TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

CREATE INDEX idx_safety_events_user ON safety_events(user_id, created_at DESC);
CREATE INDEX idx_safety_events_status ON safety_events(status);
CREATE INDEX idx_safety_events_type ON safety_events(event_type);

-- ============================================================
-- 企业用户表
-- ============================================================

CREATE TABLE enterprises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 企业信息
    name VARCHAR(200) NOT NULL,
    industry VARCHAR(50),
    employee_count_range VARCHAR(20),
    
    -- 联系人
    contact_name VARCHAR(100),
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    
    -- 订阅
    subscription_tier VARCHAR(20) DEFAULT 'enterprise',
    seats_total INT DEFAULT 0,
    seats_used INT DEFAULT 0,
    
    -- 合同
    contract_id VARCHAR(50),
    start_date DATE,
    end_date DATE,
    
    -- 状态
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'trial', 'suspended', 'cancelled')),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 企业用户关联
CREATE TABLE enterprise_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enterprise_id UUID NOT NULL REFERENCES enterprises(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'manager', 'member')),
    status VARCHAR(20) DEFAULT 'active',
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(enterprise_id, user_id)
);

-- ============================================================
-- 设备表（未来扩展）
-- ============================================================

CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 设备信息
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('phone', 'watch', 'speaker', 'tv', 'car')),
    device_id VARCHAR(100) NOT NULL,
    device_name VARCHAR(100),
    
    -- 推送
    push_token VARCHAR(500),
    push_enabled BOOLEAN DEFAULT TRUE,
    
    -- 设置
    notification_settings JSONB DEFAULT '{}',
    
    -- 状态
    last_active_at TIMESTAMP,
    is_primary BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, device_type, device_id)
);

-- ============================================================
-- 审计日志表
-- ============================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 操作信息
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(36),
    
    -- 详情
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- 结果
    status VARCHAR(20) DEFAULT 'success',
    error_message TEXT,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);

-- ============================================================
-- 函数与触发器
-- ============================================================

-- 更新时间触发器
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 用户更新时间触发器
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- 对话创建时更新用户统计
CREATE OR REPLACE FUNCTION update_user_conversation_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'user' THEN
        UPDATE users 
        SET total_messages = COALESCE(total_messages, 0) + 1,
            last_active_at = NOW()
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER conversations_after_insert
    AFTER INSERT ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_user_conversation_stats();

-- ============================================================
-- 视图：用户行为摘要
-- ============================================================

CREATE VIEW user_activity_summary AS
SELECT 
    u.id as user_id,
    u.life_stage,
    u.subscription_tier,
    u.created_at as member_since,
    COUNT(DISTINCT c.id) as total_conversations,
    COUNT(DISTINCT c.message) as total_messages,
    MAX(c.created_at) as last_conversation_at,
    COALESCE(
        (SELECT COUNT(*) FROM user_memories WHERE user_id = u.id AND memory_type = 'preference'),
        0
    ) as preference_memories
FROM users u
LEFT JOIN conversations c ON c.user_id = u.id
GROUP BY u.id, u.life_stage, u.subscription_tier, u.created_at;

-- ============================================================
-- 视图：家庭摘要
-- ============================================================

CREATE VIEW family_summary AS
SELECT 
    fr.user_id as primary_user_id,
    fr.related_user_id,
    u.name as member_name,
    u.life_stage as member_life_stage,
    cs.overall_status as member_care_status,
    cs.emotion_trend,
    fr.relation_type,
    fr.notification_enabled,
    fr.status as relation_status
FROM family_relations fr
JOIN users u ON u.id = fr.related_user_id
LEFT JOIN care_status cs ON cs.user_id = fr.related_user_id
WHERE fr.status = 'active';

-- ============================================================
-- RLS 策略（行级安全）
-- ============================================================

-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_relations ENABLE ROW LEVEL SECURITY;

-- 用户只能看到自己的数据
CREATE POLICY users_select ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY conversations_select ON conversations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY user_memories_select ON user_memories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY family_relations_select ON family_relations FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = related_user_id);
```

---

## 二、数据字典

### users（用户表）

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| id | UUID | 主键 | - |
| phone | VARCHAR(20) | 手机号 | 13800138000 |
| email | VARCHAR(255) | 邮箱 | user@example.com |
| name | VARCHAR(100) | 昵称 | feifei |
| life_stage | VARCHAR(20) | 人生阶段 | exploration/stress/health/companionship |
| age_group | VARCHAR(20) | 年龄组 | young_adult/mid_adult/middle_aged/senior/elderly |
| subscription_tier | VARCHAR(20) | 订阅等级 | free/premium/family/enterprise |
| memory_enabled | BOOLEAN | 记忆开关 | true |
| quiet_hours_start | TIME | 免打扰开始 | 23:00 |

### conversations（对话表）

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| id | UUID | 主键 | - |
| user_id | UUID | 用户ID | - |
| role | VARCHAR(10) | 角色 | user/assistant/system |
| message | TEXT | 消息内容 | 最近睡眠不好 |
| intent | VARCHAR(50) | 意图 | sleep |
| skill_used | VARCHAR(50) | 使用的Skill | SleepWindDown |
| safety_flag | VARCHAR(20) | 安全标记 | none/sensitive/abnormal |

### user_memories（记忆表）

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| memory_type | VARCHAR(30) | 记忆类型 | preference/routine/trend |
| content | TEXT | 记忆内容 | 用户喜欢喝红茶 |
| importance | INT | 重要程度1-10 | 7 |
| expires_at | TIMESTAMP | 过期时间 | - |

---

## 三、ER 图关系

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   users    │──────▶│conversations│◀────│ user_      │
│             │       │             │     │ memories   │
└─────────────┘       └─────────────┘       └─────────────┘
      │                     │                     │
      │                     │                     │
      ▼                     ▼                     ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│care_status  │       │  ai_logs   │       │user_favorites│
│             │       │             │       │             │
└─────────────┘       └─────────────┘       └─────────────┘
      │
      │
      ▼
┌─────────────┐       ┌─────────────┐
│family_       │       │subscriptions│
│relations     │       │             │
└─────────────┘       └─────────────┘
```

---

## 四、总结

```
数据库设计要点：

1. 用户核心
   - 生命周期（life_stage）
   - 订阅体系
   - 隐私合规

2. 对话与记忆
   - 完整对话历史
   - 长期记忆系统
   - 审计日志

3. 家庭系统
   - 关系管理
   - 隐私权限
   - 摘要缓存

4. AI 支持
   - Skills 版本管理
   - Prompt 版本控制
   - 安全事件追踪

5. 扩展性
   - 企业用户
   - 设备管理
   - 审计日志
```
