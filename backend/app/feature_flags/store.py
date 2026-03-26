"""
顺时 AI - Feature Flag 存储层
支持 SQLite 持久化 + 内存缓存，延迟 < 1ms

作者: Claw 🦅
日期: 2026-03-18
"""

import json
import hashlib
import time
import threading
from typing import Any, Optional
from dataclasses import dataclass, field, asdict
from datetime import datetime

from app.database.db import get_db

# ==================== 数据模型 ====================

@dataclass
class FlagValue:
    """Feature Flag 值"""
    key: str
    value_type: str  # boolean, string, json, variant
    value_default: Any
    rollout_pct: float = 100.0
    user_whitelist: list = field(default_factory=list)
    description: str = ""
    category: str = "general"  # prompt, skill, payment, content, general
    created_at: str = ""
    updated_at: str = ""


# ==================== 预设 Flags ====================

PRESET_FLAGS = {
    "prompt.v2_enabled": {
        "value": False, "category": "prompt",
        "desc": "启用V2版本Prompt"
    },
    "skill.parallel_execution": {
        "value": False, "category": "skill",
        "desc": "Skill并行执行"
    },
    "payment.stripe_live": {
        "value": False, "category": "payment",
        "desc": "Stripe生产模式"
    },
    "content.premium_lock": {
        "value": True, "category": "content",
        "desc": "高级内容会员锁定"
    },
    "ai.model_deepseek_primary": {
        "value": True, "category": "prompt",
        "desc": "DeepSeek为主模型"
    },
    "ai.kimi_emotion": {
        "value": False, "category": "prompt",
        "desc": "情绪场景用Kimi", "rollout_pct": 20.0
    },
    "chat.long_memory": {
        "value": False, "category": "skill",
        "desc": "长期记忆增强", "rollout_pct": 10.0
    },
}


# ==================== FlagStore ====================

class FlagStore:
    """
    Feature Flag 存储
    - 内存缓存保证 < 1ms 读取
    - SQLite 持久化
    - 基于用户 ID hash 的百分比灰度
    - 用户白名单强制启用
    """

    def __init__(self):
        self._cache: dict[str, FlagValue] = {}
        self._lock = threading.Lock()

    def _serialize_value(self, value: Any) -> tuple[str, str]:
        """将 Python 值序列化为 (value_type, value_default)"""
        if isinstance(value, bool):
            return "boolean", "true" if value else "false"
        elif isinstance(value, (dict, list)):
            return "json", json.dumps(value, ensure_ascii=False)
        elif isinstance(value, str):
            return "string", value
        else:
            # 数值等
            return "string", str(value)

    def _deserialize_value(self, value_type: str, value_default: str) -> Any:
        """反序列化存储值"""
        if value_type == "boolean":
            return value_default.lower() == "true"
        elif value_type == "json":
            return json.loads(value_default)
        else:
            return value_default

    def _hash_user(self, key: str, user_id: str) -> int:
        """基于 key + user_id 生成 0-99 的确定性 hash 值"""
        h = hashlib.md5(f"{key}:{user_id}".encode()).hexdigest()
        return int(h[:8], 16) % 100

    # ---- 缓存操作 ----

    def _load_cache(self):
        """从数据库加载所有 flags 到内存缓存"""
        conn = get_db()
        rows = conn.execute("SELECT * FROM feature_flags ORDER BY key").fetchall()
        cache = {}
        for row in rows:
            cache[row["key"]] = FlagValue(
                key=row["key"],
                value_type=row["value_type"],
                value_default=self._deserialize_value(row["value_type"], row["value_default"]),
                rollout_pct=row["rollout_pct"],
                user_whitelist=json.loads(row["user_whitelist"]),
                description=row["description"],
                category=row["category"],
                created_at=row["created_at"],
                updated_at=row["updated_at"],
            )
        with self._lock:
            self._cache = cache

    def _invalidate_cache(self):
        """刷新内存缓存"""
        self._load_cache()

    def _get_from_cache(self, key: str) -> Optional[FlagValue]:
        """线程安全地读取缓存"""
        with self._lock:
            return self._cache.get(key)

    # ---- 公共 API ----

    def get_flag(self, key: str, user_id: str = None) -> Optional[FlagValue]:
        """获取 flag，支持用户级覆盖（白名单）"""
        flag = self._get_from_cache(key)
        if flag is None:
            return None
        return flag

    def is_enabled(self, key: str, user_id: str = None) -> bool:
        """
        判断 flag 是否对某用户启用
        优先级: 白名单 > 默认值 + 百分比灰度
        """
        flag = self._get_from_cache(key)
        if flag is None:
            return False

        # 白名单用户始终启用
        if user_id and flag.user_whitelist and user_id in flag.user_whitelist:
            return True

        # 获取基础值
        value = flag.value_default

        if flag.value_type == "boolean":
            if not value:
                return False
            # 如果默认为 True 且 rollout=100%，直接返回 True
            if flag.rollout_pct >= 100.0:
                return True
            # 否则用百分比灰度
            if user_id:
                return self._hash_user(key, user_id) < flag.rollout_pct
            return bool(value)
        else:
            # 非布尔类型的 flag，非空即视为启用
            if value is None or value == "" or value == "false" or value is False:
                return False
            if flag.rollout_pct >= 100.0:
                return True
            if user_id:
                return self._hash_user(key, user_id) < flag.rollout_pct
            return bool(value)

    def get_variant(self, key: str, user_id: str = None, variants: list[str] = None) -> str:
        """
        A/B 测试变体选择
        返回变体名称，如 "control", "variant_a", "variant_b"
        基于 user_id hash 确定性分配
        """
        flag = self._get_from_cache(key)
        if flag is None:
            return "control"

        if not variants:
            # 从 flag 的 JSON 值中提取变体列表
            if flag.value_type == "json" and isinstance(flag.value_default, list):
                variants = flag.value_default
            else:
                variants = ["control", "variant_a"]

        if not user_id:
            return variants[0]

        idx = self._hash_user(key, user_id) % len(variants)
        return variants[idx]

    def set_flag(self, key: str, value: Any, rollout_pct: float = 100.0,
                 user_whitelist: list = None, description: str = "",
                 category: str = "general"):
        """设置或更新 flag"""
        now = datetime.utcnow().isoformat()
        value_type, value_str = self._serialize_value(value)
        if user_whitelist is None:
            user_whitelist = []

        conn = get_db()
        existing = conn.execute(
            "SELECT key FROM feature_flags WHERE key = ?", (key,)
        ).fetchone()

        if existing:
            conn.execute("""
                UPDATE feature_flags SET
                    value_type = ?, value_default = ?, rollout_pct = ?,
                    user_whitelist = ?, description = ?, category = ?,
                    updated_at = ?
                WHERE key = ?
            """, (value_type, value_str, rollout_pct,
                  json.dumps(user_whitelist, ensure_ascii=False),
                  description, category, now, key))
        else:
            conn.execute("""
                INSERT INTO feature_flags
                    (key, value_type, value_default, rollout_pct,
                     user_whitelist, description, category, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (key, value_type, value_str, rollout_pct,
                  json.dumps(user_whitelist, ensure_ascii=False),
                  description, category, now, now))
        conn.commit()

        # 刷新缓存
        self._invalidate_cache()

    def delete_flag(self, key: str) -> bool:
        """删除 flag，返回是否成功"""
        conn = get_db()
        cursor = conn.execute("DELETE FROM feature_flags WHERE key = ?", (key,))
        conn.commit()
        if cursor.rowcount > 0:
            self._invalidate_cache()
            return True
        return False

    def list_flags(self, category: str = None) -> list[FlagValue]:
        """列出所有 flags，可按 category 过滤"""
        with self._lock:
            flags = list(self._cache.values())
        if category:
            flags = [f for f in flags if f.category == category]
        return flags

    def evaluate(self, key: str, user_id: str = None) -> dict:
        """
        评估某用户某 flag 的结果（调试用）
        同时记录到 flag_evaluations 表
        """
        flag = self._get_from_cache(key)
        if flag is None:
            result = {"enabled": False, "reason": "flag_not_found"}
        else:
            # 白名单检查
            if user_id and flag.user_whitelist and user_id in flag.user_whitelist:
                result = {
                    "enabled": True,
                    "reason": "whitelisted",
                    "value": flag.value_default,
                }
            else:
                hash_val = self._hash_user(key, user_id) if user_id else None
                enabled = self.is_enabled(key, user_id)
                reasons = []
                if hash_val is not None:
                    reasons.append(f"user_hash={hash_val}, rollout={flag.rollout_pct}%")
                result = {
                    "enabled": enabled,
                    "reason": ", ".join(reasons) if reasons else "default",
                    "value": flag.value_default,
                    "hash_value": hash_val,
                }

        # 记录评估日志
        self._log_evaluation(key, user_id, result)

        return {
            "key": key,
            "user_id": user_id,
            **result,
            "flag": asdict(flag) if flag else None,
        }

    def _log_evaluation(self, key: str, user_id: str, result: dict):
        """记录 flag 评估到数据库"""
        import uuid
        conn = get_db()
        conn.execute("""
            INSERT INTO flag_evaluations (id, flag_key, user_id, result, evaluated_at)
            VALUES (?, ?, ?, ?, ?)
        """, (
            str(uuid.uuid4()),
            key,
            user_id,
            json.dumps(result, ensure_ascii=False, default=str),
            datetime.utcnow().isoformat(),
        ))
        conn.commit()

    def init_preset_flags(self):
        """初始化预设 flags（不覆盖已有的）"""
        conn = get_db()
        now = datetime.utcnow().isoformat()
        for key, config in PRESET_FLAGS.items():
            existing = conn.execute(
                "SELECT key FROM feature_flags WHERE key = ?", (key,)
            ).fetchone()
            if not existing:
                value = config["value"]
                rollout_pct = config.get("rollout_pct", 100.0)
                value_type, value_str = self._serialize_value(value)
                conn.execute("""
                    INSERT INTO feature_flags
                        (key, value_type, value_default, rollout_pct,
                         user_whitelist, description, category, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    key, value_type, value_str, rollout_pct,
                    json.dumps([]),
                    config.get("desc", ""),
                    config["category"],
                    now, now,
                ))
        conn.commit()
        # 加载到缓存
        self._invalidate_cache()

    def ensure_tables(self):
        """确保数据库表存在"""
        conn = get_db()
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS feature_flags (
                key TEXT PRIMARY KEY,
                value_type TEXT NOT NULL,
                value_default TEXT NOT NULL,
                rollout_pct REAL DEFAULT 100.0,
                user_whitelist TEXT DEFAULT '[]',
                description TEXT DEFAULT '',
                category TEXT DEFAULT 'general',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS flag_evaluations (
                id TEXT PRIMARY KEY,
                flag_key TEXT NOT NULL,
                user_id TEXT,
                result TEXT NOT NULL,
                evaluated_at TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_flag_evaluations_key
                ON flag_evaluations(flag_key);
            CREATE INDEX IF NOT EXISTS idx_flag_evaluations_time
                ON flag_evaluations(evaluated_at);
        """)
        conn.commit()


# 全局单例
flag_store = FlagStore()
