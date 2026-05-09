-- 顺时数据库设计

-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    avatar VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- 订阅相关
    subscription_type VARCHAR(50) DEFAULT 'free',
    subscription_expires_at TIMESTAMP,
    
    -- 体质相关
    constitution VARCHAR(50),
    constitution_identified_at TIMESTAMP,
    
    -- 设置
    notifications_enabled BOOLEAN DEFAULT TRUE,
    ai_tone VARCHAR(50) DEFAULT 'gentle',
    reminder_time VARCHAR(10) DEFAULT '10:00'
);

-- 对话表
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    title VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    last_message_at TIMESTAMP,
    message_count INTEGER DEFAULT 0
);

-- 消息表
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id),
    role VARCHAR(20) NOT NULL, -- 'user' | 'assistant'
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- AI 响应额外字段
    tone VARCHAR(50),
    care_status VARCHAR(50),
    safety_flag VARCHAR(50),
    intent VARCHAR(100),
    metadata JSONB DEFAULT '{}'
);

-- 养生内容表
CREATE TABLE wellness_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 食疗/茶饮/穴位/运动/睡眠/情绪
    type VARCHAR(20) NOT NULL, -- article/video/image
    content TEXT NOT NULL,
    summary TEXT,
    
    -- 体质适配
    suitable_constitutions TEXT[],
    avoid_constitutions TEXT[],
    
    -- 节气适配
    suitable_seasons TEXT[],
    
    -- 媒体
    image_url VARCHAR(500),
    video_url VARCHAR(500),
    
    -- 标签
    tags TEXT[],
    
    -- 状态
    is_published BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- 跟进任务表
CREATE TABLE follow_ups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    conversation_id UUID REFERENCES conversations(id),
    
    -- 跟进设置
    trigger_in_days INTEGER NOT NULL,
    intent VARCHAR(100) NOT NULL,
    custom_message TEXT,
    
    -- 触发状态
    is_triggered BOOLEAN DEFAULT FALSE,
    triggered_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- 创建信息
    created_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(20) -- 'ai' | 'user'
);

-- 订阅表
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    plan VARCHAR(50) NOT NULL, -- 'free' | 'monthly' | 'yearly'
    status VARCHAR(50) NOT NULL, -- 'active' | 'cancelled' | 'expired'
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    
    -- 支付信息
    transaction_id VARCHAR(100),
    payment_method VARCHAR(50),
    store VARCHAR(20), -- 'apple' | 'google'
    
    -- 自动续费
    auto_renew BOOLEAN DEFAULT TRUE,
    cancelled_at TIMESTAMP
);

-- 关怀状态表
CREATE TABLE care_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL, -- stable/concerned/attention
    notes TEXT,
    recorded_at TIMESTAMP DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_follow_ups_trigger_at ON follow_ups(trigger_at) WHERE is_triggered = FALSE;
CREATE INDEX idx_wellness_contents_category ON wellness_contents(category);
CREATE INDEX idx_wellness_contents_constitutions ON wellness_contents USING GIN(suitable_constitutions);
