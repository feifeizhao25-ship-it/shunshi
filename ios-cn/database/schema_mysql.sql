-- 顺时数据库完整设计
-- 版本: v1.0.0
-- 日期: 2026-03-09

-- ==================== 用户相关 ====================

-- 用户表
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    avatar VARCHAR(500),
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 订阅相关
    subscription_type VARCHAR(50) DEFAULT 'free', -- free, premium, family
    subscription_expires_at DATETIME,
    daily_ai_limit INTEGER DEFAULT 5,
    ai_usage_today INTEGER DEFAULT 0,
    
    -- 体质相关
    constitution VARCHAR(50), -- 平和, 气虚, 阳虚, 阴虚, 痰湿, 湿热, 血瘀, 气郁, 特禀
    constitution_identified_at DATETIME,
    
    -- 设置
    notifications_enabled TINYINT(1) DEFAULT 1,
    ai_tone VARCHAR(50) DEFAULT 'gentle', -- gentle, professional, casual
    reminder_time VARCHAR(10) DEFAULT '10:00',
    language VARCHAR(10) DEFAULT 'zh-CN'
);

-- 用户设备表
CREATE TABLE user_devices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    device_id VARCHAR(255) NOT NULL,
    device_type VARCHAR(50), -- ios, android
    fcm_token VARCHAR(500),
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 对话相关 ====================

-- 对话表
CREATE TABLE conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    title VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at DATETIME,
    message_count INTEGER DEFAULT 0,
    is_archived TINYINT(1) DEFAULT 0
);

-- 消息表
CREATE TABLE messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT REFERENCES conversations(id) ,
    role VARCHAR(20) NOT NULL, -- user, assistant
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- AI 响应额外字段
    tone VARCHAR(50), -- gentle, professional, warm
    care_status VARCHAR(50), -- none, suggested, care_given
    safety_flag VARCHAR(50), -- safe, warning, blocked
    intent VARCHAR(100), -- wellness_advice, emotional_support, etc.
    model_used VARCHAR(50),
    tokens_used INTEGER DEFAULT 0,
    latency_ms INTEGER DEFAULT 0,
    metadata JSON 
);

-- ==================== 养生内容 ====================

-- 养生内容表
CREATE TABLE wellness_contents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- solar_term, food, tea, exercise, sleep, emotion
    content JSON NOT NULL,
    
    -- 适配
    applicable_constitutions JSON, -- ["气虚", "阳虚"]
    applicable_seasons JSON, -- ["spring", "summer"]
    applicable_stages JSON, -- ["youth", "adult"]
    
    -- 状态
    is_published TINYINT(1) DEFAULT 0,
    published_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 24节气内容
CREATE TABLE solar_terms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL, -- 立春, 雨水, etc.
    solar_term_date DATE NOT NULL,
    description TEXT,
    climate_features TEXT,
    health_focus TEXT,
    food_suggestions JSON,
    living_suggestions JSON,
    exercise_suggestions JSON,
    emotion_suggestions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 体质测试结果
CREATE TABLE constitution_tests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    answers JSON NOT NULL,
    result VARCHAR(50),
    confidence FLOAT,
    taken_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 习惯与日记 ====================

-- 习惯表
CREATE TABLE habits (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    name VARCHAR(255) NOT NULL,
    habit_type VARCHAR(50), -- exercise, sleep, diet, mood, custom
    frequency VARCHAR(50), -- daily, weekly
    reminder_time VARCHAR(10),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 习惯打卡记录
CREATE TABLE habit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    habit_id BIGINT REFERENCES habits(id) ,
    user_id BIGINT REFERENCES users(id) ,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    note TEXT,
    metadata JSON 
);

-- 养生日记
CREATE TABLE wellness_journals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    date DATE NOT NULL,
    mood VARCHAR(50),
    sleep_hours FLOAT,
    sleep_quality VARCHAR(20),
    exercise_minutes INTEGER,
    diet_notes TEXT,
    journal_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 家庭系统 ====================

-- 家庭组
CREATE TABLE family_groups (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    owner_id BIGINT REFERENCES users(id),
    invite_code VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 家庭成员
CREATE TABLE family_members (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT REFERENCES family_groups(id) ,
    user_id BIGINT REFERENCES users(id),
    role VARCHAR(50), -- owner, parent, child, elder
    name VARCHAR(255) NOT NULL,
    stage VARCHAR(50), -- youth, adult, middle_age, elder
    constitution VARCHAR(50),
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(family_id, user_id)
);

-- 家庭关怀记录
CREATE TABLE family_care_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    family_id BIGINT REFERENCES family_groups(id) ,
    from_user_id BIGINT REFERENCES users(id),
    to_member_id BIGINT REFERENCES family_members(id),
    care_type VARCHAR(50), -- reminder, greeting, alert
    message TEXT,
    sent_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 通知系统 ====================

-- 通知表
CREATE TABLE notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    notification_type VARCHAR(50), -- reminder, system, care, promotion
    data JSON ,
    is_read TINYINT(1) DEFAULT 0,
    sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- ==================== 订阅系统 ====================

-- 订阅记录
CREATE TABLE subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ,
    plan_type VARCHAR(50) NOT NULL, -- free, monthly, yearly
    payment_method VARCHAR(50), -- apple, google, wechat, alipay
    transaction_id VARCHAR(255),
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    is_active TINYINT(1) DEFAULT 1,
    auto_renew TINYINT(1) DEFAULT 0
);

-- ==================== 审计日志 ====================

-- AI 请求日志
CREATE TABLE ai_request_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
