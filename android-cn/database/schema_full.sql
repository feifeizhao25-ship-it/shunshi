-- 顺时数据库完整设计
-- 版本: v1.0.0
-- 日期: 2026-03-09

-- ==================== 用户相关 ====================

-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    avatar VARCHAR(500),
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- 订阅相关
    subscription_type VARCHAR(50) DEFAULT 'free', -- free, premium, family
    subscription_expires_at TIMESTAMP,
    daily_ai_limit INTEGER DEFAULT 5,
    ai_usage_today INTEGER DEFAULT 0,
    
    -- 体质相关
    constitution VARCHAR(50), -- 平和, 气虚, 阳虚, 阴虚, 痰湿, 湿热, 血瘀, 气郁, 特禀
    constitution_identified_at TIMESTAMP,
    
    -- 设置
    notifications_enabled BOOLEAN DEFAULT TRUE,
    ai_tone VARCHAR(50) DEFAULT 'gentle', -- gentle, professional, casual
    reminder_time VARCHAR(10) DEFAULT '10:00',
    language VARCHAR(10) DEFAULT 'zh-CN'
);

-- 用户设备表
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_type VARCHAR(50), -- ios, android
    fcm_token VARCHAR(500),
    last_active_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==================== 对话相关 ====================

-- 对话表
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    last_message_at TIMESTAMP,
    message_count INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT FALSE
);

-- 消息表
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- user, assistant
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- AI 响应额外字段
    tone VARCHAR(50), -- gentle, professional, warm
    care_status VARCHAR(50), -- none, suggested, care_given
    safety_flag VARCHAR(50), -- safe, warning, blocked
    intent VARCHAR(100), -- wellness_advice, emotional_support, etc.
    model_used VARCHAR(50),
    tokens_used INTEGER DEFAULT 0,
    latency_ms INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'
);

-- ==================== 养生内容 ====================

-- 养生内容表
CREATE TABLE wellness_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- solar_term, food, tea, exercise, sleep, emotion
    content JSONB NOT NULL,
    
    -- 适配
    applicable_constitutions JSONB, -- ["气虚", "阳虚"]
    applicable_seasons JSONB, -- ["spring", "summer"]
    applicable_stages JSONB, -- ["youth", "adult"]
    
    -- 状态
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 24节气内容
CREATE TABLE solar_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(20) NOT NULL, -- 立春, 雨水, etc.
    solar_term_date DATE NOT NULL,
    description TEXT,
    climate_features TEXT,
    health_focus TEXT,
    food_suggestions JSONB,
    living_suggestions JSONB,
    exercise_suggestions JSONB,
    emotion_suggestions JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 体质测试结果
CREATE TABLE constitution_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    answers JSONB NOT NULL,
    result VARCHAR(50),
    confidence FLOAT,
    taken_at TIMESTAMP DEFAULT NOW()
);

-- ==================== 习惯与日记 ====================

-- 习惯表
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    habit_type VARCHAR(50), -- exercise, sleep, diet, mood, custom
    frequency VARCHAR(50), -- daily, weekly
    reminder_time VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 习惯打卡记录
CREATE TABLE habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    completed_at TIMESTAMP DEFAULT NOW(),
    note TEXT,
    metadata JSONB DEFAULT '{}'
);

-- 养生日记
CREATE TABLE wellness_journals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood VARCHAR(50),
    sleep_hours FLOAT,
    sleep_quality VARCHAR(20),
    exercise_minutes INTEGER,
    diet_notes TEXT,
    journal_text TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ==================== 家庭系统 ====================

-- 家庭组
CREATE TABLE family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    owner_id UUID REFERENCES users(id),
    invite_code VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 家庭成员
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES family_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    role VARCHAR(50), -- owner, parent, child, elder
    name VARCHAR(255) NOT NULL,
    stage VARCHAR(50), -- youth, adult, middle_age, elder
    constitution VARCHAR(50),
    joined_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(family_id, user_id)
);

-- 家庭关怀记录
CREATE TABLE family_care_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES family_groups(id) ON DELETE CASCADE,
    from_user_id UUID REFERENCES users(id),
    to_member_id UUID REFERENCES family_members(id),
    care_type VARCHAR(50), -- reminder, greeting, alert
    message TEXT,
    sent_at TIMESTAMP DEFAULT NOW()
);

-- ==================== 通知系统 ====================

-- 通知表
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    notification_type VARCHAR(50), -- reminder, system, care, promotion
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT NOW(),
    read_at TIMESTAMP
);

-- ==================== 订阅系统 ====================

-- 订阅记录
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan_type VARCHAR(50) NOT NULL, -- free, monthly, yearly
    payment_method VARCHAR(50), -- apple, google, wechat, alipay
    transaction_id VARCHAR(255),
    started_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    auto_renew BOOLEAN DEFAULT FALSE
);

-- ==================== 审计日志 ====================

-- AI 请求日志
CREATE TABLE ai_request_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    request_type VARCHAR(50), -- chat, skill, report
    api_path VARCHAR(100),
    prompt TEXT,
    model_used VARCHAR(50),
    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,
    latency_ms INTEGER DEFAULT 0,
    cost_usd FLOAT DEFAULT 0,
    status VARCHAR(20), -- success, error, fallback
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ==================== 索引 ====================

-- 用户索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription ON users(subscription_type);

-- 对话索引
CREATE INDEX idx_conversations_user ON conversations(user_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at);

-- 消息索引
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at);

-- 习惯索引
CREATE INDEX idx_habits_user ON habits(user_id);
CREATE INDEX idx_habit_logs_habit ON habit_logs(habit_id);
CREATE INDEX idx_habit_logs_date ON habit_logs(completed_at);

-- 日记索引
CREATE INDEX idx_journals_user_date ON wellness_journals(user_id, date);

-- 家庭索引
CREATE INDEX idx_family_members_user ON family_members(user_id);
CREATE INDEX idx_family_invite ON family_groups(invite_code);

-- 通知索引
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- 审计索引
CREATE INDEX idx_ai_logs_user ON ai_request_logs(user_id);
CREATE INDEX idx_ai_logs_created ON ai_request_logs(created_at);
