-- 顺时数据库初始化脚本
-- 创建数据库
CREATE DATABASE IF NOT EXISTS shunshi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE shunshi;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) DEFAULT '用户',
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    life_stage VARCHAR(20) DEFAULT 'exploration',
    birthday DATE,
    gender VARCHAR(10) DEFAULT 'unknown',
    is_premium BOOLEAN DEFAULT FALSE,
    subscription_plan VARCHAR(20) DEFAULT 'free',
    subscription_expires_at TIMESTAMP NULL,
    memory_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_life_stage (life_stage),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 会话表
CREATE TABLE IF NOT EXISTS conversations (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(255),
    messages TEXT,
    context JSON,
    token_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 内容表
CREATE TABLE IF NOT EXISTS contents (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL,
    category VARCHAR(50),
    media_url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    tags JSON,
    view_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Follow-up表
CREATE TABLE IF NOT EXISTS follow_ups (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    conversation_id VARCHAR(36),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(20) DEFAULT 'wellness',
    status VARCHAR(20) DEFAULT 'pending',
    priority VARCHAR(10) DEFAULT 'normal',
    scheduled_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_scheduled_at (scheduled_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订阅表
CREATE TABLE IF NOT EXISTS subscriptions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    plan VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 家庭关系表
CREATE TABLE IF NOT EXISTS family_relations (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    member_name VARCHAR(100) NOT NULL,
    relation VARCHAR(20) NOT NULL,
    age INT,
    status VARCHAR(20) DEFAULT 'normal',
    last_active_at TIMESTAMP NULL,
    health_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_relation (relation),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 家庭邀请码表
CREATE TABLE IF NOT EXISTS family_invites (
    id VARCHAR(36) PRIMARY KEY,
    family_id VARCHAR(36) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,
    relation VARCHAR(20) NOT NULL,
    created_by VARCHAR(36) NOT NULL,
    used_by VARCHAR(36),
    used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_family_id (family_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户节律记录表
CREATE TABLE IF NOT EXISTS care_status (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    date DATE NOT NULL,
    mood VARCHAR(20),
    sleep_hours DECIMAL(3,1),
    exercise_minutes INT,
    stress_level VARCHAR(10),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_date (date),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 通知记录表
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    type VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    data JSON,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_sent_at (sent_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 初始化一些测试数据
INSERT INTO users (id, name, email, password_hash, life_stage) VALUES
('user-001', '测试用户', 'test@shunshi.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqKx8pKvW', 'exploration');

INSERT INTO contents (id, title, description, type, category, tags) VALUES
('content-001', '春季养肝茶', '枸杞菊花茶，清肝明目', 'recipe', '茶饮', '["春季", "养肝", "茶饮"]'),
('content-002', '足三里穴位', '调理脾胃，增强免疫', 'acupoint', '穴位', '["脾胃", "免疫"]'),
('content-003', '八段锦', '传统养生功法', 'exercise', '运动', '["传统", "功法", "运动"]'),
('content-004', '春季睡眠指南', '顺应春困，调整作息', 'tips', '睡眠', '["春季", "睡眠"]'),
('content-005', '情绪调节方法', '保持心情愉悦', 'tips', '情绪', '["情绪", "心理"]');

-- 插入节气数据
INSERT INTO contents (id, title, description, type, category, tags) VALUES
('st-001', '立春', '万物复苏，宜养肝护肝', 'solar_term', '节气', '["立春", "春季"]'),
('st-002', '雨水', '春雨润物，宜祛湿健脾', 'solar_term', '节气', '["雨水", "春季"]'),
('st-003', '惊蛰', '春雷惊醒，宜养心安神', 'solar_term', '节气', '["惊蛰", "春季"]'),
('st-004', '春分', '阴阳平衡，宜调理气血', 'solar_term', '节气', '["春分", "春季"]'),
('st-005', '清明', '气清景明，宜养肺润燥', 'solar_term', '节气', '["清明", "春季"]'),
('st-006', '谷雨', '雨生百谷，宜健脾祛湿', 'solar_term', '节气', '["谷雨", "春季"]');
