"""
顺时 SQLite 数据库层
使用同步 sqlite3，通过 FastAPI 线程池运行
"""
import sqlite3
import json
import os
import threading
from pathlib import Path
from typing import Optional

# 数据库文件路径
DB_DIR = Path(__file__).resolve().parent.parent.parent / "data"
DB_PATH = DB_DIR / "shunshi.db"

# 线程局部存储（每个线程一个连接）
_local = threading.local()

# 全局锁，用于初始化（仅启动时）
_init_lock = threading.Lock()


def _get_connection() -> sqlite3.Connection:
    """获取当前线程的数据库连接"""
    if not hasattr(_local, "connection") or _local.connection is None:
        DB_DIR.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        _local.connection = conn
    return _local.connection


def get_db() -> sqlite3.Connection:
    """获取数据库连接（FastAPI 依赖注入用）"""
    return _get_connection()


def close_db():
    """关闭当前线程的连接"""
    if hasattr(_local, "connection") and _local.connection is not None:
        _local.connection.close()
        _local.connection = None


# ==================== 建表 SQL ====================

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT DEFAULT '用户',
    email TEXT UNIQUE,
    password_hash TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    life_stage TEXT DEFAULT 'exploration',
    birthday TEXT,
    gender TEXT DEFAULT 'unknown',
    is_premium INTEGER DEFAULT 0,
    subscription_plan TEXT DEFAULT 'free',
    subscription_expires_at TEXT,
    google_id TEXT UNIQUE,
    apple_id TEXT UNIQUE,
    stripe_customer_id TEXT,
    memory_enabled INTEGER DEFAULT 1,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    last_active_at TEXT
);

CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS contents (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    category TEXT,
    tags TEXT DEFAULT '[]',
    difficulty TEXT,
    time TEXT,
    duration TEXT,
    ingredients TEXT DEFAULT '[]',
    steps TEXT DEFAULT '[]',
    location TEXT,
    method TEXT,
    effect TEXT,
    benefits TEXT DEFAULT '[]',
    best_time TEXT,
    season_tag TEXT,
    locale TEXT DEFAULT 'zh-CN',
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    is_premium INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS follow_ups (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    conversation_id TEXT,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT DEFAULT 'wellness',
    status TEXT DEFAULT 'pending',
    priority TEXT DEFAULT 'normal',
    scheduled_at TEXT,
    completed_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    plan TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    started_at TEXT DEFAULT (datetime('now')),
    expires_at TEXT,
    auto_renew INTEGER DEFAULT 1,
    platform TEXT,
    subscribed_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS family_relations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    family_id TEXT NOT NULL,
    family_name TEXT DEFAULT '我的家庭',
    member_name TEXT NOT NULL,
    relation TEXT NOT NULL,
    age INTEGER,
    status TEXT DEFAULT 'normal',
    last_active_at TEXT,
    user_id_member TEXT,
    health_data TEXT DEFAULT '{}',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS family_invites (
    id TEXT PRIMARY KEY,
    family_id TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    relation TEXT NOT NULL,
    created_by TEXT NOT NULL,
    used_by TEXT,
    used INTEGER DEFAULT 0,
    used_at TEXT,
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS care_status (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    mood TEXT,
    sleep_hours REAL,
    exercise_minutes INTEGER,
    stress_level TEXT,
    notes TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS emotion_records (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    emotion TEXT NOT NULL,
    intensity INTEGER DEFAULT 5,
    trigger TEXT,
    notes TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sleep_records (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    sleep_time TEXT DEFAULT '23:00',
    wake_time TEXT DEFAULT '07:00',
    hours REAL DEFAULT 8.0,
    quality TEXT DEFAULT 'normal',
    notes TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data TEXT DEFAULT '{}',
    is_read INTEGER DEFAULT 0,
    sent_at TEXT DEFAULT (datetime('now')),
    read_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data TEXT DEFAULT '{}',
    scheduled_at TEXT,
    status TEXT DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS user_settings (
    user_id TEXT PRIMARY KEY,
    memory_enabled INTEGER DEFAULT 1,
    quiet_hours_enabled INTEGER DEFAULT 0,
    quiet_hours_start TEXT DEFAULT '22:00',
    quiet_hours_end TEXT DEFAULT '08:00',
    notifications_enabled INTEGER DEFAULT 1,
    solar_term_reminders INTEGER DEFAULT 1,
    followup_reminders INTEGER DEFAULT 1,
    marketing_notifications INTEGER DEFAULT 0,
    language TEXT DEFAULT 'zh-CN',
    theme TEXT DEFAULT 'light',
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS user_memory (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    confidence REAL DEFAULT 1.0,
    source TEXT DEFAULT 'conversation',
    metadata TEXT DEFAULT '{}',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auth_tokens (
    token TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_history (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    plan TEXT NOT NULL,
    price INTEGER DEFAULT 0,
    platform TEXT DEFAULT 'ios',
    receipt TEXT,
    subscribed_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS notification_settings (
    user_id TEXT PRIMARY KEY,
    enabled INTEGER DEFAULT 1,
    solar_term INTEGER DEFAULT 1,
    followup INTEGER DEFAULT 1,
    marketing INTEGER DEFAULT 0,
    quiet_hours_enabled INTEGER DEFAULT 0,
    quiet_hours_start TEXT DEFAULT '22:00',
    quiet_hours_end TEXT DEFAULT '08:00',
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_conversations_user ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conv ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_contents_type ON contents(type);
CREATE INDEX IF NOT EXISTS idx_contents_category ON contents(category);
CREATE INDEX IF NOT EXISTS idx_contents_locale ON contents(locale);
CREATE INDEX IF NOT EXISTS idx_care_user ON care_status(user_id);
CREATE INDEX IF NOT EXISTS idx_care_date ON care_status(date);
CREATE INDEX IF NOT EXISTS idx_emotion_user ON emotion_records(user_id);
CREATE INDEX IF NOT EXISTS idx_sleep_user ON sleep_records(user_id);
CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_family_user ON family_relations(user_id);
CREATE INDEX IF NOT EXISTS idx_subs_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_user ON user_memory(user_id);

-- AI LLM 审计日志
CREATE TABLE IF NOT EXISTS ai_audit_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    request_id TEXT,
    provider TEXT NOT NULL,
    model TEXT NOT NULL,
    skill_chain TEXT,
    prompt_hash TEXT NOT NULL,
    prompt_version TEXT,
    tokens_in INTEGER DEFAULT 0,
    tokens_out INTEGER DEFAULT 0,
    latency_ms INTEGER DEFAULT 0,
    cost_usd REAL DEFAULT 0.0,
    safety_flag TEXT DEFAULT 'none',
    route_decision TEXT,
    response_status TEXT,
    error_message TEXT,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audit_user_date ON ai_audit_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_model ON ai_audit_logs(model, created_at);

CREATE TABLE IF NOT EXISTS skill_versions (
    id TEXT PRIMARY KEY,
    skill_name TEXT NOT NULL,
    version INTEGER NOT NULL,
    config TEXT NOT NULL,
    changelog TEXT DEFAULT '',
    is_active INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    UNIQUE(skill_name, version)
);
CREATE INDEX IF NOT EXISTS idx_skill_versions_name ON skill_versions(skill_name, version);
"""


# ==================== 种子数据 ====================

def _s(iid, title, desc, tp, cat, tags, season=None,
        difficulty=None, duration=None, ingredients=None, steps=None,
        location=None, method=None, effect=None, benefits=None, best_time=None):
    """辅助函数：生成种子数据元组，统一18个字段顺序（含locale）"""
    return (
        iid, title, desc, tp, cat,
        json.dumps(tags, ensure_ascii=False),
        difficulty, None,  # time
        duration,
        json.dumps(ingredients, ensure_ascii=False) if ingredients else None,
        json.dumps(steps, ensure_ascii=False) if steps else None,
        location, method, effect,
        json.dumps(benefits, ensure_ascii=False) if benefits else None,
        best_time, season, "zh-CN"
    )

def _se(iid, title, desc, tp, cat, tags, season=None,
        difficulty=None, duration=None, ingredients=None, steps=None,
        location=None, method=None, effect=None, benefits=None, best_time=None):
    """辅助函数：生成英文种子数据元组，locale='en-US'"""
    return (
        iid, title, desc, tp, cat,
        json.dumps(tags, ensure_ascii=False),
        difficulty, None,  # time
        duration,
        json.dumps(ingredients, ensure_ascii=False) if ingredients else None,
        json.dumps(steps, ensure_ascii=False) if steps else None,
        location, method, effect,
        json.dumps(benefits, ensure_ascii=False) if benefits else None,
        best_time, season, "en-US"
    )

SEED_CONTENTS = [
    # ========== 原有数据 (23条) ==========
    # 食疗 (5)
    _s("food-001", "枸杞菊花茶", "清肝明目，养颜美容", "recipe", "茶饮",
       ["养肝", "明目", "茶饮"], ingredients=["枸杞", "菊花", "蜂蜜"],
       steps=["枸杞菊花用热水冲泡", "加入蜂蜜调味"], difficulty="简单", duration="10分钟"),
    _s("food-002", "红枣桂圆粥", "补气养血，美容养颜", "recipe", "粥品",
       ["补血", "养颜", "早餐"], ingredients=["红枣", "桂圆", "大米", "红糖"],
       steps=["大米红枣桂圆煮粥", "加入红糖"], difficulty="简单", duration="30分钟"),
    _s("food-003", "山药薏米粥", "健脾祛湿", "recipe", "粥品",
       ["健脾", "祛湿", "养生"], ingredients=["山药", "薏米", "大米"],
       steps=["薏米提前浸泡", "与山药大米煮粥"], difficulty="简单", duration="40分钟"),
    _s("food-004", "百合莲子银耳羹", "润肺止咳，养心安神", "recipe", "甜品",
       ["润肺", "养心", "美容"], ingredients=["百合", "莲子", "银耳", "冰糖"],
       steps=["银耳泡发", "加入百合莲子炖煮"], difficulty="中等", duration="60分钟"),
    _s("food-005", "生姜红糖水", "驱寒暖胃", "recipe", "茶饮",
       ["驱寒", "暖胃", "感冒"], ingredients=["生姜", "红糖", "红枣"],
       steps=["生姜红枣煮水", "加入红糖"], difficulty="简单", duration="15分钟"),
    # 穴位 (5)
    _s("acup-001", "足三里", "调理脾胃，增强免疫", "acupoint", "穴位",
       ["脾胃", "免疫", "保健"], location="小腿外侧，犊鼻下3寸",
       method="艾灸或按摩", effect="调理脾胃，促进消化"),
    _s("acup-002", "关元穴", "补肾固本", "acupoint", "穴位",
       ["补肾", "固本", "保健"], location="脐下3寸",
       method="艾灸或按摩", effect="补肾壮阳，增强体质"),
    _s("acup-003", "合谷穴", "止痛镇静", "acupoint", "穴位",
       ["止痛", "镇静", "感冒"], location="手背虎口处",
       method="按摩", effect="缓解疼痛，预防感冒"),
    _s("acup-004", "内关穴", "安神定悸", "acupoint", "穴位",
       ["安神", "心悸", "晕车"], location="前臂掌侧，腕横纹上2寸",
       method="按摩", effect="缓解心悸，安神"),
    _s("acup-005", "涌泉穴", "补肾安神", "acupoint", "穴位",
       ["补肾", "安神", "失眠"], location="足底前1/3处",
       method="泡脚或按摩", effect="补肾安神，改善睡眠"),
    # 运动 (5)
    _s("exercise-001", "八段锦", "传统养生功法", "exercise", "传统功法",
       ["传统", "养生", "功法"], benefits=["调理气血", "增强体质"],
       difficulty="简单", duration="15分钟"),
    _s("exercise-002", "太极拳", "舒缓身心", "exercise", "传统功法",
       ["传统", "舒缓", "平衡"], benefits=["平衡身心", "增强协调"],
       difficulty="中等", duration="30分钟"),
    _s("exercise-003", "五禽戏", "模仿五禽的养生运动", "exercise", "传统功法",
       ["传统", "仿生", "养生"], benefits=["增强脏腑", "提高免疫"],
       difficulty="中等", duration="20分钟"),
    _s("exercise-004", "散步", "最简单的养生运动", "exercise", "有氧",
       ["简单", "有氧", "日常"], benefits=["促进消化", "放松心情"],
       difficulty="简单", duration="30分钟"),
    _s("exercise-005", "站桩", "静功养生", "exercise", "静功",
       ["静功", "养生", "桩功"], benefits=["调理气血", "增强内力"],
       difficulty="中等", duration="15分钟"),
    # 睡眠 (4)
    _s("sleep-001", "睡前泡脚", "促进血液循环", "tips", "睡眠",
       ["睡眠", "保健", "简单"], method="40度温水泡脚15-20分钟", best_time="睡前1小时"),
    _s("sleep-002", "助眠香薰", "芳香疗法助眠", "tips", "睡眠",
       ["睡眠", "香薰", "放松"], method="使用薰衣草精油扩香", best_time="睡前30分钟"),
    _s("sleep-003", "睡前冥想", "放空大脑", "tips", "睡眠",
       ["睡眠", "冥想", "放松"], method="深呼吸，放空思绪", best_time="睡前15分钟"),
    _s("sleep-004", "睡眠姿势", "右侧卧最佳", "tips", "睡眠",
       ["睡眠", "姿势", "健康"], method="右侧卧，双腿微屈", best_time="整晚"),
    # 情绪 (4)
    _s("mood-001", "深呼吸练习", "缓解焦虑", "tips", "情绪",
       ["情绪", "焦虑", "放松"], method="4-7-8呼吸法", effect="缓解焦虑"),
    _s("mood-002", "情绪日记", "记录情绪", "tips", "情绪",
       ["情绪", "自我", "觉察"], method="每天记录情绪变化", effect="提高情绪觉察"),
    _s("mood-003", "正念冥想", "活在当下", "tips", "情绪",
       ["正念", "冥想", "当下"], method="专注当下感受", effect="减少焦虑"),
    _s("mood-004", "音乐疗法", "音乐疗愈", "tips", "情绪",
       ["音乐", "疗愈", "放松"], method="聆听舒缓音乐", effect="调节情绪"),

    # ========== A. 食疗推荐 (80条) ==========
    # ----- 春季食疗 (20) -----
    _s("seed_food_therapy_001", "菠菜养肝汤", "菠菜性凉味甘，入肝经，能养血润燥、平肝清热。《本草纲目》载其通血脉、开胸膈，春季食用可助肝气条达，明目止血。", "food_therapy", "春季食疗", ["春季", "养肝", "明目", "菠菜"], season="spring",
       ingredients=["菠菜300g", "猪肝100g", "生姜3片", "枸杞10g", "盐适量"],
       steps=["菠菜焯水切段", "猪肝切片焯水", "锅中加水煮开，放入姜片", "下猪肝煮5分钟", "加菠菜枸杞煮熟，调味"], difficulty="简单", duration="20分钟"),
    _s("seed_food_therapy_002", "韭菜炒鸡蛋", "韭菜温中补肾，被称为起阳草。《本草拾遗》载其温中下气，补虚益阳。春季食用可助阳气生发，温暖脾胃，增强体力。", "food_therapy", "春季食疗", ["春季", "温阳", "补肾", "韭菜"], season="spring",
       ingredients=["韭菜250g", "鸡蛋3个", "盐适量", "食用油适量"],
       steps=["韭菜洗净切段", "鸡蛋打散加少许盐", "热锅下油炒蛋盛出", "下韭菜快炒", "倒入鸡蛋翻炒均匀"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_003", "油焖春笋", "春笋味甘性寒，清热化痰、益气和胃。《本草纲目拾遗》称其利九窍、通血脉。春季食笋可清热除烦、促进消化，为时令佳品。", "food_therapy", "春季食疗", ["春季", "清热", "化痰", "春笋"], season="spring",
       ingredients=["春笋500g", "生抽2勺", "老抽1勺", "白糖1勺", "食用油适量"],
       steps=["春笋去壳切块焯水", "热锅下油炒笋块", "加生抽老抽白糖翻炒", "加少量水焖煮10分钟", "大火收汁即可"], difficulty="简单", duration="25分钟"),
    _s("seed_food_therapy_004", "荠菜豆腐羹", "荠菜性平味甘，和脾利水、止血明目。《名医别录》载其主利肝气、和中。春季荠菜鲜嫩，配豆腐清热利湿，为养生上选。", "food_therapy", "春季食疗", ["春季", "利水", "明目", "荠菜"], season="spring",
       ingredients=["荠菜200g", "嫩豆腐1块", "鸡蛋1个", "淀粉适量", "盐适量"],
       steps=["荠菜焯水切碎", "豆腐切小丁", "锅中加水煮开下豆腐", "加荠菜煮2分钟", "淋入蛋液勾芡调味"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_005", "香椿拌豆腐", "香椿性凉味苦，清热解毒、健胃理气。《陆川本草》载其清热解毒。春季香椿嫩芽香气浓郁，拌豆腐清爽可口，可清热利湿。", "food_therapy", "春季食疗", ["春季", "清热", "解毒", "香椿"], season="spring",
       ingredients=["香椿芽100g", "嫩豆腐1块", "香油适量", "盐适量", "生抽适量"],
       steps=["香椿焯水切末", "豆腐切小丁摆盘", "香椿末铺在豆腐上", "淋香油生抽调味"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_006", "清炒豆芽", "豆芽性凉味甘，清热解毒、健脾益气。《本草纲目》载其去肝火、解诸毒。春季食用豆芽可助肝气疏泄，清解内热，营养丰富。", "food_therapy", "春季食疗", ["春季", "清热", "解毒", "豆芽"], season="spring",
       ingredients=["绿豆芽300g", "葱花适量", "醋少许", "盐适量", "食用油适量"],
       steps=["豆芽洗净沥干", "热锅快炒豆芽", "加葱花翻炒", "淋少许醋出锅"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_007", "草莓润肺饮", "草莓性凉味甘酸，润肺生津、健脾和胃。《本草纲目》载其补脾气、固元气。春季食用可生津止渴，润燥养颜，富含维生素C。", "food_therapy", "春季食疗", ["春季", "润肺", "生津", "草莓"], season="spring",
       ingredients=["草莓200g", "蜂蜜适量", "酸奶200ml"],
       steps=["草莓洗净去蒂", "与酸奶蜂蜜一起打汁", "冰镇后饮用更佳"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_008", "樱桃补血方", "樱桃性温味甘，补中益气、祛风除湿。《本草纲目》称其调中益脾、美容颜。春季食用樱桃可补血养颜，缓解疲劳，改善面色萎黄。", "food_therapy", "春季食疗", ["春季", "补血", "养颜", "樱桃"], season="spring",
       ingredients=["樱桃200g", "冰糖适量", "桂花少许"],
       steps=["樱桃洗净去核", "加水加冰糖煮开", "小火煮10分钟", "撒桂花即可"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_009", "蜂蜜柚子茶", "蜂蜜性平味甘，补中润燥、止痛解毒。《本草纲目》称其入药之功有五：清热、补中、解毒、润燥、止痛。春季润燥养颜佳品。", "food_therapy", "春季食疗", ["春季", "润燥", "养颜", "蜂蜜"], season="spring",
       ingredients=["蜂蜜3勺", "柚子半个", "温水适量"],
       steps=["柚子取肉撕碎", "加入蜂蜜拌匀", "用温水冲泡饮用"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_010", "山药养胃粥", "山药性平味甘，补脾养胃、生津益肺。《本草纲目》载其益肾气、健脾胃。春季以山药煮粥，可健脾益气，助消化，老少皆宜。", "food_therapy", "春季食疗", ["春季", "健脾", "养胃", "山药"], season="spring",
       ingredients=["山药200g", "大米100g", "红枣5颗", "冰糖适量"],
       steps=["山药去皮切块", "大米红枣洗净", "一同入锅煮粥", "煮至粘稠加冰糖"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_011", "枸杞明目粥", "枸杞子性平味甘，滋补肝肾、益精明目。《本草纲目》载其补肾生精、养肝明目。春季养肝正当时，枸杞粥可明目补血，改善眼干眼涩。", "food_therapy", "春季食疗", ["春季", "养肝", "明目", "枸杞"], season="spring",
       ingredients=["枸杞20g", "大米100g", "红枣5颗", "冰糖适量"],
       steps=["大米红枣煮粥", "粥将熟时加入枸杞", "再煮5分钟加冰糖"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_012", "红枣花生汤", "红枣性温味甘，补中益气、养血安神。《本草纲目》载其补气健脾、养血安神。配花生可增强补血功效，春季食用可改善气血不足。", "food_therapy", "春季食疗", ["春季", "补血", "安神", "红枣"], season="spring",
       ingredients=["红枣15颗", "花生50g", "红糖适量", "生姜2片"],
       steps=["花生提前浸泡", "红枣花生同煮", "加红糖姜片调味"], difficulty="简单", duration="30分钟"),
    _s("seed_food_therapy_013", "莲子百合羹", "莲子性平味甘涩，补脾止泻、益肾固精。《本草纲目》载其交心肾、厚肠胃。春季配百合可养心安神，改善失眠多梦、心烦不宁。", "food_therapy", "春季食疗", ["春季", "养心", "安神", "莲子"], season="spring",
       ingredients=["莲子30g", "百合20g", "银耳半朵", "冰糖适量"],
       steps=["莲子百合泡发", "银耳撕碎", "一同炖煮至软烂", "加冰糖调味"], difficulty="中等", duration="45分钟"),
    _s("seed_food_therapy_014", "百合银耳汤", "百合性微寒味甘，润肺止咳、清心安神。《本草纲目》载其利大小便、补中益气。春季配银耳滋阴润肺，适合肺燥干咳、皮肤干燥者。", "food_therapy", "春季食疗", ["春季", "润肺", "止咳", "百合"], season="spring",
       ingredients=["干百合20g", "银耳1朵", "枸杞10g", "冰糖适量"],
       steps=["银耳泡发撕碎", "加百合枸杞炖煮", "小火慢炖1小时", "加冰糖调味"], difficulty="中等", duration="60分钟"),
    _s("seed_food_therapy_015", "核桃补脑粥", "核桃性温味甘，补肾固精、温肺定喘。《本草纲目》载其补气养血、润燥化痰。春季食用核桃可健脑益智，改善记忆力衰退。", "food_therapy", "春季食疗", ["春季", "补脑", "固肾", "核桃"], season="spring",
       ingredients=["核桃仁50g", "大米100g", "红枣5颗", "冰糖适量"],
       steps=["核桃仁捣碎", "大米红枣煮粥", "加入核桃仁同煮", "加冰糖调味"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_016", "花生养血糊", "花生性平味甘，润肺和胃、止咳化痰。《本草纲目拾遗》载其悦脾和胃、润肺化痰。春季食用可补血止血，润肠通便，适合体虚者。", "food_therapy", "春季食疗", ["春季", "补血", "润肺", "花生"], season="spring",
       ingredients=["花生50g", "糯米50g", "红枣8颗", "红糖适量"],
       steps=["花生糯米浸泡", "红枣去核", "一同煮成糊状", "加红糖调味"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_017", "燕麦养心粥", "燕麦性平味甘，补益脾胃、滑肠催产。《本草纲目》载其益气力、续精神。春季以燕麦煮粥，可健脾养心，降低血脂，通便排毒。", "food_therapy", "春季食疗", ["春季", "健脾", "降脂", "燕麦"], season="spring",
       ingredients=["燕麦片100g", "牛奶200ml", "蜂蜜适量", "蓝莓少许"],
       steps=["燕麦加牛奶煮开", "小火煮5分钟", "加蜂蜜蓝莓即可"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_018", "桂圆安神汤", "桂圆性温味甘，补心脾、益气血。《本草纲目》载其开胃益脾、补虚长智。春季心神不宁、失眠健忘者可常食，能养血安神。", "food_therapy", "春季食疗", ["春季", "安神", "补血", "桂圆"], season="spring",
       ingredients=["桂圆干20g", "红枣10颗", "鸡蛋1个", "红糖适量"],
       steps=["桂圆红枣煮水", "水开15分钟后打入鸡蛋", "加红糖调味"], difficulty="简单", duration="20分钟"),
    _s("seed_food_therapy_019", "菊花养肝茶", "菊花性微寒味甘苦，疏风散热、平肝明目。《本草纲目》载其散风热、平肝阳。春季肝火旺盛，菊花茶可清热明目，缓解头痛眩晕。", "food_therapy", "春季食疗", ["春季", "养肝", "清热", "菊花"], season="spring",
       ingredients=["菊花10g", "枸杞10g", "冰糖适量"],
       steps=["菊花枸杞洗净", "沸水冲泡5分钟", "加冰糖调味饮用"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_020", "茵陈蒿粥", "茵陈性微寒味苦，清热利湿、退黄。《本草纲目》载其治通身发黄、小便不利。早春采嫩茵陈煮粥，可清利湿热，护肝利胆。", "food_therapy", "春季食疗", ["春季", "利湿", "护肝", "茵陈"], season="spring",
       ingredients=["鲜茵陈30g", "大米100g", "白糖适量"],
       steps=["茵陈洗净煮水取汁", "大米加入茵陈汁煮粥", "加白糖调味"], difficulty="简单", duration="30分钟"),

    # ----- 夏季食疗 (20) -----
    _s("seed_food_therapy_021", "西瓜清热饮", "西瓜性寒味甘，清热解暑、除烦止渴。《本草纲目》载其消烦止渴、解暑热。夏季食用西瓜可清热降火，利尿消肿，为天然白虎汤。", "food_therapy", "夏季食疗", ["夏季", "清热", "解暑", "西瓜"], season="summer",
       ingredients=["西瓜瓤500g", "冰糖少许", "薄荷叶少许"],
       steps=["西瓜瓤去籽切块", "加冰糖打汁", "放薄荷叶点缀饮用"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_022", "凉拌黄瓜", "黄瓜性凉味甘，清热利水、解毒消肿。《本草纲目》载其清热解渴、利小便。夏季凉拌黄瓜，可清热生津，开胃消食，为消暑良方。", "food_therapy", "夏季食疗", ["夏季", "清热", "利水", "黄瓜"], season="summer",
       ingredients=["黄瓜2根", "蒜末适量", "醋适量", "辣椒油少许", "盐适量"],
       steps=["黄瓜拍碎切段", "加蒜末醋辣椒油", "拌匀入味即可"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_023", "苦瓜降糖汤", "苦瓜性寒味苦，清暑涤热、明目解毒。《本草纲目》载其除邪热、解劳乏。夏季食苦瓜可清热消暑，降血糖、降血脂，苦味入心。", "food_therapy", "夏季食疗", ["夏季", "清热", "降糖", "苦瓜"], season="summer",
       ingredients=["苦瓜1根", "排骨300g", "黄豆30g", "生姜3片", "盐适量"],
       steps=["苦瓜去瓤切块", "排骨焯水", "黄豆提前泡发", "全部材料煲汤1.5小时"], difficulty="中等", duration="90分钟"),
    _s("seed_food_therapy_024", "绿豆解毒汤", "绿豆性凉味甘，清热解毒、消暑利尿。《本草纲目》称其济世之良谷。夏季煮绿豆汤，可清热解暑、止渴利尿，为消暑第一汤。", "food_therapy", "夏季食疗", ["夏季", "清热", "解毒", "绿豆"], season="summer",
       ingredients=["绿豆100g", "冰糖适量", "薄荷少许"],
       steps=["绿豆洗净浸泡", "大火煮开转小火", "煮至绿豆开花", "加冰糖薄荷调味"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_025", "薏米祛湿粥", "薏米性凉味甘淡，健脾渗湿、除痹止泻。《本草纲目》载其健脾益胃、补肺清热。夏秋之交湿气重，薏米粥可健脾祛湿，消水肿。", "food_therapy", "夏季食疗", ["夏季", "祛湿", "健脾", "薏米"], season="summer",
       ingredients=["薏米100g", "赤小豆50g", "冰糖适量"],
       steps=["薏米赤豆提前浸泡", "一同煮粥", "加冰糖调味"], difficulty="简单", duration="50分钟"),
    _s("seed_food_therapy_026", "冬瓜利水汤", "冬瓜性凉味甘淡，清热利水、解毒生津。《本草纲目》载其益气耐老、除心胸满。夏季冬瓜汤利水消肿，解暑除烦，为时令清补佳品。", "food_therapy", "夏季食疗", ["夏季", "利水", "消暑", "冬瓜"], season="summer",
       ingredients=["冬瓜500g", "排骨200g", "姜片3片", "盐适量"],
       steps=["冬瓜去皮切块", "排骨焯水", "一同煲汤1小时", "加盐调味"], difficulty="简单", duration="60分钟"),
    _s("seed_food_therapy_027", "番茄鸡蛋汤", "番茄性微寒味甘酸，生津止渴、健胃消食。《本草纲目》载其清热解毒、凉血平肝。夏季番茄汤酸甜开胃，补充番茄红素，抗氧化。", "food_therapy", "夏季食疗", ["夏季", "开胃", "抗氧化", "番茄"], season="summer",
       ingredients=["番茄2个", "鸡蛋2个", "葱花适量", "盐适量", "香油少许"],
       steps=["番茄切块炒出汁", "加水煮开", "淋入蛋液", "撒葱花淋香油"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_028", "丝瓜解毒汤", "丝瓜性凉味甘，清热化痰、凉血解毒。《本草纲目》载其通经活络、行血脉。夏季丝瓜汤可清热解暑，通络化痰，为消暑佳菜。", "food_therapy", "夏季食疗", ["夏季", "清热", "化痰", "丝瓜"], season="summer",
       ingredients=["丝瓜2根", "鸡蛋1个", "虾皮少许", "盐适量"],
       steps=["丝瓜去皮切片", "虾皮炒香", "加水煮开放丝瓜", "打蛋花调味"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_029", "薄荷清凉饮", "薄荷性凉味辛，疏散风热、清利头目。《本草纲目》载其利咽喉、口齿诸病。夏季薄荷茶可清凉解暑，疏风散热，提神醒脑。", "food_therapy", "夏季食疗", ["夏季", "清凉", "解暑", "薄荷"], season="summer",
       ingredients=["鲜薄荷叶10片", "柠檬3片", "蜂蜜适量", "冰块适量"],
       steps=["薄荷叶洗净", "与柠檬片蜂蜜拌匀", "加冰水冲泡"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_030", "荷叶减肥茶", "荷叶性平味苦涩，清暑利湿、升发清阳。《本草纲目》载其生发元气、裨助脾胃。夏季荷叶茶可清热消暑，降脂减肥，为瘦身佳品。", "food_therapy", "夏季食疗", ["夏季", "消暑", "降脂", "荷叶"], season="summer",
       ingredients=["干荷叶5g", "山楂10g", "决明子5g", "冰糖少许"],
       steps=["荷叶山楂决明子洗净", "沸水冲泡10分钟", "加冰糖调味"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_031", "金银花解毒茶", "金银花性寒味甘，清热解毒、疏散风热。《本草纲目》载其散热解毒、治诸肿毒。夏季饮用可清热消暑，预防感冒，消炎抗菌。", "food_therapy", "夏季食疗", ["夏季", "清热", "解毒", "金银花"], season="summer",
       ingredients=["金银花10g", "菊花5g", "甘草3g", "冰糖适量"],
       steps=["金银花菊花甘草洗净", "沸水冲泡5分钟", "加冰糖饮用"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_032", "酸梅生津饮", "乌梅性平味酸涩，生津止渴、涩肠止泻。《本草纲目》载其敛肺涩肠、生津止渴。夏季酸梅汤可生津解渴，开胃消食，为传统消暑名饮。", "food_therapy", "夏季食疗", ["夏季", "生津", "消暑", "酸梅"], season="summer",
       ingredients=["乌梅30g", "山楂20g", "甘草5g", "桂花少许", "冰糖适量"],
       steps=["乌梅山楂甘草煮水", "大火煮开转小火30分钟", "加冰糖桂花调味", "冰镇后饮用"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_033", "茄子清热菜", "茄子性凉味甘，清热活血、消肿止痛。《本草纲目》载其散血止痛、消肿宽肠。夏季食茄子可清热消肿，保护心血管，降低胆固醇。", "food_therapy", "夏季食疗", ["夏季", "清热", "活血", "茄子"], season="summer",
       ingredients=["茄子2根", "蒜末适量", "生抽2勺", "醋1勺", "香油少许"],
       steps=["茄子蒸熟撕条", "蒜末撒上面", "淋生抽醋香油", "拌匀食用"], difficulty="简单", duration="20分钟"),
    _s("seed_food_therapy_034", "莴笋利尿汤", "莴笋性凉味苦甘，利尿通乳、通利肠胃。《本草纲目》载其通乳汁、利小便。夏季食莴笋可清热利尿，通利消化，适合水肿体质。", "food_therapy", "夏季食疗", ["夏季", "利尿", "清热", "莴笋"], season="summer",
       ingredients=["莴笋1根", "猪肉片100g", "生姜3片", "盐适量"],
       steps=["莴笋去皮切片", "肉片滑炒", "加水煮开放莴笋", "调味出锅"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_035", "芦笋清热方", "芦笋性凉味甘，清热生津、利小便。《本草纲目》载其瘿结热气、利小便。夏季芦笋富含多种氨基酸，可清热解毒，增强免疫力。", "food_therapy", "夏季食疗", ["夏季", "清热", "增强免疫", "芦笋"], season="summer",
       ingredients=["芦笋300g", "虾仁100g", "蒜末适量", "盐适量"],
       steps=["芦笋焯水切段", "虾仁滑炒", "加芦笋蒜末快炒", "调味出锅"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_036", "桃子养阴饮", "桃子性温味甘酸，生津润肠、活血消积。《本草纲目》载其作脯食、益颜色。夏季食桃可生津解渴，润肠通便，补益气血。", "food_therapy", "夏季食疗", ["夏季", "生津", "润肠", "桃子"], season="summer",
       ingredients=["鲜桃3个", "蜂蜜适量", "柠檬汁少许"],
       steps=["桃子去皮切块", "加蜂蜜柠檬汁", "冷藏后食用"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_037", "荔枝补脾方", "荔枝性温味甘酸，补脾益肝、养血安神。《本草纲目》载其止渴、益人颜色。夏季荔枝甘甜多汁，可补脾益肝，养心安神。但不宜过量。", "food_therapy", "夏季食疗", ["夏季", "补脾", "养血", "荔枝"], season="summer",
       ingredients=["荔枝200g", "冰糖适量", "银耳半朵"],
       steps=["银耳泡发", "与荔枝冰糖炖煮", "小火炖30分钟"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_038", "杨梅生津饮", "杨梅性温味甘酸，生津止渴、和胃消食。《本草纲目》载其盐藏食、去痰止呕。夏季杨梅酸甜可口，可生津止渴，和胃消食。", "food_therapy", "夏季食疗", ["夏季", "生津", "消食", "杨梅"], season="summer",
       ingredients=["杨梅300g", "冰糖适量", "盐少许"],
       steps=["杨梅加盐浸泡洗净", "加冰糖煮水", "冷藏后饮用"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_039", "荷叶薏米粥", "荷叶性平味苦涩，清热解暑；薏米健脾渗湿。二味合用，可清暑利湿、健脾和中。夏季湿重天气，此粥可祛暑湿、助消化。", "food_therapy", "夏季食疗", ["夏季", "祛湿", "消暑", "荷叶"], season="summer",
       ingredients=["干荷叶10g", "薏米50g", "大米50g", "冰糖适量"],
       steps=["荷叶煮水取汁", "薏米大米用荷叶汁煮粥", "加冰糖调味"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_040", "莲子心茶", "莲子心性寒味苦，清心安神、交通心肾。《本草纲目》载其清心去热。夏季心火旺盛，莲子心茶可清心除烦，改善失眠，降血压。", "food_therapy", "夏季食疗", ["夏季", "清心", "安神", "莲子心"], season="summer",
       ingredients=["莲子心3g", "甘草2g", "蜂蜜适量"],
       steps=["莲子心甘草沸水冲泡", "闷5分钟", "加蜂蜜调味饮用"], difficulty="简单", duration="5分钟"),

    # ----- 秋季食疗 (20) -----
    _s("seed_food_therapy_041", "雪梨润肺汤", "梨性凉味甘微酸，润肺清热、化痰止咳。《本草纲目》载其润肺凉心、消痰降火。秋季燥邪伤肺，雪梨可润燥化痰，为秋令养肺首选。", "food_therapy", "秋季食疗", ["秋季", "润肺", "化痰", "梨"], season="autumn",
       ingredients=["雪梨1个", "冰糖20g", "川贝5g", "枸杞10g"],
       steps=["雪梨去核切块", "加冰糖川贝枸杞", "隔水炖30分钟"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_042", "银耳秋梨羹", "银耳性平味甘淡，滋阴润肺、养胃生津。《本草纲目》载其强精补肾、润肺生津。秋季配雪梨同炖，可滋阴润燥，养颜润肺。", "food_therapy", "秋季食疗", ["秋季", "滋阴", "润肺", "银耳"], season="autumn",
       ingredients=["银耳1朵", "雪梨1个", "红枣5颗", "冰糖适量"],
       steps=["银耳泡发撕碎", "雪梨切块", "小火慢炖1小时", "加冰糖调味"], difficulty="中等", duration="60分钟"),
    _s("seed_food_therapy_043", "百合秋梨粥", "百合性微寒味甘，润肺止咳、清心安神。《本草纲目》载其润肺清心。秋季配雪梨煮粥，可滋阴润燥，宁心安神，适合秋燥咳嗽。", "food_therapy", "秋季食疗", ["秋季", "润肺", "安神", "百合"], season="autumn",
       ingredients=["百合30g", "雪梨1个", "大米100g", "冰糖适量"],
       steps=["百合泡发", "雪梨切块", "与大米同煮粥", "加冰糖调味"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_044", "莲藕养胃汤", "莲藕性寒味甘，清热生津、凉血散瘀。《本草纲目》载其补中养神、益气力。秋季莲藕肥美，可清热润燥，健脾开胃，补血生肌。", "food_therapy", "秋季食疗", ["秋季", "养胃", "润燥", "莲藕"], season="autumn",
       ingredients=["莲藕500g", "排骨300g", "花生50g", "红枣5颗", "盐适量"],
       steps=["莲藕去皮切块", "排骨焯水", "全部材料煲汤1.5小时", "调味出锅"], difficulty="中等", duration="90分钟"),
    _s("seed_food_therapy_045", "山药健脾粥", "山药性平味甘，补脾养胃、生津益肺。《本草纲目》载其健脾胃、止泻痢。秋季以山药煮粥，可健脾润肺，固肾益精，为平补佳品。", "food_therapy", "秋季食疗", ["秋季", "健脾", "润肺", "山药"], season="autumn",
       ingredients=["山药200g", "小米50g", "红枣5颗", "枸杞10g"],
       steps=["山药去皮切丁", "小米红枣煮粥", "加入山药枸杞同煮"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_046", "南瓜补脾方", "南瓜性温味甘，补中益气、化痰排脓。《本草纲目》载其补中益气。秋季南瓜成熟，可健脾暖胃，补中益气，保护胃黏膜。", "food_therapy", "秋季食疗", ["秋季", "健脾", "暖胃", "南瓜"], season="autumn",
       ingredients=["南瓜300g", "小米50g", "红枣5颗"],
       steps=["南瓜切块蒸软", "与小米红枣煮粥", "煮至粘稠即可"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_047", "柿子润肺饮", "柿子性寒味甘涩，清热润肺、化痰止咳。《本草纲目》载其润心肺、止咳化痰。秋季柿子成熟，可润肺生津，但不可与螃蟹同食。", "food_therapy", "秋季食疗", ["秋季", "润肺", "生津", "柿子"], season="autumn",
       ingredients=["熟柿子2个", "蜂蜜适量", "牛奶200ml"],
       steps=["柿子去皮去核", "与牛奶蜂蜜打汁", "饮用即可"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_048", "葡萄养肝饮", "葡萄性平味甘酸，补气血、生津液。《本草纲目》载其益气倍力、强志。秋季葡萄丰收，可补益气血，滋养肝肾，强筋健骨。", "food_therapy", "秋季食疗", ["秋季", "补血", "养肝", "葡萄"], season="autumn",
       ingredients=["葡萄200g", "酸奶200ml", "蜂蜜适量"],
       steps=["葡萄洗净去籽", "与酸奶蜂蜜打汁", "饮用即可"], difficulty="简单", duration="5分钟"),
    _s("seed_food_therapy_049", "苹果润肠方", "苹果性凉味甘，生津润肺、除烦解暑。《本草纲目》载其润肺悦心、生津开胃。秋季食用苹果可生津润肺，促进消化，降低胆固醇。", "food_therapy", "秋季食疗", ["秋季", "润肺", "润肠", "苹果"], season="autumn",
       ingredients=["苹果2个", "蜂蜜适量", "肉桂粉少许"],
       steps=["苹果切块", "隔水蒸20分钟", "加蜂蜜肉桂粉食用"], difficulty="简单", duration="25分钟"),
    _s("seed_food_therapy_050", "柚子化痰饮", "柚子性寒味甘酸，健胃消食、化痰止咳。《本草纲目》载其消食、去肠胃中恶气。秋季柚子上市，可化痰止咳，消食下气，理气宽中。", "food_therapy", "秋季食疗", ["秋季", "化痰", "消食", "柚子"], season="autumn",
       ingredients=["柚子半个", "蜂蜜适量", "冰糖少许"],
       steps=["柚子取肉撕碎", "加冰糖隔水蒸", "加蜂蜜拌匀食用"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_051", "杏仁润肺粥", "杏仁性微温味苦，降气止咳平喘、润肠通便。《本草纲目》载其杀虫、治诸疮疥。秋季食杏仁可润肺止咳，但苦杏仁有毒需炮制。", "food_therapy", "秋季食疗", ["秋季", "润肺", "止咳", "杏仁"], season="autumn",
       ingredients=["甜杏仁20g", "大米100g", "冰糖适量"],
       steps=["甜杏仁泡去皮", "与大米煮粥", "加冰糖调味"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_052", "白果敛肺方", "白果性平味甘苦涩，敛肺定喘、止带缩尿。《本草纲目》载其生食降痰、消毒杀虫。秋季白果可敛肺平喘，但需熟食去毒，每次不过10粒。", "food_therapy", "秋季食疗", ["秋季", "敛肺", "定喘", "白果"], season="autumn",
       ingredients=["白果15粒", "鸭肉300g", "生姜3片", "盐适量"],
       steps=["白果去壳去心", "鸭肉焯水", "一同煲汤1小时", "调味出锅"], difficulty="中等", duration="70分钟"),
    _s("seed_food_therapy_053", "蜂蜜润燥饮", "蜂蜜性平味甘，补中润燥、止痛解毒。《本草纲目》载其入药之功有五。秋季燥邪当令，蜂蜜可润燥止咳，润肠通便，养颜护肤。", "food_therapy", "秋季食疗", ["秋季", "润燥", "养颜", "蜂蜜"], season="autumn",
       ingredients=["蜂蜜2勺", "温开水适量", "柠檬2片"],
       steps=["温水中加入蜂蜜", "加柠檬片", "搅匀饮用"], difficulty="简单", duration="2分钟"),
    _s("seed_food_therapy_054", "萝卜理气汤", "萝卜性凉味辛甘，下气消食、化痰止咳。《本草纲目》载其散服及炮煮服食，下大气消食。秋季萝卜称为土人参，可理气消食，清热化痰。", "food_therapy", "秋季食疗", ["秋季", "理气", "消食", "萝卜"], season="autumn",
       ingredients=["白萝卜500g", "排骨200g", "生姜3片", "盐适量"],
       steps=["萝卜切块", "排骨焯水", "一同煲汤1小时", "调味出锅"], difficulty="简单", duration="65分钟"),
    _s("seed_food_therapy_055", "茭白清热菜", "茭白性寒味甘，解热毒、除烦渴、利二便。《本草纲目》载其去烦热、止渴。秋季茭白鲜嫩，可清热除烦，通利二便，为水八仙之一。", "food_therapy", "秋季食疗", ["秋季", "清热", "除烦", "茭白"], season="autumn",
       ingredients=["茭白3根", "猪肉丝100g", "生抽适量", "盐适量"],
       steps=["茭白切丝", "肉丝滑炒", "加茭白翻炒", "调味出锅"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_056", "菱角补脾方", "菱角性凉味甘，健脾益胃、安中补脏。《本草纲目》载其安中补脏、不饥轻身。秋季菱角成熟，可健脾益气，轻身延年，为水乡珍品。", "food_therapy", "秋季食疗", ["秋季", "健脾", "益气", "菱角"], season="autumn",
       ingredients=["鲜菱角200g", "排骨300g", "红枣5颗", "盐适量"],
       steps=["菱角去壳", "排骨焯水", "一同煲汤1小时", "调味出锅"], difficulty="中等", duration="65分钟"),
    _s("seed_food_therapy_057", "栗子补肾粥", "栗子性温味甘，养胃健脾、补肾强筋。《本草纲目》载其益气厚肠胃、补肾气。秋季板栗香甜，可补肾强筋，健脾养胃，益气补血。", "food_therapy", "秋季食疗", ["秋季", "补肾", "健脾", "栗子"], season="autumn",
       ingredients=["板栗150g", "大米100g", "冰糖适量"],
       steps=["板栗去壳", "与大米煮粥", "煮至粘稠加冰糖"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_058", "秋葵润肠方", "秋葵性寒味甘，利咽、通淋、下乳、调经。《本草纲目》载其利咽喉、通小便。秋葵富含黏液蛋白，可保护胃黏膜，润肠通便。", "food_therapy", "秋季食疗", ["秋季", "润肠", "护胃", "秋葵"], season="autumn",
       ingredients=["秋葵200g", "蒜蓉适量", "生抽适量", "香油少许"],
       steps=["秋葵整根焯水3分钟", "切段摆盘", "蒜蓉淋汁调味"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_059", "芹菜平肝方", "芹菜性凉味甘，平肝清热、祛风利湿。《本草纲目》载其止血养精、保血脉。秋季食用芹菜可平肝清热，降血压，利水消肿。", "food_therapy", "秋季食疗", ["秋季", "平肝", "降压", "芹菜"], season="autumn",
       ingredients=["芹菜300g", "百合50g", "枸杞10g", "盐适量"],
       steps=["芹菜切段焯水", "百合泡发", "热油快炒", "调味出锅"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_060", "芝麻润肠方", "黑芝麻性平味甘，补肝肾、润五脏。《本草纲目》载其伤中虚羸、补五脏、益气力。秋季润燥，黑芝麻可滋养肝肾，润肠通便，乌发养颜。", "food_therapy", "秋季食疗", ["秋季", "润燥", "养发", "芝麻"], season="autumn",
       ingredients=["黑芝麻50g", "核桃30g", "蜂蜜适量", "牛奶200ml"],
       steps=["黑芝麻核桃炒香", "打碎加蜂蜜牛奶", "搅打均匀饮用"], difficulty="简单", duration="10分钟"),

    # ----- 冬季食疗 (20) -----
    _s("seed_food_therapy_061", "当归羊肉汤", "羊肉性温味甘，温中暖肾、益气补虚。《本草纲目》载其暖中补气、开胃健力。冬季配当归可温补气血，暖宫散寒，为冬季进补第一汤。", "food_therapy", "冬季食疗", ["冬季", "温补", "散寒", "羊肉"], season="winter",
       ingredients=["羊肉500g", "当归15g", "生姜5片", "枸杞10g", "盐适量"],
       steps=["羊肉焯水切块", "加当归姜片炖煮", "小火煲1.5小时", "加枸杞调味"], difficulty="中等", duration="100分钟"),
    _s("seed_food_therapy_062", "牛肉补气方", "牛肉性温味甘，补中益气、滋养脾胃。《本草纲目》载其安中益气、养脾胃。冬季食牛肉可强健筋骨，补益气血，增强御寒能力。", "food_therapy", "冬季食疗", ["冬季", "补气", "强筋", "牛肉"], season="winter",
       ingredients=["牛肉500g", "萝卜300g", "生姜5片", "八角2个", "盐适量"],
       steps=["牛肉焯水切块", "加萝卜姜片八角", "小火炖煮2小时", "调味出锅"], difficulty="中等", duration="120分钟"),
    _s("seed_food_therapy_063", "桂圆补血汤", "桂圆性温味甘，补心脾、益气血。《本草纲目》载其开胃益脾、补虚长智。冬季桂圆汤可温补心血，安神定志，改善手脚冰凉。", "food_therapy", "冬季食疗", ["冬季", "补血", "安神", "桂圆"], season="winter",
       ingredients=["桂圆干30g", "红枣10颗", "鸡蛋2个", "红糖适量"],
       steps=["桂圆红枣煮水", "打入荷包蛋", "加红糖调味"], difficulty="简单", duration="20分钟"),
    _s("seed_food_therapy_064", "红枣养血粥", "红枣性温味甘，补中益气、养血安神。《本草纲目》载其补气健脾、养血安神。冬季红枣粥可温补气血，暖胃散寒，增强体质。", "food_therapy", "冬季食疗", ["冬季", "养血", "暖胃", "红枣"], season="winter",
       ingredients=["红枣15颗", "糯米100g", "红糖适量", "桂圆10颗"],
       steps=["糯米红枣桂圆煮粥", "煮至粘稠", "加红糖调味"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_065", "核桃补肾方", "核桃性温味甘，补肾固精、温肺定喘。《本草纲目》载其补气养血、润燥化痰。冬季食核桃可补肾固精，温肺定喘，乌发健脑。", "food_therapy", "冬季食疗", ["冬季", "补肾", "健脑", "核桃"], season="winter",
       ingredients=["核桃仁50g", "黑芝麻30g", "红枣10颗", "红糖适量"],
       steps=["核桃黑芝麻炒香", "红枣煮水", "加入核桃芝麻粉", "加红糖调味"], difficulty="简单", duration="20分钟"),
    _s("seed_food_therapy_066", "黑芝麻补肾粥", "黑芝麻性平味甘，补肝肾、润五脏。《本草纲目》载其伤中虚羸、补五脏。冬季黑芝麻可滋补肝肾，润肠通便，乌发养颜。", "food_therapy", "冬季食疗", ["冬季", "补肾", "养发", "黑芝麻"], season="winter",
       ingredients=["黑芝麻30g", "大米100g", "核桃20g", "冰糖适量"],
       steps=["黑芝麻炒香研碎", "大米煮粥", "加入芝麻核桃", "加冰糖调味"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_067", "板栗炖鸡", "板栗性温味甘，养胃健脾、补肾强筋。《本草纲目》载其益气厚肠胃。冬季板栗配鸡肉，温补脾胃，补肾强筋，为冬令进补佳品。", "food_therapy", "冬季食疗", ["冬季", "健脾", "补肾", "板栗"], season="winter",
       ingredients=["板栗200g", "鸡肉500g", "生姜5片", "红枣5颗", "盐适量"],
       steps=["鸡肉焯水", "加板栗姜片红枣", "小火炖煮1小时", "调味出锅"], difficulty="中等", duration="70分钟"),
    _s("seed_food_therapy_068", "萝卜通气汤", "白萝卜性凉味辛甘，下气消食、化痰止咳。《本草纲目》载其主吞酸、化积滞。冬季萝卜称为小人参，可下气化痰，助消化。", "food_therapy", "冬季食疗", ["冬季", "消食", "化痰", "白萝卜"], season="winter",
       ingredients=["白萝卜500g", "羊肉200g", "生姜5片", "花椒5粒", "盐适量"],
       steps=["萝卜切块", "羊肉焯水", "一同炖煮1小时", "调味出锅"], difficulty="中等", duration="70分钟"),
    _s("seed_food_therapy_069", "白菜养胃方", "大白菜性平味甘，通利肠胃、清热除烦。《本草纲目》载其通利肠胃、除胸烦。冬季白菜耐储，可清热润燥，通利肠胃，为百菜之王。", "food_therapy", "冬季食疗", ["冬季", "养胃", "清热", "大白菜"], season="winter",
       ingredients=["大白菜500g", "豆腐1块", "粉丝50g", "盐适量"],
       steps=["白菜切段", "豆腐切块", "一起炖煮15分钟", "调味出锅"], difficulty="简单", duration="20分钟"),
    _s("seed_food_therapy_070", "红薯补脾方", "红薯性平味甘，补脾益胃、生津止渴。《本草纲目拾遗》载其补中、和血、暖胃。冬季红薯可健脾益气，润肠通便，为粗粮佳品。", "food_therapy", "冬季食疗", ["冬季", "健脾", "润肠", "红薯"], season="winter",
       ingredients=["红薯2个", "大米100g", "红枣5颗"],
       steps=["红薯去皮切块", "与大米红枣煮粥", "煮至粘稠"], difficulty="简单", duration="35分钟"),
    _s("seed_food_therapy_071", "芋头健脾方", "芋头性平味甘辛，健脾补虚、散结解毒。《本草纲目》载其宽肠胃、充肌肤。冬季芋头可健脾益胃，增强免疫，软坚散结。", "food_therapy", "冬季食疗", ["冬季", "健脾", "益气", "芋头"], season="winter",
       ingredients=["芋头300g", "排骨300g", "生姜3片", "盐适量"],
       steps=["芋头去皮切块", "排骨焯水", "一同煲汤1小时", "调味出锅"], difficulty="简单", duration="65分钟"),
    _s("seed_food_therapy_072", "糯米温中粥", "糯米性温味甘，补中益气、健脾暖胃。《本草纲目》载其暖脾胃、止虚寒泻痢。冬季糯米粥可温中散寒，补脾暖胃，适合虚寒体质。", "food_therapy", "冬季食疗", ["冬季", "温中", "暖胃", "糯米"], season="winter",
       ingredients=["糯米100g", "红枣10颗", "桂圆10颗", "红糖适量"],
       steps=["糯米红枣桂圆煮粥", "煮至粘稠", "加红糖调味"], difficulty="简单", duration="40分钟"),
    _s("seed_food_therapy_073", "枸杞温补茶", "枸杞子性平味甘，滋补肝肾、益精明目。《本草纲目》载其补肾生精、养肝明目。冬季枸杞可温补肝肾，益精血，明目安神。", "food_therapy", "冬季食疗", ["冬季", "补肾", "养肝", "枸杞"], season="winter",
       ingredients=["枸杞20g", "红枣5颗", "黄芪10g"],
       steps=["全部材料洗净", "沸水冲泡或煮水", "代茶饮用"], difficulty="简单", duration="10分钟"),
    _s("seed_food_therapy_074", "人参补气汤", "人参性微温味甘微苦，大补元气、复脉固脱。《本草纲目》载其补五脏、安精神。冬季人参可大补元气，增强免疫，但实热证忌用。", "food_therapy", "冬季食疗", ["冬季", "补气", "增强免疫", "人参"], season="winter",
       ingredients=["人参片10g", "鸡腿1个", "红枣5颗", "生姜3片", "盐适量"],
       steps=["鸡腿焯水", "加人参红枣姜片", "小火炖煮1小时", "调味出锅"], difficulty="中等", duration="70分钟"),
    _s("seed_food_therapy_075", "黄芪益气汤", "黄芪性微温味甘，补气固表、利尿托毒。《本草纲目》载其益气、固表、利水。冬季黄芪可补气固表，增强免疫，预防感冒。", "food_therapy", "冬季食疗", ["冬季", "补气", "固表", "黄芪"], season="winter",
       ingredients=["黄芪30g", "红枣10颗", "枸杞15g", "乌鸡半只", "盐适量"],
       steps=["乌鸡焯水", "加黄芪红枣炖煮", "小火煲2小时", "加枸杞调味"], difficulty="中等", duration="120分钟"),
    _s("seed_food_therapy_076", "当归暖宫汤", "当归性温味甘辛，补血活血、调经止痛。《本草纲目》载其治妇人诸疾。冬季当归汤可补血活血，暖宫散寒，改善痛经畏寒。", "food_therapy", "冬季食疗", ["冬季", "补血", "暖宫", "当归"], season="winter",
       ingredients=["当归15g", "鸡蛋2个", "红枣10颗", "红糖适量"],
       steps=["当归红枣煮水", "煮15分钟打入鸡蛋", "加红糖调味"], difficulty="简单", duration="25分钟"),
    _s("seed_food_therapy_077", "生姜驱寒方", "生姜性温味辛，解表散寒、温中止呕。《本草纲目》载其生用发散、熟用和中。冬季姜汤可温中散寒，预防风寒感冒，暖胃止呕。", "food_therapy", "冬季食疗", ["冬季", "驱寒", "暖胃", "生姜"], season="winter",
       ingredients=["生姜50g", "红糖30g", "大葱白3段"],
       steps=["生姜切片", "加水红糖煮开", "加葱白再煮5分钟"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_078", "大蒜杀菌方", "大蒜性温味辛，解毒杀虫、消肿止痛。《本草纲目》载其归五脏、散痈肿。冬季食大蒜可杀菌抗病毒，温中消食，预防感冒。", "food_therapy", "冬季食疗", ["冬季", "杀菌", "抗病毒", "大蒜"], season="winter",
       ingredients=["大蒜5瓣", "米醋适量", "冰糖少许"],
       steps=["大蒜去皮", "泡入米醋中", "加冰糖密封", "7天后食用"], difficulty="简单", duration="7天"),
    _s("seed_food_therapy_079", "花椒温中方", "花椒性温味辛，温中散寒、除湿止痛。《本草纲目》载其散寒除湿、解郁结。冬季花椒可温中散寒，驱除体内寒湿，暖胃止痛。", "food_therapy", "冬季食疗", ["冬季", "温中", "散寒", "花椒"], season="winter",
       ingredients=["花椒10g", "生姜5片", "红枣5颗", "红糖适量"],
       steps=["花椒姜片红枣煮水", "煮10分钟", "加红糖调味饮用"], difficulty="简单", duration="15分钟"),
    _s("seed_food_therapy_080", "八角暖胃汤", "八角性温味辛，温阳散寒、理气止痛。《本草纲目》载其主一切冷气及诸疝痛。冬季八角可温中散寒，理气止痛，促进消化。", "food_therapy", "冬季食疗", ["冬季", "暖胃", "理气", "八角"], season="winter",
       ingredients=["八角3个", "桂皮1小块", "牛肉500g", "生姜5片", "盐适量"],
       steps=["牛肉焯水", "加八角桂皮姜片", "小火炖煮2小时", "调味出锅"], difficulty="中等", duration="120分钟"),

    # ========== B. 穴位保健 (50条) ==========
    # ----- 头部穴位 (10) -----
    _s("seed_acupressure_001", "百会穴", "百会位于头顶正中，两耳尖连线与正中线交点。为诸阳之会，可升阳举陷、醒脑开窍。每日按揉3-5分钟，可缓解头痛眩晕，提升阳气。", "acupressure", "头部穴位", ["头部", "升阳", "止痛", "百会"], season=None,
       location="头顶正中线与两耳尖连线交点", method="拇指按揉或艾灸", effect="升阳举陷、醒脑开窍、缓解头痛", duration="3-5分钟"),
    _s("seed_acupressure_002", "太阳穴", "太阳穴位于眉梢与外眼角之间向后一横指的凹陷处。为经外奇穴，可疏风清热、止痛明目。按揉可缓解偏头痛、目赤肿痛，每日2-3分钟。", "acupressure", "头部穴位", ["头部", "止痛", "明目", "太阳"], season=None,
       location="眉梢与外眼角之间向后一横指凹陷处", method="双手中指按揉，顺时针旋转", effect="疏风清热、止痛明目、缓解偏头痛", duration="2-3分钟"),
    _s("seed_acupressure_003", "风池穴", "风池位于后颈部，枕骨下方，胸锁乳突肌与斜方肌上端之间的凹陷处。为足少阳胆经穴，可疏风解表、醒脑开窍。按揉可治颈项强痛、感冒头痛。", "acupressure", "头部穴位", ["头部", "祛风", "解表", "风池"], season=None,
       location="后颈部枕骨下，两侧凹陷处", method="双手拇指按揉，由轻到重", effect="疏风解表、缓解颈痛、治疗感冒头痛", duration="3-5分钟"),
    _s("seed_acupressure_004", "印堂穴", "印堂位于两眉头连线中点。为经外奇穴，可清头明目、通鼻开窍。按揉可缓解前额头痛、鼻塞不通、失眠眩晕，每日2-3分钟。", "acupressure", "头部穴位", ["头部", "明目", "通鼻", "印堂"], season=None,
       location="两眉头连线中点", method="中指或拇指按揉，上下推动", effect="清头明目、通鼻开窍、缓解头痛鼻塞", duration="2-3分钟"),
    _s("seed_acupressure_005", "四白穴", "四白位于面部，瞳孔直下，眶下孔凹陷处。为足阳明胃经穴，可祛风明目、通经活络。按揉可改善眼疲劳、面瘫、三叉神经痛。", "acupressure", "头部穴位", ["头部", "明目", "通络", "四白"], season=None,
       location="面部瞳孔直下，眶下孔凹陷处", method="食指按揉，轻柔打圈", effect="祛风明目、缓解眼疲劳、改善面部麻木", duration="2-3分钟"),
    _s("seed_acupressure_006", "迎香穴", "迎香位于鼻翼外缘中点旁开，鼻唇沟中。为手阳明大肠经穴，可通鼻窍、散风热。按揉可治鼻塞流涕、口眼歪斜，对过敏性鼻炎尤佳。", "acupressure", "头部穴位", ["头部", "通鼻", "散风", "迎香"], season=None,
       location="鼻翼外缘中点旁开鼻唇沟中", method="双手食指按揉，上下按压", effect="通鼻窍、散风热、治疗鼻炎鼻塞", duration="2-3分钟"),
    _s("seed_acupressure_007", "率谷穴", "率谷位于耳尖直上入发际1.5寸处。为足少阳胆经穴，可平肝息风、通络止痛。按揉可缓解偏头痛、眩晕、耳鸣，每日2-3分钟。", "acupressure", "头部穴位", ["头部", "止痛", "平肝", "率谷"], season=None,
       location="耳尖直上入发际1.5寸", method="拇指按揉，环形按揉", effect="平肝息风、缓解偏头痛、改善耳鸣", duration="2-3分钟"),
    _s("seed_acupressure_008", "天柱穴", "天柱位于后发际正中直上0.5寸，旁开1.3寸。为足太阳膀胱经穴，可疏风解表、舒筋活络。按揉可缓解颈项僵硬、头痛目眩。", "acupressure", "头部穴位", ["头部", "舒筋", "解表", "天柱"], season=None,
       location="后发际正中直上0.5寸旁开1.3寸", method="双手拇指按揉，由轻到重", effect="舒筋活络、缓解颈椎疲劳、改善头痛", duration="3-5分钟"),
    _s("seed_acupressure_009", "风府穴", "风府位于后发际正中直上1寸。为督脉穴，可散风息风、通关开窍。为风邪入侵之要冲，按揉可治感冒头痛、颈项强痛、中风不语。", "acupressure", "头部穴位", ["头部", "祛风", "开窍", "风府"], season=None,
       location="后发际正中直上1寸", method="中指按揉，轻柔为宜", effect="散风祛邪、通窍醒脑、缓解头痛", duration="2-3分钟"),
    _s("seed_acupressure_010", "哑门穴", "哑门位于后发际正中直上0.5寸。为督脉穴，可散风息风、开窍醒神。按揉可治舌缓不语、暴喑、颈项强痛。按揉时力度宜轻。", "acupressure", "头部穴位", ["头部", "开窍", "醒神", "哑门"], season=None,
       location="后发际正中直上0.5寸", method="中指轻揉，切忌用力过重", effect="开窍醒神、缓解颈项强痛", duration="1-2分钟"),

    # ----- 上肢穴位 (10) -----
    _s("seed_acupressure_011", "合谷穴", "合谷位于手背第1、2掌骨间，虎口处。为手阳明大肠经原穴，可镇静止痛、通经活络。为四总穴之一，治头面诸疾，可缓解头痛牙痛感冒。", "acupressure", "上肢穴位", ["上肢", "止痛", "通络", "合谷"], season=None,
       location="手背第1、2掌骨间虎口处", method="拇指按压对侧合谷，由轻到重", effect="镇静止痛、通经活络、治头面疾病", duration="3-5分钟"),
    _s("seed_acupressure_012", "内关穴", "内关位于前臂掌侧，腕横纹上2寸，两筋之间。为手厥阴心包经络穴，可宁心安神、和胃降逆。治心悸失眠、恶心呕吐、晕车。", "acupressure", "上肢穴位", ["上肢", "安神", "止呕", "内关"], season=None,
       location="前臂掌侧腕横纹上2寸两筋间", method="拇指按压，持续揉按", effect="宁心安神、和胃止呕、治心悸晕车", duration="3-5分钟"),
    _s("seed_acupressure_013", "曲池穴", "曲池位于肘横纹外侧端。为手阳明大肠经合穴，可疏风清热、调和气血。可治高血压、咽喉肿痛、发热、皮肤病，为保健要穴。", "acupressure", "上肢穴位", ["上肢", "清热", "降压", "曲池"], season=None,
       location="肘横纹外侧端凹陷处", method="拇指按揉，配合屈肘活动", effect="疏风清热、降血压、治皮肤病", duration="3-5分钟"),
    _s("seed_acupressure_014", "神门穴", "神门位于腕掌侧横纹尺侧端。为手少阴心经原穴，可宁心安神、清心泻火。治失眠心悸、健忘痴呆，为安神第一要穴。", "acupressure", "上肢穴位", ["上肢", "安神", "宁心", "神门"], season=None,
       location="腕掌侧横纹尺侧端凹陷处", method="拇指按揉，轻柔持久", effect="宁心安神、改善失眠、缓解心悸焦虑", duration="3-5分钟"),
    _s("seed_acupressure_015", "列缺穴", "列缺位于前臂桡侧缘，腕横纹上1.5寸。为手太阴肺经络穴，可宣肺利气、通络止痛。治咳嗽气喘、头痛项强。四总穴之一，头项寻列缺。", "acupressure", "上肢穴位", ["上肢", "宣肺", "止痛", "列缺"], season=None,
       location="前臂桡侧腕横纹上1.5寸", method="拇指按揉，上下推按", effect="宣肺利气、缓解咳嗽、治疗头痛项强", duration="3-5分钟"),
    _s("seed_acupressure_016", "外关穴", "外关位于前臂背侧，腕横纹上2寸。为手少阳三焦经络穴，可清热解表、通经活络。治感冒发热、耳鸣耳聋、上肢痹痛。", "acupressure", "上肢穴位", ["上肢", "清热", "解表", "外关"], season=None,
       location="前臂背侧腕横纹上2寸两骨间", method="拇指按揉，可配艾灸", effect="清热解表、治疗感冒发热耳鸣", duration="3-5分钟"),
    _s("seed_acupressure_017", "肩井穴", "肩井位于肩上大椎穴与肩峰端连线中点。为足少阳胆经穴，可祛风清热、活络消肿。治肩颈疼痛、乳汁不下、感冒。孕妇禁用。", "acupressure", "上肢穴位", ["上肢", "祛风", "活络", "肩井"], season=None,
       location="肩上大椎与肩峰连线中点", method="拇指按揉，配合肩部旋转", effect="祛风活络、缓解肩颈疼痛", duration="3-5分钟"),
    _s("seed_acupressure_018", "手三里穴", "手三里位于前臂背面桡侧，曲池下2寸。为手阳明大肠经穴，可通经活络、清热明目。治上肢麻木、齿痛颊肿、腹痛腹泻。", "acupressure", "上肢穴位", ["上肢", "通络", "明目", "手三里"], season=None,
       location="前臂桡侧曲池穴下2寸", method="拇指按揉，上下推动", effect="通经活络、缓解上肢麻木酸痛", duration="3-5分钟"),
    _s("seed_acupressure_019", "太渊穴", "太渊位于腕掌侧横纹桡侧端。为手太阴肺经原穴，可止咳化痰、通脉理血。治咳嗽气喘、腕臂痛、无脉症。为肺经母穴。", "acupressure", "上肢穴位", ["上肢", "止咳", "化痰", "太渊"], season=None,
       location="腕掌侧横纹桡侧端凹陷处", method="拇指按揉，轻柔点按", effect="止咳化痰、调理肺气、改善气喘", duration="2-3分钟"),
    _s("seed_acupressure_020", "少商穴", "少商位于拇指桡侧指甲角旁约0.1寸。为手太阴肺经井穴，可清热利咽、醒脑开窍。治咽喉肿痛、咳嗽发热、昏迷。可点刺放血。", "acupressure", "上肢穴位", ["上肢", "利咽", "清热", "少商"], season=None,
       location="拇指桡侧指甲角旁0.1寸", method="拇指掐按或点刺放血", effect="清热利咽、治疗咽喉肿痛", duration="1-2分钟"),

    # ----- 下肢穴位 (10) -----
    _s("seed_acupressure_021", "足三里穴", "足三里位于小腿外侧，犊鼻下3寸。为足阳明胃经合穴，可调理脾胃、补中益气。为全身强壮要穴第一，保健灸之可延年益寿。", "acupressure", "下肢穴位", ["下肢", "健脾", "强身", "足三里"], season=None,
       location="小腿外侧犊鼻下3寸胫骨旁1横指", method="拇指按揉或艾灸，力度适中", effect="调理脾胃、增强免疫、延年益寿", duration="5-10分钟"),
    _s("seed_acupressure_022", "三阴交穴", "三阴交位于内踝尖上3寸，胫骨内侧缘后。为肝脾肾三经交会穴，可健脾益血、调肝补肾。治妇科诸疾、失眠腹胀、遗精阳痿。", "acupressure", "下肢穴位", ["下肢", "调经", "补肾", "三阴交"], season=None,
       location="内踝尖上3寸胫骨内侧缘后方", method="拇指按揉，配合深呼吸", effect="健脾益血、调补肝肾、治妇科病", duration="3-5分钟"),
    _s("seed_acupressure_023", "太冲穴", "太冲位于足背第1、2跖骨结合部前方凹陷处。为足厥阴肝经原穴，可平肝息风、清热明目。治头痛眩晕、高血压、月经不调。为消气穴。", "acupressure", "下肢穴位", ["下肢", "平肝", "降压", "太冲"], season=None,
       location="足背第1、2跖骨结合部前凹陷处", method="拇指按压，由轻到重", effect="平肝息风、降压明目、疏肝解郁", duration="3-5分钟"),
    _s("seed_acupressure_024", "涌泉穴", "涌泉位于足底部，蜷足时足前部凹陷处。为足少阴肾经井穴，可滋阴益肾、平肝息风。为肾经首穴，按摩可引火归元，安神助眠。", "acupressure", "下肢穴位", ["下肢", "补肾", "安神", "涌泉"], season=None,
       location="足底前1/3处蜷足凹陷中", method="拇指擦揉或搓擦脚心", effect="滋阴益肾、安神助眠、引火归元", duration="5-10分钟"),
    _s("seed_acupressure_025", "阳陵泉穴", "阳陵泉位于小腿外侧，腓骨小头前下方凹陷处。为足少阳胆经合穴、筋会，可疏肝利胆、舒筋活络。治筋脉拘挛、口苦黄疸、胁肋疼痛。", "acupressure", "下肢穴位", ["下肢", "利胆", "舒筋", "阳陵泉"], season=None,
       location="小腿外侧腓骨小头前下方凹陷处", method="拇指按揉，可配合弹拨", effect="疏肝利胆、舒筋活络、治筋病", duration="3-5分钟"),
    _s("seed_acupressure_026", "血海穴", "血海位于髌骨内上缘上2寸。为足太阴脾经穴，可活血化瘀、补血养血。治月经不调、荨麻疹、膝痛。为血症要穴。", "acupressure", "下肢穴位", ["下肢", "活血", "补血", "血海"], season=None,
       location="髌骨内上缘上2寸股四头肌内侧头隆起处", method="拇指或掌根按揉", effect="活血化瘀、调经止痒、治血症", duration="3-5分钟"),
    _s("seed_acupressure_027", "委中穴", "委中位于腘横纹中点。为足太阳膀胱经合穴，可舒筋活络、清热解毒。四总穴之一，腰背委中求。治腰背疼痛、下肢痿痹、腹痛吐泻。", "acupressure", "下肢穴位", ["下肢", "舒筋", "治腰", "委中"], season=None,
       location="腘横纹中点", method="拇指按揉或点按", effect="舒筋活络、缓解腰背疼痛、治腿痛", duration="3-5分钟"),
    _s("seed_acupressure_028", "太溪穴", "太溪位于内踝尖与跟腱之间凹陷处。为足少阴肾经原穴，可滋补肾阴、益肾纳气。治腰痛、耳鸣、失眠、遗精。为肾经原穴。", "acupressure", "下肢穴位", ["下肢", "补肾", "滋阴", "太溪"], season=None,
       location="内踝尖与跟腱之间凹陷处", method="拇指按揉，配艾灸更佳", effect="滋补肾阴、益肾纳气、改善腰膝酸软", duration="3-5分钟"),
    _s("seed_acupressure_029", "行间穴", "行间位于足背第1、2趾间缝纹端。为足厥阴肝经荥穴，可清肝泻火、凉血安神。治头痛眩晕、目赤肿痛、痛经、高血压。", "acupressure", "下肢穴位", ["下肢", "泻火", "凉血", "行间"], season=None,
       location="足背第1、2趾间缝纹端", method="拇指按揉，力度稍重", effect="清肝泻火、凉血安神、降压止痛", duration="2-3分钟"),
    _s("seed_acupressure_030", "商丘穴", "商丘位于内踝前下方凹陷处。为足太阴脾经经穴，可健脾化湿、调经止血。治腹胀泄泻、消化不良、足踝肿痛。为脾经金穴。", "acupressure", "下肢穴位", ["下肢", "健脾", "化湿", "商丘"], season=None,
       location="内踝前下方凹陷中", method="拇指按揉，轻柔持续", effect="健脾化湿、调经止血、治踝关节痛", duration="3-5分钟"),

    # ----- 背部穴位 (10) -----
    _s("seed_acupressure_031", "命门穴", "命门位于后正中线上，第2腰椎棘突下凹陷中。为督脉穴，可温肾壮阳、强腰固本。为肾之命门，艾灸可补肾壮阳，治腰痛阳痿。", "acupressure", "背部穴位", ["背部", "补肾", "壮阳", "命门"], season=None,
       location="后正中线第2腰椎棘突下", method="手掌擦热后搓命门，或艾灸", effect="温肾壮阳、强腰固本、治腰膝冷痛", duration="5-10分钟"),
    _s("seed_acupressure_032", "肾俞穴", "肾俞位于第2腰椎棘突下旁开1.5寸。为足太阳膀胱经穴，可补肾益精、温肾壮阳。治腰膝酸痛、耳鸣耳聋、遗精阳痿、水肿。", "acupressure", "背部穴位", ["背部", "补肾", "益精", "肾俞"], season=None,
       location="第2腰椎棘突下旁开1.5寸", method="双拳背按揉肾俞或艾灸", effect="补肾益精、强腰膝、治腰痛遗精", duration="5-10分钟"),
    _s("seed_acupressure_033", "肝俞穴", "肝俞位于第9胸椎棘突下旁开1.5寸。为足太阳膀胱经穴，可疏肝利胆、养血明目。治胁肋胀痛、目赤目眩、黄疸、脊背痛。", "acupressure", "背部穴位", ["背部", "疏肝", "利胆", "肝俞"], season=None,
       location="第9胸椎棘突下旁开1.5寸", method="拇指按揉或拍打，配合深呼吸", effect="疏肝利胆、养血明目、缓解胁痛", duration="3-5分钟"),
    _s("seed_acupressure_034", "脾俞穴", "脾俞位于第11胸椎棘突下旁开1.5寸。为足太阳膀胱经穴，可健脾化湿、益气统血。治腹胀泄泻、消化不良、水肿、便血。", "acupressure", "背部穴位", ["背部", "健脾", "化湿", "脾俞"], season=None,
       location="第11胸椎棘突下旁开1.5寸", method="掌根按揉或艾灸", effect="健脾化湿、益气统血、治脾胃病", duration="5-10分钟"),
    _s("seed_acupressure_035", "胃俞穴", "胃俞位于第12胸椎棘突下旁开1.5寸。为足太阳膀胱经穴，可和胃健脾、化湿降逆。治胃痛呕吐、腹胀肠鸣、消化不良。", "acupressure", "背部穴位", ["背部", "和胃", "健脾", "胃俞"], season=None,
       location="第12胸椎棘突下旁开1.5寸", method="拇指按揉，配合掌根推擦", effect="和胃健脾、降逆止呕、治胃痛", duration="3-5分钟"),
    _s("seed_acupressure_036", "肺俞穴", "肺俞位于第3胸椎棘突下旁开1.5寸。为足太阳膀胱经穴，可宣肺平喘、益气固表。治咳嗽气喘、鼻塞、感冒、皮肤瘙痒。", "acupressure", "背部穴位", ["背部", "宣肺", "平喘", "肺俞"], season=None,
       location="第3胸椎棘突下旁开1.5寸", method="拇指按揉或艾灸，配合拍背", effect="宣肺平喘、益气固表、治咳嗽", duration="3-5分钟"),
    _s("seed_acupressure_037", "心俞穴", "心俞位于第5胸椎棘突下旁开1.5寸。为足太阳膀胱经穴，可宁心安神、调和气血。治心痛心悸、失眠健忘、梦遗盗汗。", "acupressure", "背部穴位", ["背部", "安神", "宁心", "心俞"], season=None,
       location="第5胸椎棘突下旁开1.5寸", method="拇指轻揉，力度适中", effect="宁心安神、调和气血、治心悸失眠", duration="3-5分钟"),
    _s("seed_acupressure_038", "大肠俞穴", "大肠俞位于第4腰椎棘突下旁开1.5寸。为足太阳膀胱经穴，可通调肠胃、强健腰膝。治腰腿痛、腹胀肠鸣、便秘腹泻。", "acupressure", "背部穴位", ["背部", "通肠", "强腰", "大肠俞"], season=None,
       location="第4腰椎棘突下旁开1.5寸", method="拇指按揉或掌根推擦", effect="通调肠胃、强健腰膝、治便秘腰痛", duration="3-5分钟"),
    _s("seed_acupressure_039", "膀胱俞穴", "膀胱俞位于第2骶椎棘突下旁开1.5寸。为足太阳膀胱经穴，可清热利湿、通利膀胱。治小便不利、遗尿、腰脊强痛。", "acupressure", "背部穴位", ["背部", "利湿", "通淋", "膀胱俞"], season=None,
       location="第2骶椎棘突下旁开1.5寸", method="拇指按揉，配合艾灸", effect="清热利湿、通利膀胱、治尿频", duration="3-5分钟"),
    _s("seed_acupressure_040", "八髎穴", "八髎位于骶骨部，由上髎、次髎、中髎、下髎左右共八穴组成。为膀胱经穴，可调经止痛、强壮腰膝。为妇科要穴，治月经不调、腰痛。", "acupressure", "背部穴位", ["背部", "调经", "强腰", "八髎"], season=None,
       location="骶骨部第一至第四对骶后孔", method="掌根搓擦八髎区域至发热", effect="调经止痛、强壮腰膝、治妇科病", duration="5-10分钟"),

    # ----- 胸腹穴位 (10) -----
    _s("seed_acupressure_041", "气海穴", "气海位于前正中线上，脐下1.5寸。为任脉穴，可补气固本、温阳益气。为元气之海，灸之可培补元气，治气虚乏力、遗精阳痿。", "acupressure", "胸腹穴位", ["胸腹", "补气", "固本", "气海"], season=None,
       location="前正中线脐下1.5寸", method="掌根按揉或艾灸", effect="补气固本、温阳益气、治气虚乏力", duration="5-10分钟"),
    _s("seed_acupressure_042", "关元穴", "关元位于前正中线上，脐下3寸。为任脉穴、小肠募穴，可培元固本、补益下焦。为保健要穴，灸之可补肾壮阳，治虚劳。", "acupressure", "胸腹穴位", ["胸腹", "培元", "固本", "关元"], season=None,
       location="前正中线脐下3寸", method="掌根按揉或艾灸，配合深呼吸", effect="培元固本、补肾壮阳、治虚劳", duration="5-10分钟"),
    _s("seed_acupressure_043", "中脘穴", "中脘位于前正中线上，脐上4寸。为任脉穴、胃募穴，可健脾和胃、补中安神。为胃之募穴，治胃痛呕吐、腹胀泄泻、失眠。", "acupressure", "胸腹穴位", ["胸腹", "和胃", "健脾", "中脘"], season=None,
       location="前正中线脐上4寸", method="掌根按揉，顺时针揉", effect="健脾和胃、补中安神、治胃病", duration="5-10分钟"),
    _s("seed_acupressure_044", "膻中穴", "膻中位于前正中线上，两乳头连线中点。为任脉穴、心包募穴，可宽胸理气、活血通络。为气会，治胸闷气短、心悸咳嗽。", "acupressure", "胸腹穴位", ["胸腹", "理气", "宽胸", "膻中"], season=None,
       location="前正中线两乳头连线中点", method="双手掌根重叠按揉", effect="宽胸理气、活血通络、治胸闷", duration="3-5分钟"),
    _s("seed_acupressure_045", "天枢穴", "天枢位于脐旁2寸。为足阳明胃经穴、大肠募穴，可调理肠胃、通便止泻。治腹胀便秘、腹泻痢疾、月经不调。", "acupressure", "胸腹穴位", ["胸腹", "通肠", "调理", "天枢"], season=None,
       location="脐旁2寸", method="双手拇指按揉，顺时针方向", effect="调理肠胃、通便止泻、治腹胀", duration="3-5分钟"),
    _s("seed_acupressure_046", "中极穴", "中极位于前正中线上，脐下4寸。为任脉穴、膀胱募穴，可补肾培元、清热利湿。治小便不利、遗尿、阳痿、月经不调。", "acupressure", "胸腹穴位", ["胸腹", "补肾", "利湿", "中极"], season=None,
       location="前正中线脐下4寸", method="掌根按揉或艾灸", effect="补肾培元、通利膀胱、治泌尿病", duration="3-5分钟"),
    _s("seed_acupressure_047", "神阙穴", "神阙即肚脐。为任脉穴，可温阳救逆、利水固脱。为先天之本源，禁针，可灸可敷。治腹痛泄泻、虚脱、水肿。", "acupressure", "胸腹穴位", ["胸腹", "温阳", "固脱", "神阙"], season=None,
       location="脐中央", method="手掌覆脐按揉或艾灸隔盐灸", effect="温阳救逆、健脾和胃、治腹痛", duration="5-10分钟"),
    _s("seed_acupressure_048", "期门穴", "期门位于乳头直下，第6肋间隙。为足厥阴肝经募穴，可疏肝理气、活血化瘀。治胸胁胀痛、腹胀、呕吐、乳痈。", "acupressure", "胸腹穴位", ["胸腹", "疏肝", "理气", "期门"], season=None,
       location="乳头直下第6肋间隙", method="拇指按揉，轻柔为宜", effect="疏肝理气、活血化瘀、治胁痛", duration="2-3分钟"),
    _s("seed_acupressure_049", "日月穴", "日月位于乳头直下，第7肋间隙。为足少阳胆经募穴，可疏肝利胆、清热化湿。治胁肋疼痛、呕吐吞酸、黄疸。", "acupressure", "胸腹穴位", ["胸腹", "利胆", "清热", "日月"], season=None,
       location="乳头直下第7肋间隙", method="拇指按揉，力度适中", effect="疏肝利胆、清热化湿、治胁痛", duration="2-3分钟"),
    _s("seed_acupressure_050", "章门穴", "章门位于第11肋骨游离端下方。为足厥阴肝经募穴、脏会，可疏肝健脾、理气散结。治胁痛腹胀、痞块呕吐、泄泻。", "acupressure", "胸腹穴位", ["胸腹", "疏肝", "健脾", "章门"], season=None,
       location="侧腹部第11肋骨游离端下方", method="掌根按揉，配合深呼吸", effect="疏肝健脾、理气散结、治腹胀", duration="3-5分钟"),

    # ========== C. 运动功法 (30条) ==========
    # ----- 传统功法 (8) -----
    _s("seed_exercise_001", "八段锦", "八段锦为传统导引功法，由八个动作组成，可调理脏腑、疏通经络。两手托天理三焦、左右开弓似射雕等，每日15分钟可强身健体。", "exercise", "传统功法", ["传统", "导引", "养生", "八段锦"], season=None,
       benefits=["调理气血", "疏通经络", "增强体质"], difficulty="简单", duration="15分钟"),
    _s("seed_exercise_002", "太极拳", "太极拳以柔克刚、动静结合，融合阴阳哲理。可调和气血、平衡阴阳，改善心肺功能和平衡能力。每日练习30分钟，身心受益。", "exercise", "传统功法", ["传统", "太极", "平衡", "太极拳"], season=None,
       benefits=["调和气血", "平衡阴阳", "增强协调"], difficulty="中等", duration="30分钟"),
    _s("seed_exercise_003", "五禽戏", "五禽戏模仿虎鹿熊猿鸟五种动物的动作，由华佗创编。可增强五脏功能，活动筋骨关节，提高免疫力。每日20分钟。", "exercise", "传统功法", ["传统", "仿生", "养生", "五禽戏"], season=None,
       benefits=["增强脏腑", "活动关节", "提高免疫"], difficulty="中等", duration="20分钟"),
    _s("seed_exercise_004", "六字诀", "六字诀通过嘘呵呼呬吹嘻六字发音配合呼吸，可调理五脏六腑。嘘肝呵心呼脾呬肺吹肾嘻三焦，每日练习可调和脏腑气机。", "exercise", "传统功法", ["传统", "呼吸", "养生", "六字诀"], season=None,
       benefits=["调理脏腑", "调和气机", "吐故纳新"], difficulty="简单", duration="15分钟"),
    _s("seed_exercise_005", "易筋经", "易筋经为少林传统功法，以拉伸筋骨为主，可强筋健骨、内壮脏腑。十二势如韦驮献杵、摘星换斗等，每日练习可增强体力。", "exercise", "传统功法", ["传统", "强筋", "少林", "易筋经"], season=None,
       benefits=["强筋健骨", "内壮脏腑", "增强体力"], difficulty="中等", duration="20分钟"),
    _s("seed_exercise_006", "导引术", "导引术为古代养生方法，通过肢体运动配合呼吸导引，可疏通经络、调和气血。马王堆出土导引图记载数十种导引姿势。", "exercise", "传统功法", ["传统", "导引", "呼吸", "导引术"], season=None,
       benefits=["疏通经络", "调和气血", "延年益寿"], difficulty="简单", duration="20分钟"),
    _s("seed_exercise_007", "站桩功", "站桩为传统内功心法，通过保持特定姿势静立，可培蓄内气、强健筋骨。常见浑圆桩、三体式等，每日站桩15-30分钟。", "exercise", "传统功法", ["传统", "内功", "静功", "站桩"], season=None,
       benefits=["培蓄内气", "强健筋骨", "调理气血"], difficulty="中等", duration="15-30分钟"),
    _s("seed_exercise_008", "打坐冥想", "打坐即静坐禅修，通过调身调息调心达到身心统一。可清心寡欲、安定心神。盘坐闭目观呼吸，每日15-30分钟可改善心理健康。", "exercise", "传统功法", ["传统", "静坐", "冥想", "打坐"], season=None,
       benefits=["安定心神", "清心寡欲", "改善心理"], difficulty="中等", duration="15-30分钟"),

    # ----- 日常运动 (8) -----
    _s("seed_exercise_009", "散步养生", "散步是最简便有效的养生运动。饭后百步走，活到九十九。可促进消化、放松心情、预防心血管疾病。每日30-60分钟为宜。", "exercise", "日常运动", ["日常", "有氧", "简单", "散步"], season=None,
       benefits=["促进消化", "放松心情", "预防心血管病"], difficulty="简单", duration="30-60分钟"),
    _s("seed_exercise_010", "慢跑健身", "慢跑为中等强度有氧运动，可增强心肺功能、燃烧脂肪、提高免疫力。建议每周3-5次，每次20-30分钟，心率控制在120-140次。", "exercise", "日常运动", ["日常", "有氧", "健身", "慢跑"], season=None,
       benefits=["增强心肺", "燃烧脂肪", "提高免疫"], difficulty="中等", duration="20-30分钟"),
    _s("seed_exercise_011", "游泳锻炼", "游泳为全身运动，可锻炼心肺、增强肌肉力量。水的浮力减少关节负担，适合各年龄段。每周2-3次，每次30-45分钟。", "exercise", "日常运动", ["日常", "全身", "低冲击", "游泳"], season=None,
       benefits=["锻炼心肺", "增强肌肉", "保护关节"], difficulty="中等", duration="30-45分钟"),
    _s("seed_exercise_012", "骑行运动", "骑行为低冲击有氧运动，可锻炼下肢力量、增强心肺功能。户外骑行还可呼吸新鲜空气，放松心情。每次30-60分钟为宜。", "exercise", "日常运动", ["日常", "有氧", "户外", "骑行"], season=None,
       benefits=["锻炼下肢", "增强心肺", "放松心情"], difficulty="中等", duration="30-60分钟"),
    _s("seed_exercise_013", "瑜伽拉伸", "瑜伽融合体位法、呼吸法和冥想，可增强柔韧性、缓解压力。各种体式可针对性地调理身体。每周3-5次，每次30-60分钟。", "exercise", "日常运动", ["日常", "柔韧", "减压", "瑜伽"], season=None,
       benefits=["增强柔韧", "缓解压力", "调理身心"], difficulty="简单", duration="30-60分钟"),
    _s("seed_exercise_014", "太极球运动", "太极球结合太极拳原理，持球做各种圆转动作，可增强手臂力量、协调性和平衡感。适合中老年人，每日练习15-20分钟。", "exercise", "日常运动", ["日常", "协调", "养生", "太极球"], season=None,
       benefits=["增强力量", "提高协调", "平衡身心"], difficulty="简单", duration="15-20分钟"),
    _s("seed_exercise_015", "踢毽子", "踢毽子为传统民间运动，可锻炼下肢灵活性和反应能力。适合各年龄段，室内外均可。每次15-20分钟，有趣又健身。", "exercise", "日常运动", ["日常", "灵活", "趣味", "踢毽子"], season=None,
       benefits=["锻炼下肢", "提高反应", "趣味健身"], difficulty="简单", duration="15-20分钟"),
    _s("seed_exercise_016", "跳绳运动", "跳绳为高效有氧运动，可燃烧大量卡路里、增强心肺功能。每次10-15分钟相当于慢跑30分钟。注意选择合适场地和鞋子。", "exercise", "日常运动", ["日常", "有氧", "高效", "跳绳"], season=None,
       benefits=["燃烧脂肪", "增强心肺", "提高协调"], difficulty="中等", duration="10-15分钟"),

    # ----- 办公运动 (7) -----
    _s("seed_exercise_017", "颈部运动", "长时间伏案易致颈椎僵硬。每隔1小时做颈部运动：前屈后仰各10次，左右旋转各10次，可有效缓解颈椎疲劳，预防颈椎病。", "exercise", "办公运动", ["办公", "颈椎", "放松", "颈部"], season=None,
       benefits=["缓解颈椎疲劳", "预防颈椎病", "放松肩颈"], difficulty="简单", duration="5分钟", best_time="每小时一次"),
    _s("seed_exercise_018", "肩部拉伸", "办公族肩部常处于紧张状态。每隔1小时做肩部环绕和拉伸：双肩上提后放各10次，双手交叉向后拉伸15秒，可缓解肩部酸痛。", "exercise", "办公运动", ["办公", "肩部", "放松", "肩部拉伸"], season=None,
       benefits=["缓解肩部酸痛", "放松肩背", "改善体态"], difficulty="简单", duration="3-5分钟", best_time="每小时一次"),
    _s("seed_exercise_019", "腰部转动", "久坐易致腰肌劳损。每隔1小时做腰部运动：双手叉腰顺逆时针各转10圈，左右侧弯各5次，可缓解腰部僵硬疼痛。", "exercise", "办公运动", ["办公", "腰部", "放松", "腰部转动"], season=None,
       benefits=["缓解腰部僵硬", "预防腰肌劳损", "活动腰椎"], difficulty="简单", duration="3-5分钟", best_time="每小时一次"),
    _s("seed_exercise_020", "腿部伸展", "久坐下肢血液循环不畅。每隔1小时做腿部伸展：坐位抬腿交替各10次，站起踮脚10次，可促进下肢血液循环，预防静脉曲张。", "exercise", "办公运动", ["办公", "腿部", "循环", "腿部伸展"], season=None,
       benefits=["促进下肢循环", "预防静脉曲张", "消除水肿"], difficulty="简单", duration="3-5分钟", best_time="每小时一次"),
    _s("seed_exercise_021", "手腕运动", "长期使用鼠标键盘易致腕管综合征。每隔1小时做手腕运动：旋转手腕各10圈，手指伸展握拳各10次，可预防手腕酸痛。", "exercise", "办公运动", ["办公", "手腕", "放松", "手腕运动"], season=None,
       benefits=["预防腕管综合征", "缓解手腕酸痛", "灵活手指"], difficulty="简单", duration="2-3分钟", best_time="每小时一次"),
    _s("seed_exercise_022", "眼部保健操", "长时间看屏幕易致眼疲劳。每隔45分钟做眼部保健：闭目休息1分钟，远眺30秒，眼球上下左右转动各10次，可保护视力。", "exercise", "办公运动", ["办公", "眼部", "护眼", "眼部保健"], season=None,
       benefits=["缓解眼疲劳", "保护视力", "预防近视"], difficulty="简单", duration="3-5分钟", best_time="每45分钟一次"),
    _s("seed_exercise_023", "深呼吸练习", "久坐姿势使呼吸变浅。每隔1小时做3-5次腹式深呼吸：鼻吸4秒，腹扩；口呼6秒，腹缩。可增加供氧量，提神醒脑。", "exercise", "办公运动", ["办公", "呼吸", "放松", "深呼吸"], season=None,
       benefits=["增加供氧", "提神醒脑", "缓解焦虑"], difficulty="简单", duration="2-3分钟", best_time="每小时一次"),

    # ----- 季节运动 (7) -----
    _s("seed_exercise_024", "春季踏青", "春回大地，宜外出踏青。春季阳气生发，户外散步或郊游可助肝气疏泄，舒展筋骨，愉悦心情。《黄帝内经》谓春三月宜广步于庭。", "exercise", "季节运动", ["春季", "户外", "踏青", "散步"], season="spring",
       benefits=["疏肝解郁", "舒展筋骨", "愉悦心情"], difficulty="简单", duration="30-60分钟"),
    _s("seed_exercise_025", "夏季游泳", "夏季炎热，游泳为最佳运动选择。水中运动可消暑降温，锻炼全身肌肉，对关节冲击小。建议避开正午，选择早晚时段游泳。", "exercise", "季节运动", ["夏季", "消暑", "游泳", "水中"], season="summer",
       benefits=["消暑降温", "全身锻炼", "保护关节"], difficulty="中等", duration="30-45分钟"),
    _s("seed_exercise_026", "秋季登山", "秋高气爽，宜登山远足。《黄帝内经》谓秋三月宜早卧早起，与鸡俱兴。登山可增强心肺功能，呼吸新鲜空气，舒畅情志。", "exercise", "季节运动", ["秋季", "登山", "户外", "远足"], season="autumn",
       benefits=["增强心肺", "舒畅情志", "强健体魄"], difficulty="中等", duration="60-120分钟"),
    _s("seed_exercise_027", "冬季慢跑", "冬季宜适度运动以御寒。慢跑可促进血液循环，增强御寒能力。注意充分热身，选择白天时段，避免清晨寒气太重。", "exercise", "季节运动", ["冬季", "御寒", "慢跑", "有氧"], season="winter",
       benefits=["促进循环", "增强御寒", "提高免疫"], difficulty="中等", duration="20-30分钟"),
    _s("seed_exercise_028", "四季太极", "太极拳四季皆宜，为最佳养生运动之一。春季练太极助肝气疏泄，夏季助心气调和，秋季助肺气清肃，冬季助肾气封藏。", "exercise", "季节运动", ["四季", "太极", "养生", "平衡"], season=None,
       benefits=["调和阴阳", "增强免疫", "修身养性"], difficulty="中等", duration="30分钟"),
    _s("seed_exercise_029", "清晨散步", "清晨空气清新，适合散步。卯时（5-7点）大肠经当令，起床后散步可促进排便，激活身体机能。建议餐前散步20-30分钟。", "exercise", "季节运动", ["四季", "清晨", "散步", "养生"], season=None,
       benefits=["促进排便", "激活机能", "呼吸新鲜空气"], difficulty="简单", duration="20-30分钟"),
    _s("seed_exercise_030", "傍晚散步", "酉时（17-19点）肾经当令，傍晚散步可补肾养精。饭后散步有助消化，但不宜饭后立即运动，建议饭后30分钟再散步。", "exercise", "季节运动", ["四季", "傍晚", "散步", "养生"], season=None,
       benefits=["补肾养精", "助消化", "放松身心"], difficulty="简单", duration="30分钟"),

    # ========== D. 睡眠建议 (20条) ==========
    # ----- 入睡技巧 (5) -----
    _s("seed_sleep_tip_001", "478呼吸法", "478呼吸法由安德鲁·韦伊博士推广。吸气4秒，屏息7秒，呼气8秒。循环4次即可。此法可激活副交感神经，降低心率，帮助快速入睡。", "sleep_tip", "入睡技巧", ["睡眠", "呼吸", "放松", "入睡"], season=None,
       method="鼻吸气4秒-屏息7秒-口呼气8秒，循环4次", effect="激活副交感神经，降低心率，快速入睡", duration="约2分钟"),
    _s("seed_sleep_tip_002", "渐进式肌肉放松", "从脚趾开始，依次绷紧再放松各部位肌肉，从下至上至头部。每组肌肉绷紧5秒后放松10秒。可释放身体紧张感，促进深度睡眠。", "sleep_tip", "入睡技巧", ["睡眠", "放松", "肌肉", "入睡"], season=None,
       method="从脚到头依次绷紧放松各肌肉群，每组5秒绷紧10秒放松", effect="释放身体紧张感，促进全身放松入睡", duration="15-20分钟"),
    _s("seed_sleep_tip_003", "身体扫描冥想", "闭目躺平，将注意力从脚尖慢慢上移至头顶，感受每个部位的状态。不带评判地觉察身体感受。可减少杂念，引导身心进入放松状态。", "sleep_tip", "入睡技巧", ["睡眠", "冥想", "放松", "入睡"], season=None,
       method="闭目从脚尖到头顶逐步感受身体各部位", effect="减少杂念，引导身心放松，促进入睡", duration="10-15分钟"),
    _s("seed_sleep_tip_004", "数息法", "闭目调息，专注于呼吸。每次呼气时默默计数，从1数到10再从头开始。若走神则重新开始。此法可安定心神，减少入睡前的焦虑。", "sleep_tip", "入睡技巧", ["睡眠", "呼吸", "专注", "入睡"], season=None,
       method="闭目专注呼吸，每次呼气从1数到10", effect="安定心神，减少焦虑，帮助入睡", duration="5-10分钟"),
    _s("seed_sleep_tip_005", "引导意象法", "闭目想象一个宁静舒适的场景，如海滩日落、森林小溪。尽可能调动五感，沉浸其中。可转移注意力，减少失眠焦虑，自然入眠。", "sleep_tip", "入睡技巧", ["睡眠", "想象", "放松", "入睡"], season=None,
       method="闭目想象宁静场景，调动五感沉浸其中", effect="转移注意力，减少焦虑，引导入睡", duration="5-10分钟"),

    # ----- 睡前习惯 (5) -----
    _s("seed_sleep_tip_006", "温水泡脚", "睡前用40-45度温水泡脚15-20分钟，可引血下行、温暖全身、放松神经。加入艾叶、红花效果更佳。为中医经典助眠方法。", "sleep_tip", "睡前习惯", ["睡眠", "泡脚", "温暖", "习惯"], season=None,
       method="40-45度温水泡脚15-20分钟，可加艾叶红花", effect="引血下行，温暖全身，放松神经促眠", duration="15-20分钟", best_time="睡前1小时"),
    _s("seed_sleep_tip_007", "热牛奶助眠", "牛奶富含色氨酸，可转化为褪黑素促进睡眠。睡前1小时喝一杯温牛奶，可温暖肠胃、安定心神。加入少许蜂蜜效果更佳。", "sleep_tip", "睡前习惯", ["睡眠", "牛奶", "营养", "习惯"], season=None,
       method="睡前1小时饮一杯温牛奶，可加蜂蜜调味", effect="补充色氨酸，促进褪黑素分泌，助眠", duration="即时", best_time="睡前1小时"),
    _s("seed_sleep_tip_008", "远离电子屏幕", "睡前1小时应停止使用手机、电脑等电子设备。蓝光会抑制褪黑素分泌，影响睡眠质量。可改为阅读纸质书或听舒缓音乐。", "sleep_tip", "睡前习惯", ["睡眠", "屏幕", "习惯", "蓝光"], season=None,
       method="睡前1小时关闭电子设备，改为阅读或听音乐", effect="避免蓝光抑制褪黑素，保障睡眠质量", duration="持续", best_time="睡前1小时"),
    _s("seed_sleep_tip_009", "轻度阅读", "睡前阅读纸质书（非刺激性内容）可放松大脑，减少焦虑。选择散文、诗歌等轻松读物，避免悬疑小说。每次15-20分钟为宜。", "sleep_tip", "睡前习惯", ["睡眠", "阅读", "放松", "习惯"], season=None,
       method="睡前阅读轻松纸质书15-20分钟", effect="放松大脑，减少焦虑，自然过渡到睡眠", duration="15-20分钟", best_time="睡前30分钟"),
    _s("seed_sleep_tip_010", "白噪音助眠", "白噪音如雨声、海浪声可屏蔽环境杂音，营造安静睡眠氛围。也可选择自然白噪音、轻柔音乐。音量控制在40分贝以下。", "sleep_tip", "睡前习惯", ["睡眠", "白噪音", "环境", "习惯"], season=None,
       method="播放雨声或海浪声等白噪音，音量40分贝以下", effect="屏蔽杂音，营造安静氛围，促进入睡", duration="持续至入睡"),

    # ----- 时辰养生 (5) -----
    _s("seed_sleep_tip_011", "子时觉", "子时（23-1点）为胆经当令，阴气最盛阳气初生。《黄帝内经》强调子时必须入睡，可养护胆气，促进胆汁分泌和代谢，为次日储备精力。", "sleep_tip", "时辰养生", ["睡眠", "子时", "胆经", "时辰"], season=None,
       method="22:30前上床，确保23点前入睡", effect="养护胆气，促进代谢，储备精力", duration="23:00-01:00", best_time="23:00"),
    _s("seed_sleep_tip_012", "午时觉", "午时（11-13点）为心经当令，阳气最盛阴气初生。午饭后小憩20-30分钟，可养心安神，恢复精力。不宜超过1小时，否则影响夜间睡眠。", "sleep_tip", "时辰养生", ["睡眠", "午时", "心经", "时辰"], season=None,
       method="午饭后小憩20-30分钟，不宜超过1小时", effect="养心安神，恢复精力，保护心脏", duration="20-30分钟", best_time="12:00-13:00"),
    _s("seed_sleep_tip_013", "卯时起", "卯时（5-7点）为大肠经当令。此时起床可顺应天时，促进排便，激活身体机能。《黄帝内经》提倡卯时起床，不可赖床。", "sleep_tip", "时辰养生", ["睡眠", "卯时", "大肠经", "时辰"], season=None,
       method="5-7点起床，先喝一杯温水，促进排便", effect="顺应天时，促进排便，激活身体", duration="即时", best_time="05:00-07:00"),
    _s("seed_sleep_tip_014", "酉时收", "酉时（17-19点）为肾经当令，阳气收敛阴气渐盛。此时应减少剧烈运动，收摄心神，准备进入休息状态。适合散步、轻松活动。", "sleep_tip", "时辰养生", ["睡眠", "酉时", "肾经", "时辰"], season=None,
       method="17-19点减少运动强度，散步放松，收摄心神", effect="顺应阳收，养肾藏精，为睡眠做准备", duration="持续", best_time="17:00-19:00"),
    _s("seed_sleep_tip_015", "亥时息", "亥时（21-23点）为三焦经当令，此时阴气渐盛。应在亥时入睡前完成洗漱等准备工作，让身心逐渐进入安静状态。亥时入睡为最佳。", "sleep_tip", "时辰养生", ["睡眠", "亥时", "三焦经", "时辰"], season=None,
       method="21点后开始放松，洗漱、泡脚、阅读", effect="让身心安静过渡，为子时深睡做准备", duration="持续", best_time="21:00-23:00"),

    # ----- 环境调整 (5) -----
    _s("seed_sleep_tip_016", "卧室温度调节", "卧室温度宜保持在18-22度之间。温度过高易烦躁不安，过低则难以入睡。被褥选择透气性好的材料，保持适度湿度40-60%。", "sleep_tip", "环境调整", ["睡眠", "温度", "环境", "舒适"], season=None,
       method="调节空调或暖气使室温保持18-22度，湿度40-60%", effect="创造适宜睡眠温度，提升睡眠质量", duration="持续"),
    _s("seed_sleep_tip_017", "遮光窗帘", "黑暗环境可促进褪黑素分泌，改善睡眠质量。卧室应使用遮光窗帘或眼罩，避免路灯、月光或晨光干扰。越暗的睡眠环境越有利于深度睡眠。", "sleep_tip", "环境调整", ["睡眠", "遮光", "环境", "黑暗"], season=None,
       method="安装遮光窗帘或使用眼罩，保持卧室全黑", effect="促进褪黑素分泌，保障深度睡眠", duration="持续"),
    _s("seed_sleep_tip_018", "枕头高度选择", "枕头高度以仰卧时一拳高、侧卧时一拳半高为宜。过高加重颈椎负担，过低则头部充血。颈椎病患者应选择符合颈椎生理弧度的枕头。", "sleep_tip", "环境调整", ["睡眠", "枕头", "颈椎", "舒适"], season=None,
       method="选择仰卧一拳高、侧卧一拳半高的枕头", effect="保护颈椎，减少颈部不适，改善睡眠", duration="持续"),
    _s("seed_sleep_tip_019", "床垫选择", "床垫不宜太软或太硬。软硬度适中、能贴合身体曲线的床垫最佳。侧卧者稍软，仰卧者稍硬。建议每8-10年更换一次床垫。", "sleep_tip", "环境调整", ["睡眠", "床垫", "舒适", "脊柱"], season=None,
       method="选择软硬适中的床垫，能贴合身体曲线", effect="保护脊柱，减少翻身，提升睡眠质量", duration="持续"),
    _s("seed_sleep_tip_020", "卧室布置", "卧室应保持整洁安静，只用于睡眠和亲密活动。不在卧室工作或娱乐。可放置薰衣草、绿萝等植物，使用淡雅柔和的装饰色调。", "sleep_tip", "环境调整", ["睡眠", "布置", "整洁", "安静"], season=None,
       method="保持卧室整洁，只用于睡眠，淡雅装饰", effect="建立睡眠联想，减少干扰，促进入睡", duration="持续"),

    # ========== E. 茶饮推荐 (30条) ==========
    # ----- 春季茶饮 (6) -----
    _s("seed_tea_001", "菊花茶", "菊花性微寒，疏风散热、平肝明目。春季肝气旺盛，菊花茶可清肝降火，缓解目赤肿痛。取菊花5g，沸水冲泡5分钟即饮。", "tea", "春季茶饮", ["春季", "清肝", "明目", "菊花"], season="spring",
       ingredients=["菊花5g", "冰糖适量"],
       steps=["沸水冲泡菊花5分钟", "加冰糖调味饮用"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_002", "茉莉花茶", "茉莉花性温味辛，理气开郁、辟秽和中。春季饮用可疏肝解郁、提神醒脑。取茉莉花3g，沸水冲泡5分钟。适合春季情绪低落者。", "tea", "春季茶饮", ["春季", "疏肝", "解郁", "茉莉花"], season="spring",
       ingredients=["茉莉花3g", "绿茶2g"],
       steps=["茉莉花与绿茶同放杯中", "沸水冲泡5分钟饮用"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_003", "玫瑰花茶", "玫瑰花性温味甘微苦，理气解郁、活血散瘀。春季饮用可调理气血、疏肝解郁。取玫瑰花5朵，沸水冲泡5分钟。女性尤宜。", "tea", "春季茶饮", ["春季", "理气", "活血", "玫瑰花"], season="spring",
       ingredients=["玫瑰花5朵", "蜂蜜适量"],
       steps=["玫瑰花沸水冲泡5分钟", "加蜂蜜调味饮用"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_004", "薄荷茶", "薄荷性凉味辛，疏散风热、清利头目。春季风热感冒或头痛时饮用尤佳。取鲜薄荷叶5片，沸水冲泡5分钟。可提神醒脑。", "tea", "春季茶饮", ["春季", "清热", "提神", "薄荷"], season="spring",
       ingredients=["鲜薄荷叶5片", "蜂蜜适量"],
       steps=["薄荷叶洗净入杯", "沸水冲泡5分钟", "加蜂蜜调味"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_005", "枸杞菊花茶", "枸杞滋补肝肾，菊花清肝明目，二味合用可养肝明目。春季用眼过度或眼干者饮用最佳。枸杞10g、菊花5g，沸水冲泡5分钟。", "tea", "春季茶饮", ["春季", "养肝", "明目", "枸杞菊花"], season="spring",
       ingredients=["枸杞10g", "菊花5g", "冰糖适量"],
       steps=["枸杞菊花同放杯中", "沸水冲泡5分钟", "加冰糖调味"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_006", "决明子茶", "决明子性微寒味甘苦，清肝明目、润肠通便。春季肝火旺或便秘者适宜。取炒决明子10g，沸水冲泡10分钟。脾胃虚寒者慎用。", "tea", "春季茶饮", ["春季", "清肝", "通便", "决明子"], season="spring",
       ingredients=["炒决明子10g", "蜂蜜适量"],
       steps=["决明子沸水冲泡10分钟", "加蜂蜜调味饮用"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),

    # ----- 夏季茶饮 (6) -----
    _s("seed_tea_007", "绿茶", "绿茶性凉味甘苦，清热解毒、消食化痰。夏季饮用绿茶可清热消暑，提神醒脑。含丰富茶多酚，抗氧化。取绿茶3g，80度水冲泡2分钟。", "tea", "夏季茶饮", ["夏季", "清热", "消暑", "绿茶"], season="summer",
       ingredients=["绿茶3g"],
       steps=["80度水冲泡绿茶2分钟", "可反复冲泡3次"],
       method="80度水冲泡2分钟", difficulty="简单", duration="2分钟"),
    _s("seed_tea_008", "荷叶茶", "荷叶性平味苦涩，清热解暑、升发清阳。夏季饮用可消暑利湿，降脂减肥。取干荷叶5g，沸水冲泡10分钟。适合夏季湿重体质。", "tea", "夏季茶饮", ["夏季", "消暑", "降脂", "荷叶"], season="summer",
       ingredients=["干荷叶5g", "山楂5g"],
       steps=["荷叶山楂洗净", "沸水冲泡10分钟饮用"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_009", "酸梅汤", "乌梅性平味酸，生津止渴。酸梅汤为传统夏季消暑名饮。乌梅30g、山楂20g、甘草5g、冰糖适量，煮水30分钟。冰镇后饮用更佳。", "tea", "夏季茶饮", ["夏季", "生津", "消暑", "酸梅汤"], season="summer",
       ingredients=["乌梅30g", "山楂20g", "甘草5g", "桂花少许", "冰糖适量"],
       steps=["全部材料加水煮30分钟", "过滤加桂花", "冰镇后饮用"],
       method="煮水30分钟", difficulty="简单", duration="30分钟"),
    _s("seed_tea_010", "金银花茶", "金银花性寒味甘，清热解毒、疏散风热。夏季饮用可预防感冒，清热消暑。取金银花10g，沸水冲泡5分钟。脾胃虚寒者少饮。", "tea", "夏季茶饮", ["夏季", "清热", "解毒", "金银花"], season="summer",
       ingredients=["金银花10g", "甘草3g", "冰糖适量"],
       steps=["金银花甘草沸水冲泡5分钟", "加冰糖调味"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_011", "薄荷绿茶", "薄荷清凉散热，绿茶清热消暑。二味合用为夏季最佳消暑茶饮。薄荷5片、绿茶3g，80度水冲泡3分钟。提神醒脑，消暑降温。", "tea", "夏季茶饮", ["夏季", "消暑", "提神", "薄荷绿茶"], season="summer",
       ingredients=["鲜薄荷叶5片", "绿茶3g", "蜂蜜适量"],
       steps=["薄荷绿茶同放杯中", "80度水冲泡3分钟", "加蜂蜜调味"],
       method="80度水冲泡3分钟", difficulty="简单", duration="3分钟"),
    _s("seed_tea_012", "竹叶茶", "竹叶性寒味甘淡，清热除烦、生津利尿。夏季心烦口渴时饮用尤佳。取竹叶5g，沸水冲泡5分钟。可加冰糖调味，冰镇后饮用。", "tea", "夏季茶饮", ["夏季", "清热", "除烦", "竹叶"], season="summer",
       ingredients=["竹叶5g", "冰糖适量"],
       steps=["竹叶沸水冲泡5分钟", "加冰糖调味饮用"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),

    # ----- 秋季茶饮 (6) -----
    _s("seed_tea_013", "银耳莲子茶", "银耳滋阴润肺，莲子养心安神。秋季燥邪伤肺，此茶可滋阴润燥、养心安神。银耳10g泡发、莲子20g，炖煮30分钟，加冰糖饮用。", "tea", "秋季茶饮", ["秋季", "滋阴", "润燥", "银耳莲子"], season="autumn",
       ingredients=["银耳10g", "莲子20g", "枸杞10g", "冰糖适量"],
       steps=["银耳泡发撕碎", "加莲子枸杞炖煮30分钟", "加冰糖调味"],
       method="炖煮30分钟", difficulty="简单", duration="30分钟"),
    _s("seed_tea_014", "百合雪梨茶", "百合润肺止咳，雪梨清热化痰。秋季干燥咳嗽者饮用最佳。百合10g、雪梨1个切块，加水煮20分钟，加蜂蜜调味。润肺止咳佳饮。", "tea", "秋季茶饮", ["秋季", "润肺", "化痰", "百合雪梨"], season="autumn",
       ingredients=["百合10g", "雪梨1个", "蜂蜜适量"],
       steps=["百合泡发，雪梨切块", "加水煮20分钟", "加蜂蜜调味"],
       method="煮水20分钟", difficulty="简单", duration="20分钟"),
    _s("seed_tea_015", "桂花茶", "桂花性温味辛，温肺化饮、散寒止痛。秋季饮用桂花茶可温中散寒、提神醒脑。取桂花3g，沸水冲泡5分钟。适合秋季胃寒者。", "tea", "秋季茶饮", ["秋季", "温中", "散寒", "桂花"], season="autumn",
       ingredients=["干桂花3g", "红茶2g", "蜂蜜适量"],
       steps=["桂花红茶同放杯中", "沸水冲泡5分钟", "加蜂蜜调味"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_016", "蜂蜜柚子茶", "蜂蜜润燥，柚子理气化痰。秋季饮用可润肺止咳，理气消食。柚子半个取肉，加蜂蜜拌匀，温水冲饮。适合秋燥咳嗽者。", "tea", "秋季茶饮", ["秋季", "润燥", "化痰", "蜂蜜柚子"], season="autumn",
       ingredients=["柚子半个", "蜂蜜3勺", "温水适量"],
       steps=["柚子取肉撕碎", "加蜂蜜拌匀", "温水冲泡饮用"],
       method="温水冲泡", difficulty="简单", duration="5分钟"),
    _s("seed_tea_017", "杏仁茶", "甜杏仁性微温味甘，润肺止咳。秋季干燥，杏仁茶可润肺生津。甜杏仁20g研磨，加水煮10分钟，加冰糖调味。注意用甜杏仁非苦杏仁。", "tea", "秋季茶饮", ["秋季", "润肺", "止咳", "杏仁"], season="autumn",
       ingredients=["甜杏仁20g", "牛奶200ml", "冰糖适量"],
       steps=["甜杏仁研磨成粉", "加牛奶煮10分钟", "加冰糖调味"],
       method="研磨煮制10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_018", "罗汉果茶", "罗汉果性凉味甘，清热润肺、利咽开音。秋季咽喉干燥者饮用最佳。罗汉果半个，掰碎用沸水冲泡10分钟。天然甜味，无需加糖。", "tea", "秋季茶饮", ["秋季", "润肺", "利咽", "罗汉果"], season="autumn",
       ingredients=["罗汉果半个"],
       steps=["罗汉果掰碎", "沸水冲泡10分钟", "可反复冲泡3次"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),

    # ----- 冬季茶饮 (6) -----
    _s("seed_tea_019", "红枣桂圆茶", "红枣补气养血，桂圆温补心脾。冬季饮用可补血安神，温暖全身。红枣10颗、桂圆10g，沸水冲泡10分钟或煮水。适合冬季手脚冰凉者。", "tea", "冬季茶饮", ["冬季", "补血", "安神", "红枣桂圆"], season="winter",
       ingredients=["红枣10颗", "桂圆10g", "红糖适量"],
       steps=["红枣桂圆洗净", "加水煮10分钟", "加红糖调味"],
       method="煮水10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_020", "姜枣茶", "生姜温中散寒，红枣补中益气。冬季饮用姜枣茶可驱寒暖身，预防感冒。生姜3片、红枣5颗，加水煮10分钟。风寒感冒初期尤宜。", "tea", "冬季茶饮", ["冬季", "驱寒", "暖身", "姜枣"], season="winter",
       ingredients=["生姜3片", "红枣5颗", "红糖适量"],
       steps=["生姜红枣洗净", "加水煮10分钟", "加红糖调味"],
       method="煮水10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_021", "黑芝麻茶", "黑芝麻性平味甘，补肝肾、润五脏。冬季饮用可滋养肝肾，润肠通便。黑芝麻20g炒香研磨，加温水冲饮。也可加蜂蜜调味。", "tea", "冬季茶饮", ["冬季", "补肾", "养发", "黑芝麻"], season="winter",
       ingredients=["黑芝麻20g", "蜂蜜适量", "温水适量"],
       steps=["黑芝麻炒香研磨", "温水冲泡", "加蜂蜜调味饮用"],
       method="炒香研磨后温水冲饮", difficulty="简单", duration="5分钟"),
    _s("seed_tea_022", "当归生姜羊肉汤", "当归补血活血，生姜温中散寒，羊肉温补气血。冬季经典温补方，可补血散寒，暖宫调经。当归15g、生姜30g、羊肉500g，炖煮1.5小时。", "tea", "冬季茶饮", ["冬季", "温补", "补血", "当归生姜"], season="winter",
       ingredients=["当归15g", "生姜30g", "羊肉500g", "盐适量"],
       steps=["羊肉焯水切块", "加当归生姜炖煮1.5小时", "加盐调味"],
       method="炖煮1.5小时", difficulty="中等", duration="90分钟"),
    _s("seed_tea_023", "枸杞红枣茶", "枸杞滋补肝肾，红枣补中益气。冬季饮用可温补肝肾，益气养血。枸杞15g、红枣8颗，沸水冲泡10分钟。简单易行的冬季养生茶饮。", "tea", "冬季茶饮", ["冬季", "滋补", "养血", "枸杞红枣"], season="winter",
       ingredients=["枸杞15g", "红枣8颗", "冰糖适量"],
       steps=["枸杞红枣洗净", "沸水冲泡10分钟", "加冰糖调味"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_024", "核桃露", "核桃性温味甘，补肾固精、温肺定喘。冬季饮用核桃露可补肾健脑，温肺润肠。核桃仁50g研磨，加牛奶200ml煮10分钟，加蜂蜜调味。", "tea", "冬季茶饮", ["冬季", "补肾", "健脑", "核桃"], season="winter",
       ingredients=["核桃仁50g", "牛奶200ml", "蜂蜜适量"],
       steps=["核桃仁研磨", "加牛奶煮10分钟", "加蜂蜜调味"],
       method="研磨煮制10分钟", difficulty="简单", duration="10分钟"),

    # ----- 四季茶饮 (6) -----
    _s("seed_tea_025", "枸杞茶", "枸杞子性平味甘，滋补肝肾、益精明目。四季皆宜，长期饮用可增强免疫、抗衰老。枸杞10-15g，沸水冲泡5分钟。可反复冲泡。", "tea", "四季茶饮", ["四季", "滋补", "养肝", "枸杞"], season=None,
       ingredients=["枸杞15g"],
       steps=["枸杞洗净入杯", "沸水冲泡5分钟", "可反复冲泡至无味"],
       method="沸水冲泡5分钟", difficulty="简单", duration="5分钟"),
    _s("seed_tea_026", "陈皮茶", "陈皮性温味辛苦，理气健脾、燥湿化痰。四季皆宜，尤适合消化不良、痰多者。陈皮3-5g，沸水冲泡10分钟。可加蜂蜜调味。", "tea", "四季茶饮", ["四季", "理气", "健脾", "陈皮"], season=None,
       ingredients=["陈皮5g", "蜂蜜适量"],
       steps=["陈皮洗净入杯", "沸水冲泡10分钟", "加蜂蜜调味"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_027", "蜂蜜水", "蜂蜜性平味甘，补中润燥、解毒止痛。四季皆宜，早晨空腹饮用可润肠通便。蜂蜜1-2勺，温水冲泡。不可用沸水，会破坏营养。", "tea", "四季茶饮", ["四季", "润燥", "通便", "蜂蜜"], season=None,
       ingredients=["蜂蜜2勺", "温水300ml"],
       steps=["温水冲泡蜂蜜", "搅拌均匀饮用"],
       method="温水冲泡（不可用沸水）", difficulty="简单", duration="2分钟"),
    _s("seed_tea_028", "玫瑰花红枣茶", "玫瑰花理气解郁，红枣补中益气。四季皆宜，女性尤宜。玫瑰花5朵、红枣3颗，沸水冲泡10分钟。可加蜂蜜调味，调经养颜。", "tea", "四季茶饮", ["四季", "理气", "养血", "玫瑰花红枣"], season=None,
       ingredients=["玫瑰花5朵", "红枣3颗", "蜂蜜适量"],
       steps=["玫瑰花红枣洗净", "沸水冲泡10分钟", "加蜂蜜调味"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_029", "山楂茶", "山楂性微温味酸甘，消食化积、活血散瘀。饭后饮用可助消化、降血脂。山楂5g，沸水冲泡10分钟。胃酸过多者不宜空腹饮用。", "tea", "四季茶饮", ["四季", "消食", "降脂", "山楂"], season=None,
       ingredients=["山楂5g", "冰糖适量"],
       steps=["山楂洗净入杯", "沸水冲泡10分钟", "加冰糖调味"],
       method="沸水冲泡10分钟", difficulty="简单", duration="10分钟"),
    _s("seed_tea_030", "薏米红豆茶", "薏米性凉味甘淡，健脾渗湿；红豆性平味甘酸，利水消肿。四季皆宜，尤适合湿气重、水肿体质。薏米20g、红豆20g，煮水30分钟。", "tea", "四季茶饮", ["四季", "祛湿", "消肿", "薏米红豆"], season=None,
       ingredients=["薏米20g", "红豆20g", "冰糖适量"],
       steps=["薏米红豆提前浸泡", "加水煮30分钟", "加冰糖调味"],
       method="煮水30分钟", difficulty="简单", duration="30分钟"),
]

# ==================== 英文种子数据 ====================

SEED_CONTENTS_EN = [
    # ========== Food Therapy (30 entries) ==========
    # ----- Spring Diet Therapy (10) -----
    _se("seed_en_food_therapy_001", "Spinach Liver-Nourishing Soup",
        "Spinach is cool and sweet, entering the liver meridian. It nourishes blood, moistens dryness, and calms the liver. Ancient texts praise its ability to unblock vessels and improve vision. A perfect spring dish to support liver qi and brighten the eyes.",
        "food_therapy", "Spring Diet Therapy", ["spring", "liver", "vision", "spinach"], season="spring",
        ingredients=["300g spinach", "100g pork liver", "3 slices ginger", "10g goji berries", "salt to taste"],
        steps=["Blanch spinach and cut into sections", "Slice pork liver and blanch", "Bring water to boil with ginger", "Add pork liver, cook 5 minutes", "Add spinach and goji berries, season to taste"], difficulty="Easy", duration="20 minutes"),
    _se("seed_en_food_therapy_002", "Garlic Chives & Egg Stir-Fry",
        "Garlic chives are warming and nourish the kidneys. Known as the 'herb of rising yang,' they warm the middle and tonify deficiency. In spring, eating chives helps yang energy emerge, warms the spleen and stomach, and boosts vitality.",
        "food_therapy", "Spring Diet Therapy", ["spring", "warming", "kidney", "chives"], season="spring",
        ingredients=["250g garlic chives", "3 eggs", "salt to taste", "cooking oil"],
        steps=["Wash and cut chives into sections", "Beat eggs with a pinch of salt", "Stir-fry eggs and set aside", "Quick stir-fry chives", "Return eggs and toss together"], difficulty="Easy", duration="10 minutes"),
    _se("seed_en_food_therapy_003", "Braised Spring Bamboo Shoots",
        "Spring bamboo shoots are sweet and cooling, clearing heat and resolving phlegm while harmonizing the stomach. They promote the free flow of qi and blood. A seasonal delicacy that clears internal heat and aids digestion.",
        "food_therapy", "Spring Diet Therapy", ["spring", "cooling", "phlegm", "bamboo shoots"], season="spring",
        ingredients=["500g spring bamboo shoots", "2 tbsp light soy sauce", "1 tbsp dark soy sauce", "1 tbsp sugar", "cooking oil"],
        steps=["Peel and cut bamboo shoots, blanch", "Stir-fry in hot oil", "Add soy sauces and sugar", "Add a splash of water, braise 10 min", "Reduce sauce over high heat"], difficulty="Easy", duration="25 minutes"),
    _se("seed_en_food_therapy_004", "Shepherd's Purse & Tofu Soup",
        "Shepherd's purse is balancing and sweet, harmonizing the spleen, promoting urination, and brightening the eyes. Paired with tofu in spring, this soup gently clears damp-heat and is a nourishing wellness choice.",
        "food_therapy", "Spring Diet Therapy", ["spring", "diuretic", "vision", "shepherd's purse"], season="spring",
        ingredients=["200g shepherd's purse", "1 block silken tofu", "1 egg", "cornstarch", "salt to taste"],
        steps=["Blanch and chop shepherd's purse", "Dice tofu into small cubes", "Bring water to boil, add tofu", "Add greens, cook 2 minutes", "Drizzle in egg, thicken with starch, season"], difficulty="Easy", duration="15 minutes"),
    _se("seed_en_food_therapy_005", "Toona sinensis Tofu Salad",
        "Chinese toon is cooling with a slightly bitter taste. It clears heat, detoxifies, and harmonizes the stomach. In spring, the tender buds have a rich aroma. Combined with tofu, this dish is refreshing and helps clear damp-heat.",
        "food_therapy", "Spring Diet Therapy", ["spring", "cooling", "detox", "toon"], season="spring",
        ingredients=["100g toon sprouts", "1 block silken tofu", "sesame oil", "salt", "light soy sauce"],
        steps=["Blanch toon sprouts and chop finely", "Cube tofu and arrange on plate", "Top with chopped toon", "Drizzle with sesame oil and soy sauce"], difficulty="Easy", duration="10 minutes"),
    _se("seed_en_food_therapy_006", "Stir-Fried Bean Sprouts",
        "Bean sprouts are cooling and sweet, clearing heat and toxins while strengthening the spleen. Spring sprouts help the liver discharge stagnant energy, clear internal heat, and provide excellent nutrition.",
        "food_therapy", "Spring Diet Therapy", ["spring", "cooling", "detox", "bean sprouts"], season="spring",
        ingredients=["300g mung bean sprouts", "chopped scallions", "a splash of vinegar", "salt", "cooking oil"],
        steps=["Wash and drain sprouts thoroughly", "Quick stir-fry over high heat", "Add scallions and toss", "Finish with a splash of vinegar"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_007", "Strawberry Lung-Nourishing Smoothie",
        "Strawberries are cooling and slightly sour. They moisten the lungs, generate fluids, and harmonize the stomach. In spring, strawberries are hydrating, thirst-quenching, and rich in vitamin C for radiant skin.",
        "food_therapy", "Spring Diet Therapy", ["spring", "lung", "hydration", "strawberry"], season="spring",
        ingredients=["200g strawberries", "honey to taste", "200ml yogurt"],
        steps=["Wash and hull strawberries", "Blend with yogurt and honey", "Serve chilled for best results"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_008", "Cherry Blood-Nourishing Elixir",
        "Cherries are warming and sweet. They tonify the middle jiao, nourish qi, and dispel wind-dampness. Spring cherries nourish blood, relieve fatigue, and restore a healthy rosy complexion.",
        "food_therapy", "Spring Diet Therapy", ["spring", "blood", "beauty", "cherry"], season="spring",
        ingredients=["200g cherries", "rock sugar", "a pinch of dried osmanthus"],
        steps=["Pit the cherries", "Simmer with water and sugar until soft", "Cook 10 minutes over low heat", "Sprinkle with osmanthus flowers"], difficulty="Easy", duration="15 minutes"),
    _se("seed_en_food_therapy_009", "Honey Pomelo Tea",
        "Honey is balancing and sweet. It tonifies the middle, moistens dryness, relieves pain, and detoxifies. A spring staple for internal moisture and glowing skin. Five therapeutic actions are recorded in ancient herbals.",
        "food_therapy", "Spring Diet Therapy", ["spring", "moistening", "beauty", "honey"], season="spring",
        ingredients=["3 tbsp honey", "half a pomelo", "warm water"],
        steps=["Remove pomelo flesh and tear into pieces", "Mix with honey", "Dilute with warm water to drink"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_010", "Yam Stomach-Nourishing Congee",
        "Chinese yam is balancing and sweet. It tonifies the spleen, nourishes the stomach, generates fluids, and benefits the lungs. A spring congee that strengthens spleen qi and aids digestion — perfect for all ages.",
        "food_therapy", "Spring Diet Therapy", ["spring", "spleen", "stomach", "yam"], season="spring",
        ingredients=["200g Chinese yam", "100g rice", "5 red dates", "rock sugar"],
        steps=["Peel and dice the yam", "Wash rice and red dates", "Cook together until thick and creamy", "Add rock sugar to taste"], difficulty="Easy", duration="40 minutes"),

    # ----- Summer Diet Therapy (10) -----
    _se("seed_en_food_therapy_011", "Watermelon Cooling Drink",
        "Watermelon is cold and sweet, the ultimate summer cooler. It clears heat, relieves irritability, and promotes urination. Known as 'nature's white tiger decoction,' watermelon reduces internal fire and swelling in the summer heat.",
        "food_therapy", "Summer Diet Therapy", ["summer", "cooling", "hydration", "watermelon"], season="summer",
        ingredients=["500g watermelon flesh", "a little rock sugar", "fresh mint leaves"],
        steps=["Remove seeds and cube the watermelon", "Blend with a bit of sugar", "Serve with a mint leaf garnish"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_012", "Smashed Cucumber Salad",
        "Cucumber is cooling and sweet. It clears heat, promotes urination, and reduces swelling. A summer essential — crisp, refreshing, and appetite-stimulating. Perfect for beating the heat.",
        "food_therapy", "Summer Diet Therapy", ["summer", "cooling", "diuretic", "cucumber"], season="summer",
        ingredients=["2 cucumbers", "minced garlic", "black vinegar", "chili oil", "salt"],
        steps=["Smash cucumbers with the side of a knife, cut into pieces", "Add garlic, vinegar, and chili oil", "Toss well and serve immediately"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_013", "Bitter Melon Blood Sugar Soup",
        "Bitter melon is cold and bitter. It clears summer heat, brightens the eyes, and detoxifies. Summer bitter melon helps lower blood sugar and lipids. In TCM, bitter flavors nourish the heart. An acquired taste with powerful benefits.",
        "food_therapy", "Summer Diet Therapy", ["summer", "cooling", "blood sugar", "bitter melon"], season="summer",
        ingredients=["1 bitter melon", "300g pork ribs", "30g soybeans", "3 slices ginger", "salt"],
        steps=["Seed and slice bitter melon", "Blanch ribs", "Soak soybeans ahead of time", "Simmer all ingredients for 1.5 hours"], difficulty="Medium", duration="90 minutes"),
    _se("seed_en_food_therapy_014", "Mung Bean Detox Soup",
        "Mung beans are cooling and sweet. They clear heat, detoxify, and promote urination. Called 'the grain that benefits the world' in ancient texts. The number one summer soup for clearing heat and quenching thirst.",
        "food_therapy", "Summer Diet Therapy", ["summer", "cooling", "detox", "mung beans"], season="summer",
        ingredients=["100g mung beans", "rock sugar", "a few mint leaves"],
        steps=["Wash and soak mung beans", "Bring to boil, then simmer", "Cook until beans split open", "Add sugar and mint to taste"], difficulty="Easy", duration="40 minutes"),
    _se("seed_en_food_therapy_015", "Barley Damp-Draining Congee",
        "Coix seed (Job's tears) is cooling and bland. It strengthens the spleen, drains dampness, and relieves joint pain. During the humid transition from summer to autumn, this congee helps dispel dampness and reduce water retention.",
        "food_therapy", "Summer Diet Therapy", ["summer", "dampness", "spleen", "barley"], season="summer",
        ingredients=["100g coix seed (Job's tears)", "50g adzuki beans", "rock sugar"],
        steps=["Soak coix seed and adzuki beans", "Cook together as a congee", "Add rock sugar to taste"], difficulty="Easy", duration="50 minutes"),
    _se("seed_en_food_therapy_016", "Winter Melon Diuretic Soup",
        "Winter melon is cooling and bland. It clears heat, promotes urination, and generates fluids. A classic summer soup that reduces swelling, dispels heat, and gently nourishes the body.",
        "food_therapy", "Summer Diet Therapy", ["summer", "diuretic", "cooling", "winter melon"], season="summer",
        ingredients=["500g winter melon", "200g pork ribs", "3 slices ginger", "salt"],
        steps=["Peel and cube winter melon", "Blanch ribs", "Simmer together for 1 hour", "Season to taste"], difficulty="Easy", duration="60 minutes"),
    _se("seed_en_food_therapy_017", "Tomato Egg Drop Soup",
        "Tomatoes are slightly cooling and sour-sweet. They generate fluids, quench thirst, and harmonize the stomach. This sweet and tangy summer soup stimulates the appetite and provides a rich dose of lycopene antioxidants.",
        "food_therapy", "Summer Diet Therapy", ["summer", "appetizing", "antioxidant", "tomato"], season="summer",
        ingredients=["2 tomatoes", "2 eggs", "chopped scallions", "salt", "sesame oil"],
        steps=["Stir-fry tomatoes until they release their juices", "Add water and bring to boil", "Drizzle in beaten egg", "Garnish with scallions and sesame oil"], difficulty="Easy", duration="15 minutes"),
    _se("seed_en_food_therapy_018", "Mint Cooling Refresher",
        "Mint is cooling and pungent. It disperses wind-heat, clears the head, and brightens the eyes. A summer mint tea cools the body, dispels heat, and refreshes the mind. One of nature's best pick-me-ups.",
        "food_therapy", "Summer Diet Therapy", ["summer", "cooling", "refreshing", "mint"], season="summer",
        ingredients=["10 fresh mint leaves", "3 lemon slices", "honey", "ice cubes"],
        steps=["Wash mint leaves", "Muddle with lemon and honey", "Top with ice water and stir"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_019", "Honeysuckle Detox Tea",
        "Honeysuckle is cold and sweet. It clears heat, detoxifies, and disperses wind-heat. A summer staple for preventing summer colds. Its anti-inflammatory and antibacterial properties make it a powerful wellness brew.",
        "food_therapy", "Summer Diet Therapy", ["summer", "cooling", "detox", "honeysuckle"], season="summer",
        ingredients=["10g honeysuckle", "5g chrysanthemum", "3g licorice root", "rock sugar"],
        steps=["Rinse honeysuckle, chrysanthemum, and licorice", "Steep in boiling water for 5 minutes", "Add sugar to taste"], difficulty="Easy", duration="5 minutes"),
    _se("seed_en_food_therapy_020", "Sour Plum Nourishing Drink",
        "Dark plum (Wumei) is balancing and sour. It generates fluids, quenches thirst, and astringes the intestines. The traditional summer sour plum drink is beloved across Asia — tangy, refreshing, and deeply restorative.",
        "food_therapy", "Summer Diet Therapy", ["summer", "hydration", "cooling", "sour plum"], season="summer",
        ingredients=["30g dark plums", "20g hawthorn berries", "5g licorice root", "dried osmanthus", "rock sugar"],
        steps=["Simmer plums, hawthorn, and licorice 30 minutes", "Strain and add sugar and osmanthus", "Serve chilled for the best experience"], difficulty="Easy", duration="40 minutes"),

    # ----- Autumn & Winter Diet Therapy (10) -----
    _se("seed_en_food_therapy_021", "Snow Pear Lung-Moistening Soup",
        "Pears are cooling and sweet. They moisten the lungs, clear heat, and resolve phlegm. In autumn, when dryness injures the lungs, snow pear is the first choice for soothing coughs and hydrating the respiratory system.",
        "food_therapy", "Autumn Diet Therapy", ["autumn", "lung", "phlegm", "pear"], season="autumn",
        ingredients=["1 snow pear", "20g rock sugar", "5g fritillaria bulb (Chuanbei)", "10g goji berries"],
        steps=["Core and cube the pear", "Add sugar, fritillaria, and goji berries", "Steam for 30 minutes"], difficulty="Easy", duration="35 minutes"),
    _se("seed_en_food_therapy_022", "Tremella & Pear Sweet Soup",
        "White tremella (silver ear mushroom) is balancing and nourishes yin, moistens the lungs, and generates fluids. Paired with snow pear, this autumn dessert deeply hydrates dry tissues and promotes radiant skin.",
        "food_therapy", "Autumn Diet Therapy", ["autumn", "yin", "lung", "tremella"], season="autumn",
        ingredients=["1 tremella mushroom", "1 snow pear", "5 red dates", "rock sugar"],
        steps=["Soak and tear tremella into small pieces", "Cube the pear", "Simmer gently for 1 hour", "Add sugar to taste"], difficulty="Medium", duration="60 minutes"),
    _se("seed_en_food_therapy_023", "Lotus Root Stomach Soup",
        "Lotus root is cooling and sweet. It clears heat, generates fluids, and cools the blood. In autumn, lotus root is at its best — clearing dry heat, harmonizing the stomach, and nourishing blood and tissue.",
        "food_therapy", "Autumn Diet Therapy", ["autumn", "stomach", "moistening", "lotus root"], season="autumn",
        ingredients=["500g lotus root", "300g pork ribs", "50g peanuts", "5 red dates", "salt"],
        steps=["Peel and section lotus root", "Blanch ribs", "Simmer all ingredients 1.5 hours", "Season and serve"], difficulty="Medium", duration="90 minutes"),
    _se("seed_en_food_therapy_024", "Chestnut Kidney Soup",
        "Chestnuts are warming and sweet. They nourish the stomach, strengthen the spleen, and tonify the kidneys. Autumn's sweet chestnuts, simmered with chicken, make a deeply warming and restorative dish.",
        "food_therapy", "Autumn Diet Therapy", ["autumn", "kidney", "spleen", "chestnut"], season="autumn",
        ingredients=["200g chestnuts", "500g chicken", "5 slices ginger", "5 red dates", "salt"],
        steps=["Blanch chicken", "Add chestnuts, ginger, and dates", "Simmer for 1 hour", "Season and serve"], difficulty="Medium", duration="70 minutes"),
    _se("seed_en_food_therapy_025", "Angelica & Lamb Soup",
        "Lamb is warming and tonifies qi. Angelica (Dong Quai) nourishes blood and invigorates circulation. Together they form the quintessential winter nourishing soup — warming the body, dispelling cold, and building vitality.",
        "food_therapy", "Winter Diet Therapy", ["winter", "warming", "blood", "lamb"], season="winter",
        ingredients=["500g lamb", "15g angelica root", "5 slices ginger", "10g goji berries", "salt"],
        steps=["Blanch lamb and cut into chunks", "Simmer with angelica and ginger for 1.5 hours", "Add goji berries, season to taste"], difficulty="Medium", duration="100 minutes"),
    _se("seed_en_food_therapy_026", "Ginseng Vitality Soup",
        "Ginseng slightly warm and sweet. It greatly tonifies original qi, restores collapsed yang, and strengthens all five organs. The premier winter tonic for boosting immunity and energy. Avoid if you have excess heat conditions.",
        "food_therapy", "Winter Diet Therapy", ["winter", "qi", "immunity", "ginseng"], season="winter",
        ingredients=["10g ginseng slices", "1 chicken leg", "5 red dates", "3 slices ginger", "salt"],
        steps=["Blanch chicken leg", "Add ginseng, dates, and ginger", "Simmer gently for 1 hour", "Season and serve"], difficulty="Medium", duration="70 minutes"),
    _se("seed_en_food_therapy_027", "Walnut Brain Tonic Congee",
        "Walnuts are warming and sweet. They tonify the kidneys, secure essence, warm the lungs, and calm wheezing. In winter, walnuts support brain health, strengthen memory, and promote glossy hair.",
        "food_therapy", "Winter Diet Therapy", ["winter", "brain", "kidney", "walnut"], season="winter",
        ingredients=["50g walnut kernels", "100g rice", "5 red dates", "rock sugar"],
        steps=["Crush walnut kernels", "Cook rice and dates into congee", "Add walnuts and cook together", "Sweeten with rock sugar"], difficulty="Easy", duration="35 minutes"),
    _se("seed_en_food_therapy_028", "Black Sesame Kidney Congee",
        "Black sesame is balancing and sweet. It tonifies the liver and kidneys, nourishes the five organs, and moistens the intestines. A winter staple for dark lustrous hair, strong bones, and digestive regularity.",
        "food_therapy", "Winter Diet Therapy", ["winter", "kidney", "hair", "black sesame"], season="winter",
        ingredients=["30g black sesame seeds", "100g rice", "20g walnuts", "rock sugar"],
        steps=["Toast and grind black sesame", "Cook rice into congee", "Add sesame and walnuts", "Sweeten to taste"], difficulty="Easy", duration="35 minutes"),
    _se("seed_en_food_therapy_029", "Astragalus Qi-Boosting Soup",
        "Astragalus (Huangqi) is slightly warm and sweet. It tonifies qi, stabilizes the exterior, and promotes urination. In winter, astragalus strengthens defensive qi, boosts immunity, and helps prevent colds.",
        "food_therapy", "Winter Diet Therapy", ["winter", "qi", "immunity", "astragalus"], season="winter",
        ingredients=["30g astragalus root", "10 red dates", "15g goji berries", "half a silkie chicken", "salt"],
        steps=["Blanch silkie chicken", "Simmer with astragalus and dates for 2 hours", "Add goji berries, season to taste"], difficulty="Medium", duration="120 minutes"),
    _se("seed_en_food_therapy_030", "Ginger & Brown Sugar Warming Elixir",
        "Fresh ginger is warming and pungent. It releases the exterior, dispels cold, warms the middle, and stops vomiting. Winter ginger tea warms the body from within, prevents wind-cold, and soothes the stomach.",
        "food_therapy", "Winter Diet Therapy", ["winter", "warming", "stomach", "ginger"], season="winter",
        ingredients=["50g fresh ginger", "30g brown sugar", "3 sections of scallion white"],
        steps=["Slice the ginger", "Simmer with brown sugar and scallion", "Drink warm before bed or at first sign of cold"], difficulty="Easy", duration="15 minutes"),

    # ========== Acupressure (20 entries) ==========
    # ----- Head Acupoints (5) -----
    _se("seed_en_acupressure_001", "Baihui DU20 — Crown of the Head",
        "Baihui (DU20) is located at the crown of the head, at the intersection of the midline and a line connecting the ears. Known as the 'Meeting of All Yang,' this point lifts yang energy, awakens the brain, and clears the mind. Press for 3-5 minutes daily to relieve headaches, dizziness, and mental fog.",
        "acupressure", "Head Acupoints", ["head", "yang", "pain relief", "Baihui"], season=None,
        location="Crown of head, midpoint of the line connecting the apexes of both ears", method="Thumb press or moxibustion", effect="Lifts yang, awakens the brain, relieves headache and dizziness", duration="3-5 minutes"),
    _se("seed_en_acupressure_002", "Taiyang EX-HN5 — Temples",
        "Taiyang is located in the depression between the lateral end of the eyebrow and the outer canthus of the eye. An extra point that dispels wind, clears heat, and relieves pain. Gentle circular massage for 2-3 minutes eases tension headaches and eye strain.",
        "acupressure", "Head Acupoints", ["head", "pain relief", "vision", "Taiyang"], season=None,
        location="Depression at the temporal region, 1 finger-width posterior to the midpoint between the lateral eyebrow and outer eye corner", method="Bilateral middle-finger press in gentle circles", effect="Disperses wind-heat, relieves migraines and eye fatigue", duration="2-3 minutes"),
    _se("seed_en_acupressure_003", "Fengchi GB20 — Wind Pool",
        "Fengchi (GB20) sits at the base of the skull, in the hollow between the upper trapezius and sternocleidomastoid muscles. A key point for dispelling wind-cold, relieving neck stiffness, and clearing the head. Essential for office workers.",
        "acupressure", "Head Acupoints", ["head", "wind", "cervical", "Fengchi"], season=None,
        location="Base of the skull, bilateral depressions in the upper neck", method="Press with both thumbs, gradually increasing pressure", effect="Disperses wind, relieves neck pain, treats colds and headaches", duration="3-5 minutes"),
    _se("seed_en_acupressure_004", "Yintang EX-HN3 — Third Eye",
        "Yintang lies between the eyebrows at the midpoint. An extra point that clears the head, brightens the eyes, opens the nasal passages, and calms the spirit. Pressing here for 2-3 minutes eases frontal headaches and promotes calm.",
        "acupressure", "Head Acupoints", ["head", "calming", "nasal", "Yintang"], season=None,
        location="Midpoint between the inner ends of the two eyebrows", method="Middle or thumb finger press, gently stroke up and down", effect="Clears the head, opens the nose, relieves headache and insomnia", duration="2-3 minutes"),
    _se("seed_en_acupressure_005", "Yingxiang LI20 — Welcome Fragrance",
        "Yingxiang (LI20) is located in the nasolabial groove, level with the midpoint of the ala nasi. A Large Intestine point that opens the nasal passages and scatters wind-heat. Pressing here relieves nasal congestion and is excellent for allergies.",
        "acupressure", "Head Acupoints", ["head", "nasal", "allergy", "Yingxiang"], season=None,
        location="In the nasolabial groove, at the level of the midpoint of the nasal ala", method="Bilateral index finger press, upward strokes", effect="Opens nasal passages, scatters wind-heat, treats rhinitis and congestion", duration="2-3 minutes"),

    # ----- Upper Limb Acupoints (5) -----
    _se("seed_en_acupressure_006", "Hegu LI4 — Joining Valley",
        "Hegu (LI4) is in the web between the thumb and index finger. The yuan (source) point of the Large Intestine meridian and one of the Four Command Points — 'Face and mouth, select Hegu.' It relieves pain, calms the mind, and treats head and face disorders. Contraindicated in pregnancy.",
        "acupressure", "Upper Limb Acupoints", ["upper limb", "pain relief", "meridian", "Hegu"], season=None,
        location="On the dorsum of the hand, between the 1st and 2nd metacarpal bones, in the fleshy part of the thumb web", method="Press opposite Hegu with thumb, gradually increase pressure", effect="Relieves pain, regulates qi, treats headaches, toothaches, and colds", duration="3-5 minutes"),
    _se("seed_en_acupressure_007", "Neiguan PC6 — Inner Gate",
        "Neiguan (PC6) is on the palmar surface of the forearm, 2 cun above the wrist crease, between the two tendons. The luo-connecting point of the Pericardium meridian. It calms the heart, settles the stomach, and relieves nausea — nature's anti-nausea patch.",
        "acupressure", "Upper Limb Acupoints", ["upper limb", "calming", "anti-nausea", "Neiguan"], season=None,
        location="Palmar forearm, 2 cun above the transverse wrist crease, between the tendons of palmaris longus and flexor carpi radialis", method="Sustained thumb pressure with gentle massage", effect="Calms the heart, harmonizes the stomach, relieves palpitations and motion sickness", duration="3-5 minutes"),
    _se("seed_en_acupressure_008", "Quchi LI11 — Crooked Pool",
        "Quchi (LI11) is at the lateral end of the elbow crease. The he (sea) point of the Large Intestine meridian. It dispels wind-heat, harmonizes qi and blood, and is a key point for lowering blood pressure and treating skin conditions.",
        "acupressure", "Upper Limb Acupoints", ["upper limb", "cooling", "blood pressure", "Quchi"], season=None,
        location="At the lateral end of the transverse cubital crease, midpoint between LU5 and the lateral epicondyle", method="Thumb press combined with gentle elbow flexion", effect="Disperses wind-heat, lowers blood pressure, treats skin disorders", duration="3-5 minutes"),
    _se("seed_en_acupressure_009", "Shenmen HT7 — Spirit Gate",
        "Shenmen (HT7) is at the ulnar end of the transverse wrist crease. The yuan (source) point of the Heart meridian and the premier point for calming the spirit. It nourishes the heart, settles anxiety, and promotes restful sleep.",
        "acupressure", "Upper Limb Acupoints", ["upper limb", "calming", "sleep", "Shenmen"], season=None,
        location="At the ulnar end of the transverse crease of the wrist, in the depression on the radial side of the flexor carpi ulnaris tendon", method="Gentle, sustained thumb pressure", effect="Calms the spirit, improves sleep, relieves palpitations and anxiety", duration="3-5 minutes"),
    _se("seed_en_acupressure_010", "Lieque LU7 — Broken Sequence",
        "Lieque (LU7) is on the radial aspect of the forearm, 1.5 cun above the wrist crease. The luo-connecting point of the Lung meridian and one of the Four Command Points — 'Head and neck, select Lieque.' It vents the lungs, regulates qi, and treats coughs and headaches.",
        "acupressure", "Upper Limb Acupoints", ["upper limb", "lung", "pain relief", "Lieque"], season=None,
        location="On the radial aspect of the forearm, 1.5 cun proximal to the wrist crease, superior to the styloid process of the radius", method="Thumb press with up-and-down stroking", effect="Vents the lungs, relieves coughing, treats headaches and neck stiffness", duration="3-5 minutes"),

    # ----- Lower Limb Acupoints (5) -----
    _se("seed_en_acupressure_011", "Zusanli ST36 — Leg Three Miles",
        "Zusanli (ST36) is on the lateral aspect of the lower leg, 3 cun below the kneecap. The he (sea) point of the Stomach meridian and arguably the most important wellness point in all of Chinese medicine. It harmonizes the stomach, strengthens the spleen, boosts immunity, and promotes longevity. Moxibustion here is a daily wellness ritual.",
        "acupressure", "Lower Limb Acupoints", ["lower limb", "spleen", "immunity", "Zusanli"], season=None,
        location="3 cun below Dubi (ST35), one finger-width lateral to the anterior border of the tibia", method="Thumb press or moxibustion with moderate pressure", effect="Harmonizes stomach and spleen, strengthens immunity, promotes longevity", duration="5-10 minutes"),
    _se("seed_en_acupressure_012", "Sanyinjiao SP6 — Three Yin Intersection",
        "Sanyinjiao (SP6) is on the medial aspect of the lower leg, 3 cun above the medial malleolus. The convergence point of the Spleen, Liver, and Kidney meridians. It tonifies the spleen, nourishes blood, and regulates menstruation. A foundational point for women's health.",
        "acupressure", "Lower Limb Acupoints", ["lower limb", "menstrual", "kidney", "Sanyinjiao"], season=None,
        location="3 cun directly above the tip of the medial malleolus, posterior to the medial border of the tibia", method="Thumb press coordinated with deep breathing", effect="Tonifies spleen and blood, regulates liver and kidneys, treats gynecological disorders", duration="3-5 minutes"),
    _se("seed_en_acupressure_013", "Taichong LV3 — Great Rushing",
        "Taichong (LV3) is on the dorsum of the foot, in the depression proximal to the 1st and 2nd metatarsal bones. The yuan (source) point of the Liver meridian. Known as the 'anger-release point,' it pacifies liver yang, clears damp-heat, and soothes frustration.",
        "acupressure", "Lower Limb Acupoints", ["lower limb", "liver", "blood pressure", "Taichong"], season=None,
        location="On the dorsum of the foot, in the depression distal to the junction of the 1st and 2nd metatarsal bones", method="Thumb pressure, gradually increasing from light to firm", effect="Pacifies liver yang, lowers blood pressure, relieves frustration and headaches", duration="3-5 minutes"),
    _se("seed_en_acupressure_014", "Yongquan KI1 — Bubbling Spring",
        "Yongquan (KI1) is on the sole of the foot, in the depression when the toes are curled. The jing-well point of the Kidney meridian and the lowest point on the body. Massaging here draws excess fire downward, anchors the spirit, and promotes deep sleep. A cornerstone of evening wellness routines.",
        "acupressure", "Lower Limb Acupoints", ["lower limb", "kidney", "sleep", "Yongquan"], season=None,
        location="On the sole, in the depression appearing at the anterior third of the plantar surface when the foot is plantar-flexed", method="Thumb press or rubbing the sole of the foot", effect="Nourishes kidney yin, calms the spirit, anchors ascending fire, promotes sleep", duration="5-10 minutes"),
    _se("seed_en_acupressure_015", "Taixi KI3 — Great Stream",
        "Taixi (KI3) is in the depression between the medial malleolus and the Achilles tendon. The yuan (source) point of the Kidney meridian. It tonifies kidney yin, benefits the kidneys, and grasps qi. Essential for lower back pain, tinnitus, and chronic fatigue.",
        "acupressure", "Lower Limb Acupoints", ["lower limb", "kidney", "yin", "Taixi"], season=None,
        location="In the depression between the medial malleolus and the Achilles tendon", method="Thumb press, enhanced with moxibustion", effect="Nourishes kidney yin, strengthens the lower back, alleviates tinnitus and fatigue", duration="3-5 minutes"),

    # ----- Back Acupoints (5) -----
    _se("seed_en_acupressure_016", "Mingmen DU4 — Life Gate",
        "Mingmen (DU4) is on the midline of the back, below the spinous process of the 2nd lumbar vertebra. Known as the 'Gate of Life,' it is the seat of original yang. Moxibustion here warms the kidneys, strengthens the lower back, and ignites the body's vital fire.",
        "acupressure", "Back Acupoints", ["back", "kidney", "yang", "Mingmen"], season=None,
        location="On the posterior midline, in the depression below the spinous process of L2", method="Rub palms together until warm, then rub the point, or use moxibustion", effect="Warms kidney yang, strengthens the lower back, treats cold lumbar pain", duration="5-10 minutes"),
    _se("seed_en_acupressure_017", "Shenshu BL23 — Kidney Shu",
        "Shenshu (BL23) is 1.5 cun lateral to the lower border of the 2nd lumbar spinous process. The back-shu point of the Kidneys. It tonifies kidney essence, warms kidney yang, and nourishes the lumbar region. Combined with Mingmen, it forms the core of kidney-strengthening protocols.",
        "acupressure", "Back Acupoints", ["back", "kidney", "essence", "Shenshu"], season=None,
        location="1.5 cun lateral to the midpoint of the lower border of the spinous process of L2", method="Press with both fists or use moxibustion", effect="Tonifies kidney essence, strengthens the lower back, treats lumbar pain", duration="5-10 minutes"),
    _se("seed_en_acupressure_018", "Ganshu BL18 — Liver Shu",
        "Ganshu (BL18) is 1.5 cun lateral to the 9th thoracic spinous process. The back-shu point of the Liver. It smooths liver qi, drains damp-heat, and nourishes liver blood. Essential for rib pain, eye problems, and emotional regulation.",
        "acupressure", "Back Acupoints", ["back", "liver", "gallbladder", "Ganshu"], season=None,
        location="1.5 cun lateral to the lower border of the spinous process of T9", method="Thumb press or tapping, coordinated with deep breathing", effect="Soothes the liver, nourishes blood, brightens the eyes, relieves rib pain", duration="3-5 minutes"),
    _se("seed_en_acupressure_019", "Feishu BL13 — Lung Shu",
        "Feishu (BL13) is 1.5 cun lateral to the 3rd thoracic spinous process. The back-shu point of the Lungs. It vents the lungs, calms wheezing, and strengthens the defensive qi. Key for coughs, asthma, and skin conditions.",
        "acupressure", "Back Acupoints", ["back", "lung", "wheezing", "Feishu"], season=None,
        location="1.5 cun lateral to the lower border of the spinous process of T3", method="Thumb press or moxibustion with gentle back patting", effect="Vents the lungs, strengthens defensive qi, treats cough and asthma", duration="3-5 minutes"),
    _se("seed_en_acupressure_020", "Pishu BL20 — Spleen Shu",
        "Pishu (BL20) is 1.5 cun lateral to the 11th thoracic spinous process. The back-shu point of the Spleen. It strengthens the spleen, transforms dampness, and regulates qi and blood. The foundation of digestive wellness protocols.",
        "acupressure", "Back Acupoints", ["back", "spleen", "dampness", "Pishu"], season=None,
        location="1.5 cun lateral to the lower border of the spinous process of T11", method="Palm root press or moxibustion", effect="Strengthens the spleen, resolves dampness, harmonizes digestion", duration="5-10 minutes"),

    # ========== Exercise (15 entries) ==========
    # ----- Traditional Exercises (5) -----
    _se("seed_en_exercise_001", "Ba Duan Jin — Eight Brocades",
        "Ba Duan Jin (Eight Brocades) is a classic qigong form consisting of eight gentle movements that harmonize the internal organs and open the meridians. Each posture targets a specific organ system. Just 15 minutes daily builds vitality, improves posture, and cultivates inner calm. Suitable for all fitness levels.",
        "exercise", "Traditional Exercises", ["traditional", "qigong", "wellness", "Ba Duan Jin"], season=None,
        benefits=["Harmonizes qi and blood", "Opens meridian pathways", "Builds core vitality"], difficulty="Easy", duration="15 minutes"),
    _se("seed_en_exercise_002", "Tai Chi Chuan",
        "Tai Chi embodies the philosophy of using softness to overcome hardness, merging movement and stillness. Its slow, flowing sequences harmonize yin and yang, improve cardiovascular health, and enhance balance. A daily 30-minute practice transforms both body and mind.",
        "exercise", "Traditional Exercises", ["traditional", "tai chi", "balance", "meditation in motion"], season=None,
        benefits=["Harmonizes qi and blood", "Balances yin and yang", "Enhances coordination and proprioception"], difficulty="Medium", duration="30 minutes"),
    _se("seed_en_exercise_003", "Wu Qin Xi — Five Animal Frolics",
        "Created by the legendary physician Hua Tuo, Wu Qin Xi mimics the movements of five animals: tiger, deer, bear, monkey, and bird. Each animal form strengthens specific organs and qualities — power (tiger), grace (deer), stability (bear), agility (monkey), and lightness (bird). 20 minutes daily.",
        "exercise", "Traditional Exercises", ["traditional", "animal mimicry", "organ strengthening", "Five Animals"], season=None,
        benefits=["Strengthens the five organs", "Improves joint mobility", "Boosts immunity"], difficulty="Medium", duration="20 minutes"),
    _se("seed_en_exercise_004", "Liu Zi Jue — Six Healing Sounds",
        "Liu Zi Jue uses six healing sounds — Xu, He, Hu, Si, Chui, and Xi — combined with specific postures and breathing patterns to cleanse and regulate the five zang organs and the triple burner. Each sound vibrates through its target organ. A gentle, deeply restorative 15-minute practice.",
        "exercise", "Traditional Exercises", ["traditional", "breathing", "sound healing", "Six Sounds"], season=None,
        benefits=["Regulates organ function", "Harmonizes internal qi", "Releases emotional stagnation"], difficulty="Easy", duration="15 minutes"),
    _se("seed_en_exercise_005", "Standing Meditation (Zhan Zhuang)",
        "Zhan Zhuang is the art of standing still — a powerful internal cultivation practice. By holding specific postures in relaxed stillness, you accumulate internal energy, strengthen bones and tendons, and develop a profound sense of centeredness. Start with 5 minutes and build to 30.",
        "exercise", "Traditional Exercises", ["traditional", "internal cultivation", "stillness", "standing meditation"], season=None,
        benefits=["Cultivates internal qi", "Strengthens bones and tendons", "Develops mental clarity and calm"], difficulty="Medium", duration="15-30 minutes"),

    # ----- Daily Exercise (5) -----
    _se("seed_en_exercise_006", "Mindful Walking",
        "Walking is the simplest and most accessible wellness practice. 'Walk a hundred steps after meals, live to be ninety-nine.' Regular walking aids digestion, elevates mood, and protects cardiovascular health. Aim for 30-60 minutes daily, preferably in nature.",
        "exercise", "Daily Exercise", ["daily", "aerobic", "accessible", "walking"], season=None,
        benefits=["Promotes digestion", "Lifts mood and reduces stress", "Protects heart health"], difficulty="Easy", duration="30-60 minutes"),
    _se("seed_en_exercise_007", "Gentle Jogging",
        "Jogging is a moderate-intensity aerobic exercise that strengthens the heart, burns fat, and boosts immunity. Aim for 3-5 sessions per week, 20-30 minutes each, keeping your heart rate between 120-140 bpm. Start slow and build gradually.",
        "exercise", "Daily Exercise", ["daily", "aerobic", "cardio", "jogging"], season=None,
        benefits=["Strengthens cardiovascular system", "Burns calories", "Enhances immune function"], difficulty="Medium", duration="20-30 minutes"),
    _se("seed_en_exercise_008", "Swimming",
        "Swimming is a full-body workout that builds cardiovascular fitness and muscular strength. The buoyancy of water reduces joint impact, making it ideal for all ages and fitness levels. 2-3 sessions per week, 30-45 minutes each.",
        "exercise", "Daily Exercise", ["daily", "full body", "low impact", "swimming"], season=None,
        benefits=["Builds cardiovascular endurance", "Strengthens muscles", "Protects joints"], difficulty="Medium", duration="30-45 minutes"),
    _se("seed_en_exercise_009", "Yoga & Stretching",
        "Yoga combines physical postures, breathwork, and meditation to enhance flexibility, relieve stress, and cultivate body awareness. From gentle yin yoga to dynamic vinyasa, there's a practice for every body. 3-5 sessions per week, 30-60 minutes each.",
        "exercise", "Daily Exercise", ["daily", "flexibility", "stress relief", "yoga"], season=None,
        benefits=["Increases flexibility", "Reduces stress and tension", "Harmonizes body and mind"], difficulty="Easy", duration="30-60 minutes"),
    _se("seed_en_exercise_010", "Office Micro-Exercises",
        "Prolonged sitting is the new smoking. Counteract desk-bound damage with these quick micro-exercises: neck rolls, shoulder shrugs, seated twists, and standing calf raises. Set a timer for every 60 minutes. Even 3 minutes makes a meaningful difference.",
        "exercise", "Daily Exercise", ["daily", "office", "desk", "micro-movement"], season=None,
        benefits=["Relieves neck and shoulder tension", "Prevents repetitive strain", "Boosts circulation and focus"], difficulty="Easy", duration="3-5 minutes"),

    # ----- Seasonal Exercise (5) -----
    _se("seed_en_exercise_011", "Spring Nature Walks",
        "As spring returns, step outside and let nature be your healer. Spring yang energy needs movement to flow freely. Walking in green spaces helps discharge stagnant liver qi, stretches the meridians, and lifts the spirit. The ancient classics advise: 'In spring, walk widely in the courtyard.'",
        "exercise", "Seasonal Exercise", ["spring", "outdoor", "nature", "spring walking"], season="spring",
        benefits=["Releases liver qi stagnation", "Stretches muscles and joints", "Uplifts mood and spirit"], difficulty="Easy", duration="30-60 minutes"),
    _se("seed_en_exercise_012", "Summer Swimming",
        "When summer heat peaks, swimming becomes the ultimate exercise. Water movements dissipate body heat, provide a full-body workout, and protect joints from impact. Choose morning or evening sessions to avoid peak UV. A cool, restorative practice.",
        "exercise", "Seasonal Exercise", ["summer", "cooling", "water", "summer swimming"], season="summer",
        benefits=["Cools the body", "Full-body conditioning", "Joint-friendly and refreshing"], difficulty="Medium", duration="30-45 minutes"),
    _se("seed_en_exercise_013", "Autumn Hiking",
        "The crisp, clear air of autumn is an open invitation to the mountains. The Yellow Emperor's Inner Classic advises: 'In autumn, retire early and rise with the rooster.' Hiking builds cardiovascular fitness, oxygenates the lungs, and steadies the emotions.",
        "exercise", "Seasonal Exercise", ["autumn", "hiking", "outdoor", "mountain"], season="autumn",
        benefits=["Builds cardiovascular endurance", "Clears the lungs with fresh air", "Calms the mind and elevates mood"], difficulty="Medium", duration="60-120 minutes"),
    _se("seed_en_exercise_014", "Winter Indoor Tai Chi",
        "Tai Chi is the perfect all-season exercise, but winter practice is especially valuable. In cold months, gentle internal movement generates warmth from within without excessive sweating. Practice near a window for natural light. 30 minutes of slow, mindful movement.",
        "exercise", "Seasonal Exercise", ["winter", "indoor", "warming", "winter tai chi"], season="winter",
        benefits=["Generates internal warmth", "Maintains flexibility", "Calms the winter mind"], difficulty="Medium", duration="30 minutes"),
    _se("seed_en_exercise_015", "Evening Stroll",
        "The kidney meridian is active from 5-7 PM. An evening walk during this window nourishes kidney essence and aids digestion after dinner. Wait 30 minutes after eating before walking. Keep the pace gentle and conversational.",
        "exercise", "Seasonal Exercise", ["all seasons", "evening", "gentle", "digestive walk"], season=None,
        benefits=["Nourishes kidney essence", "Aids post-meal digestion", "Releases the day's tension"], difficulty="Easy", duration="30 minutes"),

    # ========== Sleep Tips (10 entries) ==========
    # ----- Sleep Techniques (4) -----
    _se("seed_en_sleep_tip_001", "4-7-8 Breathing Technique",
        "Developed by Dr. Andrew Weil, the 4-7-8 technique activates the parasympathetic nervous system and slows the heart rate. Inhale through the nose for 4 counts, hold for 7, exhale through the mouth for 8. Repeat 4 cycles. Most people fall asleep before completing the fourth round.",
        "sleep_tip", "Sleep Techniques", ["sleep", "breathing", "relaxation", "technique"], season=None,
        method="Inhale 4 counts through nose → Hold 7 counts → Exhale 8 counts through mouth. Repeat 4 times.", effect="Activates parasympathetic nervous system, slows heart rate, induces sleep quickly", duration="About 2 minutes"),
    _se("seed_en_sleep_tip_002", "Progressive Muscle Relaxation",
        "Starting from your toes, systematically tense and then release each muscle group, working upward to your head. Hold each tension for 5 seconds, then release for 10 seconds. This technique dissolves physical tension patterns you may not even be aware of, paving the way for deep, restorative sleep.",
        "sleep_tip", "Sleep Techniques", ["sleep", "relaxation", "muscle", "technique"], season=None,
        method="From toes to head: tense each muscle group for 5 seconds, release for 10 seconds", effect="Releases accumulated physical tension, promotes whole-body relaxation for sleep", duration="15-20 minutes"),
    _se("seed_en_sleep_tip_003", "Body Scan Meditation",
        "Lie comfortably and slowly sweep your attention from the tips of your toes to the crown of your head, sensing each body part without judgment. Simply notice — warmth, tingling, tension, or nothing at all. This practice reduces mental chatter and gently guides the body toward sleep.",
        "sleep_tip", "Sleep Techniques", ["sleep", "meditation", "mindfulness", "body scan"], season=None,
        method="Close eyes and slowly move attention from toes to crown, noticing sensations without judgment", effect="Quiets mental noise, cultivates body awareness, naturally leads to sleep", duration="10-15 minutes"),
    _se("seed_en_sleep_tip_004", "Breath Counting Meditation",
        "Settle into a comfortable position and focus entirely on your breathing. With each exhale, silently count: one, two, three... up to ten, then start over. If your mind wanders (and it will), gently return to one. This simple practice anchors the wandering mind and reduces pre-sleep anxiety.",
        "sleep_tip", "Sleep Techniques", ["sleep", "breathing", "focus", "counting"], season=None,
        method="Close eyes, focus on breath. Count each exhale from 1 to 10, restart if distracted.", effect="Stabilizes attention, reduces racing thoughts, eases into sleep", duration="5-10 minutes"),

    # ----- Bedtime Habits (3) -----
    _se("seed_en_sleep_tip_005", "Warm Foot Soak",
        "Soaking your feet in warm water (40-45°C / 104-113°F) for 15-20 minutes before bed draws blood away from the overactive brain and into the feet, signaling the body to wind down. Adding mugwort (Artemisia) or safflower enhances circulation. One of the most time-tested sleep remedies in traditional medicine.",
        "sleep_tip", "Bedtime Habits", ["sleep", "foot soak", "warming", "habit"], season=None,
        method="Soak feet in 40-45°C water for 15-20 minutes. Add mugwort or safflower for extra effect.", effect="Draws blood downward, warms the whole body, relaxes the nervous system", duration="15-20 minutes", best_time="1 hour before bed"),
    _se("seed_en_sleep_tip_006", "Warm Milk Before Bed",
        "Milk contains tryptophan, an amino acid precursor to melatonin — the body's sleep hormone. A cup of warm milk one hour before bed soothes the stomach and supports your natural sleep cycle. A drizzle of honey makes it even more effective.",
        "sleep_tip", "Bedtime Habits", ["sleep", "milk", "nutrition", "habit"], season=None,
        method="Drink a cup of warm milk with a drizzle of honey 1 hour before bedtime.", effect="Provides tryptophan for melatonin production, soothes the stomach, supports sleep cycle", duration="Instant", best_time="1 hour before bed"),
    _se("seed_en_sleep_tip_007", "Digital Sunset",
        "Blue light from screens suppresses melatonin production by up to 50%. One hour before bed, put your phone, tablet, and computer away. Replace screen time with a physical book, gentle stretching, or a warm conversation. This single habit can transform your sleep quality within a week.",
        "sleep_tip", "Bedtime Habits", ["sleep", "screens", "blue light", "habit"], season=None,
        method="Turn off all screens 1 hour before bed. Replace with reading, gentle stretching, or soft music.", effect="Allows natural melatonin production, reduces mental stimulation, protects sleep quality", duration="Ongoing", best_time="1 hour before bed"),

    # ----- Sleep Environment (3) -----
    _se("seed_en_sleep_tip_008", "Optimal Bedroom Temperature",
        "Research consistently shows that the ideal bedroom temperature for sleep is between 60-68°F (15-20°C). Your body temperature naturally drops during sleep, and a cool room supports this process. Use breathable bedding and maintain humidity between 40-60%.",
        "sleep_tip", "Sleep Environment", ["sleep", "temperature", "environment", "comfort"], season=None,
        method="Set thermostat to 60-68°F. Use breathable, moisture-wicking bedding. Maintain 40-60% humidity.", effect="Supports natural body temperature drop, enhances sleep quality and duration", duration="Ongoing"),
    _se("seed_en_sleep_tip_009", "Complete Darkness",
        "Even small amounts of ambient light (a street lamp, a standby LED) can disrupt melatonin production and reduce sleep depth. Install blackout curtains, use a comfortable sleep mask, and cover or remove all light sources. The darker your sleep environment, the deeper your rest.",
        "sleep_tip", "Sleep Environment", ["sleep", "darkness", "melatonin", "environment"], season=None,
        method="Install blackout curtains or use a sleep mask. Remove or cover all light sources in the bedroom.", effect="Protects melatonin production, supports deep restorative sleep cycles", duration="Ongoing"),
    _se("seed_en_sleep_tip_010", "Pillow Height Matters",
        "The right pillow height is crucial for spinal alignment: about one fist height when sleeping on your back, one and a half fists when on your side. Too high strains the cervical spine; too low causes head congestion. Choose a pillow that maintains your neck's natural curve.",
        "sleep_tip", "Sleep Environment", ["sleep", "pillow", "cervical", "comfort"], season=None,
        method="Choose a pillow that's one fist high for back-sleeping, 1.5 fists for side-sleeping.", effect="Protects cervical spine alignment, reduces neck pain, improves sleep quality", duration="Ongoing"),

    # ========== Tea (15 entries) ==========
    # ----- Spring Tea (4) -----
    _se("seed_en_tea_001", "Chrysanthemum Goji Tea",
        "Chrysanthemum is slightly cold and disperses wind-heat while brightening the eyes. Combined with goji berries, this classic spring tea nourishes the liver and clears visual fatigue. Perfect for screen-weary eyes during the spring liver season. Steep 5g chrysanthemum with 10g goji in boiling water.",
        "tea", "Spring Tea", ["spring", "liver", "vision", "chrysanthemum"], season="spring",
        ingredients=["5g chrysanthemum", "10g goji berries", "rock sugar to taste"],
        steps=["Place chrysanthemum and goji in a cup", "Pour boiling water and steep 5 minutes", "Add sugar to taste"],
        method="Steep in boiling water for 5 minutes", difficulty="Easy", duration="5 minutes"),
    _se("seed_en_tea_002", "Jasmine Green Tea",
        "Jasmine flowers are warming and regulate qi while lifting the spirit. Paired with green tea, this fragrant spring brew opens the liver, relieves stagnation, and refreshes the mind. The aroma alone is therapeutic. Steep 3g jasmine with 2g green tea.",
        "tea", "Spring Tea", ["spring", "liver", "mood", "jasmine"], season="spring",
        ingredients=["3g jasmine flowers", "2g green tea"],
        steps=["Combine jasmine and green tea in a cup", "Steep in boiling water for 5 minutes"],
        method="Steep in boiling water for 5 minutes", difficulty="Easy", duration="5 minutes"),
    _se("seed_en_tea_003", "Rose Petal Tea",
        "Rose is warming and gently moves qi while nourishing blood. This elegant spring tea soothes emotional tension, supports healthy circulation, and brings a sense of calm beauty. Especially beneficial for women. Steep 5 dried rosebuds in boiling water.",
        "tea", "Spring Tea", ["spring", "qi", "blood", "rose"], season="spring",
        ingredients=["5 dried rosebuds", "honey to taste"],
        steps=["Place rosebuds in a cup", "Steep in boiling water for 5 minutes", "Add honey to taste"],
        method="Steep in boiling water for 5 minutes", difficulty="Easy", duration="5 minutes"),
    _se("seed_en_tea_004", "Mint Refreshing Tea",
        "Mint is cooling and pungent, dispersing wind-heat and clearing the head. When spring brings stuffed noses or foggy thinking, a cup of fresh mint tea provides immediate clarity and relief. Use 5 fresh leaves with a touch of honey.",
        "tea", "Spring Tea", ["spring", "cooling", "refreshing", "mint"], season="spring",
        ingredients=["5 fresh mint leaves", "honey to taste"],
        steps=["Wash mint leaves and place in a cup", "Pour boiling water, steep 5 minutes", "Add honey to taste"],
        method="Steep in boiling water for 5 minutes", difficulty="Easy", duration="5 minutes"),

    # ----- Summer Tea (4) -----
    _se("seed_en_tea_005", "Green Tea",
        "Green tea is cooling and rich in catechins — powerful antioxidants that combat free radicals. Summer's perfect brew: it cools the body, sharpens focus, and supports metabolic health. Steep 3g leaves in 80°C (175°F) water for 2 minutes. Never use boiling water — it burns the leaves.",
        "tea", "Summer Tea", ["summer", "cooling", "antioxidant", "green tea"], season="summer",
        ingredients=["3g green tea leaves"],
        steps=["Heat water to 80°C (175°F)", "Pour over leaves and steep 2 minutes", "Can be re-steeped 2-3 times"],
        method="Steep at 80°C for 2 minutes", difficulty="Easy", duration="2 minutes"),
    _se("seed_en_tea_006", "Honeysuckle Cooling Tea",
        "Honeysuckle is cold and sweet, a natural antibiotic and anti-inflammatory. Summer honeysuckle tea clears heat-toxin, prevents colds, and soothes a scratchy throat. Steep 10g with a slice of ginger and a little licorice root for balance.",
        "tea", "Summer Tea", ["summer", "cooling", "antibacterial", "honeysuckle"], season="summer",
        ingredients=["10g honeysuckle", "3g licorice root", "rock sugar"],
        steps=["Rinse honeysuckle and licorice", "Steep in boiling water for 5 minutes", "Add sugar to taste"],
        method="Steep in boiling water for 5 minutes", difficulty="Easy", duration="5 minutes"),
    _se("seed_en_tea_007", "Sour Plum Drink (Suanmeitang)",
        "The iconic Chinese summer refresher. Dark plums are sour and astringent — they generate fluids and quench thirst like nothing else. Combined with hawthorn and licorice, this tangy, ruby-red drink is both delicious and deeply restorative. Simmer 30 minutes, serve chilled.",
        "tea", "Summer Tea", ["summer", "hydration", "traditional", "sour plum"], season="summer",
        ingredients=["30g dark plums", "20g hawthorn", "5g licorice root", "osmanthus flowers", "rock sugar"],
        steps=["Simmer plums, hawthorn, and licorice 30 minutes", "Strain, add sugar and osmanthus", "Serve over ice for maximum refreshment"],
        method="Simmer 30 minutes, serve chilled", difficulty="Easy", duration="30 minutes"),
    _se("seed_en_tea_008", "Mint Green Tea Cooler",
        "The ultimate summer cool-down: mint clears heat from the head, green tea delivers antioxidants and gentle caffeine. Together they create a refreshing, focused energy without the jitters. Steep 5 mint leaves with 3g green tea at 80°C for 3 minutes. Add honey and ice.",
        "tea", "Summer Tea", ["summer", "cooling", "refreshing", "mint green tea"], season="summer",
        ingredients=["5 fresh mint leaves", "3g green tea", "honey"],
        steps=["Combine mint and green tea in a cup", "Pour 80°C water, steep 3 minutes", "Add honey and ice"],
        method="Steep at 80°C for 3 minutes", difficulty="Easy", duration="3 minutes"),

    # ----- Autumn Tea (3) -----
    _se("seed_en_tea_009", "Tremella & Lily Bulb Tea",
        "Tremella mushroom nourishes yin and moistens the lungs; lily bulb calms the heart and soothes the mind. Together they form autumn's most elegant remedy for dry coughs, scratchy throats, and restless nights. Simmer 30 minutes with goji berries and rock sugar.",
        "tea", "Autumn Tea", ["autumn", "yin", "lung", "tremella lily"], season="autumn",
        ingredients=["10g tremella mushroom", "20g lily bulb", "10g goji berries", "rock sugar"],
        steps=["Soak and tear tremella into pieces", "Add lily bulb and goji berries", "Simmer 30 minutes", "Add sugar to taste"],
        method="Simmer 30 minutes", difficulty="Easy", duration="30 minutes"),
    _se("seed_en_tea_010", "Snow Pear & Honey Tea",
        "Snow pear clears lung heat and generates fluids; honey moistens dryness and soothes the throat. This warming autumn tea is the remedy of choice for dry coughs and autumn-induced throat irritation. Cube one pear, simmer 20 minutes with honey.",
        "tea", "Autumn Tea", ["autumn", "lung", "throat", "pear honey"], season="autumn",
        ingredients=["1 snow pear", "honey"],
        steps=["Peel and cube the pear", "Simmer in water for 20 minutes", "Stir in honey and serve warm"],
        method="Simmer 20 minutes", difficulty="Easy", duration="20 minutes"),
    _se("seed_en_tea_011", "Osmanthus Black Tea",
        "Osmanthus blossoms are warming and aromatic. They warm the lungs, transform phlegm, and dispel cold. Paired with black tea in autumn, this fragrant brew warms the body from within and lifts the spirit with its heavenly scent. Steep 3g dried osmanthus with 2g black tea.",
        "tea", "Autumn Tea", ["autumn", "warming", "aromatic", "osmanthus"], season="autumn",
        ingredients=["3g dried osmanthus", "2g black tea", "honey"],
        steps=["Combine osmanthus and black tea", "Steep in boiling water for 5 minutes", "Add honey to taste"],
        method="Steep in boiling water for 5 minutes", difficulty="Easy", duration="5 minutes"),

    # ----- Winter Tea (4) -----
    _se("seed_en_tea_012", "Red Date & Longan Tea",
        "Red dates tonify qi and nourish blood; longan berries warm the heart and spleen. This comforting winter brew restores warmth to cold hands and feet, calms the spirit, and supports restful sleep. Simmer 10 red dates with 10g longan for 10 minutes.",
        "tea", "Winter Tea", ["winter", "blood", "warming", "date longan"], season="winter",
        ingredients=["10 red dates", "10g dried longan", "brown sugar"],
        steps=["Wash dates and longan", "Simmer in water for 10 minutes", "Add brown sugar to taste"],
        method="Simmer 10 minutes", difficulty="Easy", duration="10 minutes"),
    _se("seed_en_tea_013", "Ginger & Date Warming Tea",
        "Ginger warms the middle and dispels cold; red dates tonify qi. This simple winter tea is your first line of defense against cold weather and the earliest signs of a cold. Simmer 3 slices of fresh ginger with 5 red dates for 10 minutes.",
        "tea", "Winter Tea", ["winter", "warming", "immune", "ginger date"], season="winter",
        ingredients=["3 slices fresh ginger", "5 red dates", "brown sugar"],
        steps=["Wash ginger and dates", "Simmer for 10 minutes", "Add brown sugar and serve warm"],
        method="Simmer 10 minutes", difficulty="Easy", duration="10 minutes"),
    _se("seed_en_tea_014", "Goji & Black Sesame Tea",
        "Goji berries nourish the liver and kidneys; black sesame seeds strengthen bones and promote lustrous hair. This nutty winter tonic supports the deepest layers of vitality. Toast 20g black sesame, grind, and mix with 15g goji in warm water.",
        "tea", "Winter Tea", ["winter", "kidney", "hair", "goji sesame"], season="winter",
        ingredients=["20g black sesame seeds", "15g goji berries", "honey"],
        steps=["Toast sesame seeds until fragrant", "Grind into a fine powder", "Mix with warm water and goji berries", "Add honey to taste"],
        method="Toast, grind, and mix with warm water", difficulty="Easy", duration="5 minutes"),
    _se("seed_en_tea_015", "Cinnamon & Walnut Warm Tonic",
        "Cinnamon warms and tonifies yang energy; walnuts nourish the kidneys and brain. This rich, warming winter beverage is like a hug in a mug. Grind 50g walnuts, simmer with milk, a cinnamon stick, and honey for 10 minutes. Pure winter comfort.",
        "tea", "Winter Tea", ["winter", "warming", "brain", "cinnamon walnut"], season="winter",
        ingredients=["50g walnut kernels", "200ml milk", "1 cinnamon stick", "honey"],
        steps=["Grind walnut kernels", "Simmer with milk and cinnamon for 10 minutes", "Strain and add honey to taste"],
        method="Simmer 10 minutes", difficulty="Easy", duration="10 minutes"),
]

SEED_SOLAR_TERMS = [
    ("st-001", "立春", "万物复苏，宜养肝护肝", "solar_term", "节气", '["立春", "春季"]'),
    ("st-002", "雨水", "春雨润物，宜祛湿健脾", "solar_term", "节气", '["雨水", "春季"]'),
    ("st-003", "惊蛰", "春雷惊醒，宜养心安神", "solar_term", "节气", '["惊蛰", "春季"]'),
    ("st-004", "春分", "阴阳平衡，宜调理气血", "solar_term", "节气", '["春分", "春季"]'),
    ("st-005", "清明", "气清景明，宜养肺润燥", "solar_term", "节气", '["清明", "春季"]'),
    ("st-006", "谷雨", "雨生百谷，宜健脾祛湿", "solar_term", "节气", '["谷雨", "春季"]'),
]

SEED_USER_SQL = """
INSERT OR IGNORE INTO users (id, name, email, password_hash, life_stage)
VALUES ('user-001', '演示用户', 'demo@shunshi.com', '', 'exploration');
"""


def init_db():
    """初始化数据库：建表 + 种子数据"""
    with _init_lock:
        conn = _get_connection()
        
        # 建表
        conn.executescript(SCHEMA_SQL)
        
        # 确保 season_tag 列存在（兼容旧数据库）
        try:
            conn.execute("ALTER TABLE contents ADD COLUMN season_tag TEXT")
        except sqlite3.OperationalError:
            pass  # 列已存在
        
        # 确保 locale 列存在（兼容旧数据库）
        try:
            conn.execute("ALTER TABLE contents ADD COLUMN locale TEXT DEFAULT 'zh-CN'")
        except sqlite3.OperationalError:
            pass  # 列已存在
        
        # 确保新增列存在（国际版 OAuth + Stripe 支持）
        for col_sql in [
            "ALTER TABLE users ADD COLUMN google_id TEXT UNIQUE",
            "ALTER TABLE users ADD COLUMN apple_id TEXT UNIQUE",
            "ALTER TABLE users ADD COLUMN apple_user_id TEXT",
            "ALTER TABLE users ADD COLUMN stripe_customer_id TEXT",
        ]:
            try:
                conn.execute(col_sql)
            except sqlite3.OperationalError:
                pass  # 列已存在
        conn.commit()
        
        # 确保索引存在
        try:
            conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_apple_id ON users(apple_id)")
            conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id)")
        except sqlite3.OperationalError:
            pass
        conn.commit()
        
        # 检查是否已有种子数据
        count = conn.execute("SELECT COUNT(*) FROM contents").fetchone()[0]
        if count == 0:
            for row in SEED_CONTENTS:
                conn.execute("""
                    INSERT OR IGNORE INTO contents
                    (id, title, description, type, category, tags,
                     difficulty, time, duration, ingredients, steps,
                     location, method, effect, benefits, best_time, season_tag, locale)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, row)
            
            for row in SEED_SOLAR_TERMS:
                conn.execute("""
                    INSERT OR IGNORE INTO contents (id, title, description, type, category, tags)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, row)
            
            # 英文种子数据
            for row in SEED_CONTENTS_EN:
                conn.execute("""
                    INSERT OR IGNORE INTO contents
                    (id, title, description, type, category, tags,
                     difficulty, time, duration, ingredients, steps,
                     location, method, effect, benefits, best_time, season_tag, locale)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, row)
            
            conn.executescript(SEED_USER_SQL)
            
            conn.commit()
            # 统计各类型数量
            types = conn.execute("SELECT type, COUNT(*) FROM contents GROUP BY type").fetchall()
            type_counts = ", ".join(f"{t[0]}:{t[1]}" for t in types)
            locales = conn.execute("SELECT locale, COUNT(*) FROM contents GROUP BY locale").fetchall()
            locale_counts = ", ".join(f"{l[0]}:{l[1]}" for l in locales)
            print(f"[DB] 种子数据已插入: {len(SEED_CONTENTS)}条中文 + {len(SEED_CONTENTS_EN)}条英文 + {len(SEED_SOLAR_TERMS)}条节气 + 1个用户")
            print(f"[DB] 类型分布: {type_counts}")
            print(f"[DB] 语言分布: {locale_counts}")
        else:
            print(f"[DB] 数据库已就绪，现有 {count} 条内容记录")


# ==================== 辅助函数 ====================

def row_to_dict(row: sqlite3.Row) -> dict:
    """将 Row 转为 dict"""
    return dict(row)


def rows_to_dicts(rows) -> list:
    """将多行 Row 转为 dict 列表"""
    return [dict(r) for r in rows]
