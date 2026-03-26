"""
顺时 AI LLM 调用审计模块
ShunShi AI LLM Call Audit

为每次 LLM 调用记录完整审计信息，持久化到 SQLite。
审计写入使用后台线程，不阻塞主请求。
每日用量统计使用内存缓存 + 每日重置。

不存储用户原始 prompt，只存 hash。

作者: Claw 🦅
日期: 2026-03-18
"""

import uuid
import hashlib
import json
import sqlite3
import threading
import time
import logging
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Optional, List, Dict, Any
from pydantic import BaseModel

from .budget import TOKEN_BUDGET, calculate_cost

logger = logging.getLogger(__name__)


# ==================== 数据模型 ====================

class LLMCallAudit(BaseModel):
    """每次 LLM 调用的审计记录"""
    call_id: str                    # UUID
    user_id: str
    request_id: str                 # 链路追踪 ID
    provider: str                   # siliconflow / openrouter
    model: str                      # deepseek-v3.2 / glm-4.6 等
    skill_chain: List[str] = []     # 使用的 Skill 列表
    prompt_hash: str                # Prompt 的 SHA256 hash（脱敏）
    prompt_version: str = ""        # Prompt 版本号
    tokens_in: int = 0
    tokens_out: int = 0
    latency_ms: int = 0
    cost_usd: float = 0.0           # 估算成本
    safety_flag: str = "none"       # none / sensitive / crisis
    route_decision: str = ""        # 为什么选这个模型
    response_status: str = "success"  # success / error / timeout
    error_message: Optional[str] = None
    created_at: Optional[datetime] = None
    def to_row(self) -> tuple:
        """转为数据库插入行"""
        created = self.created_at or datetime.now()
        return (
            self.call_id,
            self.user_id,
            self.request_id,
            self.provider,
            self.model,
            json.dumps(self.skill_chain, ensure_ascii=False),
            self.prompt_hash,
            self.prompt_version,
            self.tokens_in,
            self.tokens_out,
            self.latency_ms,
            self.cost_usd,
            self.safety_flag,
            self.route_decision,
            self.response_status,
            self.error_message,
            created.isoformat(),
        )


# ==================== 数据库建表 ====================

AUDIT_SCHEMA = """
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
"""


# ==================== 审计日志管理 ====================

class LLMAuditLogger:
    """
    LLM 调用审计日志管理

    - 审计写入通过后台线程执行，不阻塞主请求
    - 每日用量统计使用内存缓存，每天 UTC+8 00:00 重置
    """

    def __init__(self, db_path: str):
        self._db_path = db_path
        self._write_queue: List[tuple] = []
        self._queue_lock = threading.Lock()
        self._queue_event = threading.Event()
        self._shutdown = False

        # 每日用量缓存: {(user_id, date_str): {"tokens_in": ..., "tokens_out": ...}}
        self._daily_cache: Dict[str, Dict[str, int]] = {}
        self._cache_lock = threading.Lock()
        self._cache_date: str = ""  # 当前缓存的日期

        # 启动后台写入线程
        self._writer_thread = threading.Thread(
            target=self._write_loop, daemon=True, name="audit-writer"
        )
        self._writer_thread.start()

        # 初始化表
        self._init_table()

    def _init_table(self):
        """确保审计表存在"""
        conn = sqlite3.connect(self._db_path)
        conn.executescript(AUDIT_SCHEMA)
        conn.commit()
        conn.close()

    def _reset_daily_cache_if_needed(self):
        """如果日期变更，重置缓存"""
        today = date.today().isoformat()
        if self._cache_date != today:
            with self._cache_lock:
                if self._cache_date != today:
                    logger.info(f"[Audit] 每日缓存重置: {self._cache_date} → {today}")
                    self._daily_cache.clear()
                    self._cache_date = today

    # ==================== 核心方法 ====================

    @staticmethod
    def hash_prompt(prompt: str) -> str:
        """计算 prompt 的 SHA256 hash（脱敏）"""
        return hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:32]

    def log_call(self, audit: LLMCallAudit) -> None:
        """
        记录一次 LLM 调用（异步写入，不阻塞主请求）

        同时更新内存中的每日用量缓存。
        """
        # 写入队列
        with self._queue_lock:
            self._write_queue.append(("INSERT", audit.to_row()))
        self._queue_event.set()

        # 更新每日缓存
        today = date.today().isoformat()
        self._reset_daily_cache_if_needed()
        cache_key = f"{audit.user_id}:{today}"
        with self._cache_lock:
            if cache_key not in self._daily_cache:
                self._daily_cache[cache_key] = {"tokens_in": 0, "tokens_out": 0, "calls": 0}
            self._daily_cache[cache_key]["tokens_in"] += audit.tokens_in
            self._daily_cache[cache_key]["tokens_out"] += audit.tokens_out
            self._daily_cache[cache_key]["calls"] += 1

    def get_user_daily_usage(self, user_id: str, date_str: str = None) -> Dict[str, Any]:
        """
        获取用户每日 token 使用量

        优先从内存缓存读取，缓存不存在时查数据库。
        """
        if date_str is None:
            date_str = date.today().isoformat()

        cache_key = f"{user_id}:{date_str}"
        with self._cache_lock:
            cached = self._daily_cache.get(cache_key)
            if cached:
                return {
                    "user_id": user_id,
                    "date": date_str,
                    "tokens_in": cached["tokens_in"],
                    "tokens_out": cached["tokens_out"],
                    "total_tokens": cached["tokens_in"] + cached["tokens_out"],
                    "calls": cached["calls"],
                    "cost_usd": 0.0,  # 需要查 DB 才能精确计算
                    "source": "cache",
                }

        # 缓存不存在，查数据库
        day_start = f"{date_str}T00:00:00"
        day_end = f"{date_str}T23:59:59"

        try:
            conn = sqlite3.connect(self._db_path)
            conn.row_factory = sqlite3.Row
            row = conn.execute("""
                SELECT
                    user_id,
                    COALESCE(SUM(tokens_in), 0) as tokens_in,
                    COALESCE(SUM(tokens_out), 0) as tokens_out,
                    COALESCE(SUM(cost_usd), 0.0) as cost_usd,
                    COUNT(*) as calls
                FROM ai_audit_logs
                WHERE user_id = ? AND created_at >= ? AND created_at <= ?
                  AND response_status = 'success'
                GROUP BY user_id
            """, (user_id, day_start, day_end)).fetchone()
            conn.close()

            if row:
                return {
                    "user_id": user_id,
                    "date": date_str,
                    "tokens_in": row["tokens_in"],
                    "tokens_out": row["tokens_out"],
                    "total_tokens": row["tokens_in"] + row["tokens_out"],
                    "calls": row["calls"],
                    "cost_usd": row["cost_usd"],
                    "source": "database",
                }
        except Exception as e:
            logger.error(f"[Audit] 查询日用量失败: {e}")

        return {
            "user_id": user_id,
            "date": date_str,
            "tokens_in": 0,
            "tokens_out": 0,
            "total_tokens": 0,
            "calls": 0,
            "cost_usd": 0.0,
            "source": "none",
        }

    def check_budget(self, user_id: str, tier: str) -> Dict[str, Any]:
        """
        检查用户是否超出预算

        返回:
        {
            "within_budget": bool,
            "remaining_tokens": int,
            "daily_limit": int,
            "used_tokens": int,
            "fallback_model": str,
            "should_downgrade": bool,
        }
        """
        budget = TOKEN_BUDGET.get(tier, TOKEN_BUDGET["free"])
        daily_limit = budget["daily_tokens"]
        max_per_request = budget["max_per_request"]
        fallback_model = budget["fallback_model"]

        usage = self.get_user_daily_usage(user_id)
        used_tokens = usage["total_tokens"]

        within_budget = used_tokens < daily_limit
        should_downgrade = not within_budget or (used_tokens + max_per_request > daily_limit)
        remaining_tokens = max(0, daily_limit - used_tokens)

        return {
            "within_budget": within_budget,
            "remaining_tokens": remaining_tokens,
            "daily_limit": daily_limit,
            "used_tokens": used_tokens,
            "max_per_request": max_per_request,
            "fallback_model": fallback_model,
            "should_downgrade": should_downgrade,
        }

    def get_model_usage_stats(self, days: int = 7) -> List[Dict[str, Any]]:
        """
        获取模型使用统计（按天分组）

        Returns: [{date, model, calls, tokens_in, tokens_out, cost_usd, avg_latency_ms}, ...]
        """
        since = (date.today() - timedelta(days=days)).isoformat() + "T00:00:00"

        try:
            conn = sqlite3.connect(self._db_path)
            conn.row_factory = sqlite3.Row
            rows = conn.execute("""
                SELECT
                    DATE(created_at) as date,
                    model,
                    COUNT(*) as calls,
                    COALESCE(SUM(tokens_in), 0) as tokens_in,
                    COALESCE(SUM(tokens_out), 0) as tokens_out,
                    COALESCE(SUM(cost_usd), 0.0) as cost_usd,
                    COALESCE(AVG(latency_ms), 0) as avg_latency_ms
                FROM ai_audit_logs
                WHERE created_at >= ?
                GROUP BY DATE(created_at), model
                ORDER BY date DESC, calls DESC
            """, (since,)).fetchall()
            conn.close()

            return [dict(r) for r in rows]
        except Exception as e:
            logger.error(f"[Audit] 查询模型统计失败: {e}")
            return []

    def get_recent_calls(self, limit: int = 50, user_id: str = None) -> List[Dict[str, Any]]:
        """获取最近调用记录"""
        try:
            conn = sqlite3.connect(self._db_path)
            conn.row_factory = sqlite3.Row

            if user_id:
                rows = conn.execute("""
                    SELECT * FROM ai_audit_logs
                    WHERE user_id = ?
                    ORDER BY created_at DESC
                    LIMIT ?
                """, (user_id, limit)).fetchall()
            else:
                rows = conn.execute("""
                    SELECT * FROM ai_audit_logs
                    ORDER BY created_at DESC
                    LIMIT ?
                """, (limit,)).fetchall()

            conn.close()
            return [dict(r) for r in rows]
        except Exception as e:
            logger.error(f"[Audit] 查询最近调用失败: {e}")
            return []

    # ==================== 后台写入 ====================

    def _write_loop(self):
        """后台写入循环"""
        while not self._shutdown:
            self._queue_event.wait(timeout=1.0)
            self._queue_event.clear()

            if self._shutdown:
                break

            # 批量取出队列
            with self._queue_lock:
                batch = self._write_queue[:]
                self._write_queue.clear()

            if not batch:
                continue

            # 批量写入数据库
            try:
                conn = sqlite3.connect(self._db_path)
                for op, data in batch:
                    if op == "INSERT":
                        conn.execute("""
                            INSERT INTO ai_audit_logs
                            (id, user_id, request_id, provider, model, skill_chain,
                             prompt_hash, prompt_version, tokens_in, tokens_out,
                             latency_ms, cost_usd, safety_flag, route_decision,
                             response_status, error_message, created_at)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, data)
                conn.commit()
                conn.close()
                logger.debug(f"[Audit] 批量写入 {len(batch)} 条审计记录")
            except Exception as e:
                logger.error(f"[Audit] 批量写入失败: {e}, 丢失 {len(batch)} 条记录")
                # 将失败记录放回队列（最多重试一次）
                with self._queue_lock:
                    self._write_queue[:0] = batch

    def shutdown(self):
        """关闭审计日志，等待队列清空"""
        self._shutdown = True
        self._queue_event.set()
        self._writer_thread.join(timeout=5.0)


# ==================== 便捷函数 ====================

def create_audit(
    user_id: str,
    provider: str,
    model: str,
    prompt: str,
    tokens_in: int = 0,
    tokens_out: int = 0,
    latency_ms: int = 0,
    response_status: str = "success",
    error_message: Optional[str] = None,
    request_id: Optional[str] = None,
    skill_chain: Optional[List[str]] = None,
    prompt_version: str = "",
    safety_flag: str = "none",
    route_decision: str = "",
) -> LLMCallAudit:
    """
    快速创建审计记录

    自动生成 call_id, request_id, prompt_hash, cost_usd。
    """
    cost = calculate_cost(model, tokens_in, tokens_out)

    return LLMCallAudit(
        call_id=str(uuid.uuid4()),
        user_id=user_id,
        request_id=request_id or str(uuid.uuid4()),
        provider=provider,
        model=model,
        skill_chain=skill_chain or [],
        prompt_hash=LLMAuditLogger.hash_prompt(prompt),
        prompt_version=prompt_version,
        tokens_in=tokens_in,
        tokens_out=tokens_out,
        latency_ms=latency_ms,
        cost_usd=cost,
        safety_flag=safety_flag,
        route_decision=route_decision,
        response_status=response_status,
        error_message=error_message,
        created_at=datetime.now(),
    )


# ==================== 全局实例 ====================

_llm_audit_logger: Optional[LLMAuditLogger] = None


def get_llm_audit_logger() -> LLMAuditLogger:
    """获取全局 LLM 审计日志实例"""
    global _llm_audit_logger
    if _llm_audit_logger is None:
        from app.database.db import DB_PATH
        db_str = str(DB_PATH)
        _llm_audit_logger = LLMAuditLogger(db_str)
        logger.info(f"[Audit] LLM 审计日志初始化: {db_str}")
    return _llm_audit_logger


def init_llm_audit():
    """在应用启动时初始化 LLM 审计日志"""
    get_llm_audit_logger()
