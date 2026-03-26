-- 顺时 ShunShi 数据库 Schema (PostgreSQL)
-- Version: 1.0
-- Target: 生产级千万级用户

-- =====================================================
-- 用户系统
-- =====================================================

-- 用户主表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned', 'deleted')),
    is_premium BOOLEAN DEFAULT FALSE,
    premium_expires_at TIMESTAMP WITH TIME ZONE,
    registration_source VARCHAR(50),
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 用户认证账号 (第三方登录)
CREATE TABLE user_auth_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(20) NOT NULL CHECK (provider IN ('wechat', 'apple', 'phone', 'email')),
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(provider, provider_user_id)
);

CREATE INDEX idx_auth_user_id ON user_auth_accounts(user_id);

-- 用户资料
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    nickname VARCHAR(100),
    avatar_url TEXT,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    birth_date DATE,
    birth_time TIME,
    constellation VARCHAR(20),
    life_stage VARCHAR(20) CHECK (life_stage IN ('exploring', 'stressed', 'healthy', 'companion')),
    bio TEXT,
    location VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_profile_user_id ON user_profiles(user_id);
CREATE INDEX idx_profile_life_stage ON user_profiles(life_stage);

-- 用户设置
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'zh_CN',
    theme VARCHAR(20) DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'system')),
    font_size VARCHAR(10) DEFAULT 'medium' CHECK (font_size IN ('small', 'medium', 'large')),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    notification_settings JSONB DEFAULT '{}',
    quiet_hours_start TIME DEFAULT '23:00',
    quiet_hours_end TIME DEFAULT '08:00',
    memory_enabled BOOLEAN DEFAULT TRUE,
    presence_level VARCHAR(20) DEFAULT 'normal' CHECK (presence_level IN ('normal', 'reduced', 'silent')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 生命周期历史
CREATE TABLE life_stage_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    life_stage VARCHAR(20) NOT NULL,
    confidence FLOAT DEFAULT 1.0,
    source VARCHAR(50) DEFAULT 'manual',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_life_stage_user_id ON life_stage_history(user_id);
CREATE INDEX idx_life_stage_started_at ON life_stage_history(started_at);

-- =====================================================
-- 对话系统
-- =====================================================

-- 对话
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    type VARCHAR(20) DEFAULT 'chat' CHECK (type IN ('chat', 'voice', 'follow_up')),
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_ai_response JSONB,
    message_count INT DEFAULT 0,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at);

-- 消息
CREATE TABLE conversation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    content_type VARCHAR(20) DEFAULT 'text' CHECK (content_type IN ('text', 'voice', 'image', 'structured')),
    metadata JSONB DEFAULT '{}',
    safety_flag BOOLEAN DEFAULT FALSE,
    model_used VARCHAR(50),
    skill_code VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_id ON conversation_messages(conversation_id);
CREATE INDEX idx_messages_created_at ON conversation_messages(created_at);
CREATE INDEX idx_messages_role ON conversation_messages(role);

-- =====================================================
-- 记忆系统
-- =====================================================

-- 记忆快照 (不存原文，只存摘要)
CREATE TABLE memory_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    snapshot_type VARCHAR(50) NOT NULL,
    summary TEXT NOT NULL,
    key_points JSONB DEFAULT '[]',
    emotional_tone VARCHAR(20),
    importance_score FLOAT DEFAULT 0.5,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_memory_user_id ON memory_snapshots(user_id);
CREATE INDEX idx_memory_type ON memory_snapshots(snapshot_type);
CREATE INDEX idx_memory_created_at ON memory_snapshots(created_at);

-- 人生阶段总结
CREATE TABLE life_phase_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phase VARCHAR(50) NOT NULL,
    summary TEXT NOT NULL,
    key_events JSONB DEFAULT '[]',
    themes JSONB DEFAULT '[]',
    period_start DATE NOT NULL,
    period_end DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 照护状态历史
CREATE TABLE care_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    care_status VARCHAR(20) NOT NULL,
    trigger_event VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_care_status_user_id ON care_status_history(user_id);

-- =====================================================
-- Skills 与内容系统
-- =====================================================

-- Skills 注册表
CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    category VARCHAR(30) NOT NULL,
    description TEXT,
    input_schema JSONB NOT NULL,
    output_schema JSONB NOT NULL,
    is_premium BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    version VARCHAR(20) DEFAULT '1.0.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_skills_code ON skills(code);
CREATE INDEX idx_skills_category ON skills(category);

-- Skill Prompt 版本
CREATE TABLE skill_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    version VARCHAR(20) NOT NULL,
    prompt_content TEXT NOT NULL,
    safety_constraints JSONB DEFAULT '[]',
    caching_strategy VARCHAR(20) DEFAULT 'none',
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    rollout_percentage INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(skill_id, version)
);

-- 内容项
CREATE TABLE content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(30) NOT NULL CHECK (type IN ('food', 'tea', 'acupoint', 'movement', 'sleep', 'emotion', 'solar_term')),
    title VARCHAR(200) NOT NULL,
    title_en VARCHAR(200),
    subtitle VARCHAR(300),
    description TEXT,
    tags JSONB DEFAULT '[]',
    content JSONB NOT NULL,
    media_urls JSONB DEFAULT '[]',
    contraindications JSONB DEFAULT '[]',
    alternatives JSONB DEFAULT '[]',
    source VARCHAR(100),
    is_premium BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_content_type ON content_items(type);
CREATE INDEX idx_content_tags ON content_items USING GIN(tags);
CREATE INDEX idx_content_created_at ON content_items(created_at);

-- 内容集
CREATE TABLE content_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    content_ids UUID[] DEFAULT '{}',
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 计划与习惯系统
-- =====================================================

-- 每日计划
CREATE TABLE daily_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_date DATE NOT NULL,
    plan_data JSONB NOT NULL,
    completion_rate FLOAT DEFAULT 0.0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, plan_date)
);

CREATE INDEX idx_daily_plans_user_date ON daily_plans(user_id, plan_date);

-- 习惯
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    category VARCHAR(30),
    frequency VARCHAR(20) DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekly', 'custom')),
    target_count INT DEFAULT 1,
    reminder_time TIME,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_habits_user_id ON habits(user_id);

-- 习惯打卡记录
CREATE TABLE habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    completed_count INT DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(habit_id, log_date)
);

CREATE INDEX idx_habit_logs_user_date ON habit_logs(user_id, log_date);

-- 养生日志
CREATE TABLE wellness_journals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    journal_type VARCHAR(30) NOT NULL,
    content JSONB NOT NULL,
    mood_score INT,
    energy_score INT,
    sleep_quality INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_wellness_journals_user_date ON wellness_journals(user_id, created_at);

-- =====================================================
-- 节气系统
-- =====================================================

-- 节气表
CREATE TABLE solar_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(20) NOT NULL UNIQUE,
    name_en VARCHAR(20),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    solar_term_type VARCHAR(20),
    eat_suggestions JSONB DEFAULT '[]',
    move_suggestions JSONB DEFAULT '[]',
    sleep_suggestions JSONB DEFAULT '[]',
    mood_suggestions JSONB DEFAULT '[]',
    proverb VARCHAR(255),
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_solar_terms_date ON solar_terms(start_date);

-- 体质测试
CREATE TABLE constitution_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    answers JSONB NOT NULL,
    result_type VARCHAR(30),
    result_data JSONB,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 家庭系统
-- =====================================================

-- 家庭组
CREATE TABLE family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100),
    owner_id UUID NOT NULL REFERENCES users(id),
    invite_code VARCHAR(20) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_family_invite_code ON family_groups(invite_code);

-- 家庭成员
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'parent', 'spouse', 'child')),
    nickname VARCHAR(100),
    is_care_recipient BOOLEAN DEFAULT FALSE,
    notification_preferences JSONB DEFAULT '{}',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

CREATE INDEX idx_family_members_family_id ON family_members(family_id);
CREATE INDEX idx_family_members_user_id ON family_members(user_id);

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
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'rejected')),
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
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_care_messages_family_id ON care_messages(family_id);
CREATE INDEX idx_care_messages_created_at ON care_messages(created_at);

-- =====================================================
-- 通知与跟进系统
-- =====================================================

-- 通知
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL,
    title VARCHAR(100) NOT NULL,
    body TEXT,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- 跟进计划
CREATE TABLE follow_up_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    follow_up_type VARCHAR(30) NOT NULL,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    message TEXT,
    is_sent BOOLEAN DEFAULT FALSE,
    is_ignored BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_follow_up_user_scheduled ON follow_up_plans(user_id, scheduled_at);

-- =====================================================
-- 订阅与支付系统
-- =====================================================

-- 订阅产品
CREATE TABLE subscription_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    description TEXT,
    duration_days INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    features JSONB DEFAULT '[]',
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户订阅
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES subscription_products(id),
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'refunded')),
    payment_method VARCHAR(20),
    transaction_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_subscriptions_end_at ON user_subscriptions(end_at);

-- 礼物订阅
CREATE TABLE gift_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    giver_id UUID NOT NULL REFERENCES users(id),
    receiver_phone VARCHAR(20) NOT NULL,
    product_id UUID NOT NULL REFERENCES subscription_products(id),
    start_at TIMESTAMP WITH TIME ZONE,
    end_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'claimed', 'expired')),
    claimed_by_user_id UUID REFERENCES users(id),
    claimed_at TIMESTAMP WITH TIME ZONE,
    gift_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 审计与评测系统
-- =====================================================

-- 审计日志
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    request_data JSONB DEFAULT '{}',
    response_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    duration_ms INT,
    status_code INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- 创建月度分区
CREATE TABLE audit_logs_2026_03 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- AI 评测结果
CREATE TABLE ai_eval_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    eval_type VARCHAR(50) NOT NULL,
    test_case_id VARCHAR(100),
    prompt_version VARCHAR(20),
    input_data JSONB NOT NULL,
    output_data JSONB,
    scores JSONB DEFAULT '{}',
    safety_result VARCHAR(20),
    pass_result BOOLEAN,
    model_used VARCHAR(50),
    duration_ms INT,
    evaluator VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ai_eval_type ON ai_eval_results(eval_type);
CREATE INDEX idx_ai_eval_created_at ON ai_eval_results(created_at);

-- =====================================================
-- 公共函数与触发器
-- =====================================================

-- 更新时间戳触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有有 updated_at 的表创建触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_habits_updated_at BEFORE UPDATE ON habits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_groups_updated_at BEFORE UPDATE ON family_groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 生成邀请码函数
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := '';
    i INT;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 分页查询辅助函数
CREATE OR REPLACE FUNCTION paginate(query TEXT, limit_val INT DEFAULT 20, offset_val INT DEFAULT 0)
RETURNS TABLE(total_count BIGINT, data JSONB) AS $$
BEGIN
    RETURN QUERY EXECUTE format('SELECT COUNT(*)::BIGINT, to_jsonb(array_agg(t)) FROM (%s) t', query)
        USING limit_val, offset_val;
END;
$$ LANGUAGE plpgsql;
