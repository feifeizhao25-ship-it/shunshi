"""
告警日志存储 — SQLite 持久化

提供告警历史的记录、查询和统计功能。
"""

from __future__ import annotations

import json
import logging
import sqlite3
import uuid
from datetime import datetime, timezone
from typing import Optional, List

from app.alerts.sender import AlertEvent

logger = logging.getLogger(__name__)


class AlertStore:
    """告警历史存储"""

    def __init__(self):
        self._initialized = False

    def _get_db(self) -> sqlite3.Connection:
        from app.database.db import get_db
        return get_db()

    def init_tables(self):
        """初始化告警日志表"""
        if self._initialized:
            return
        try:
            db = self._get_db()
            db.executescript("""
                CREATE TABLE IF NOT EXISTS alert_logs (
                    id TEXT PRIMARY KEY,
                    alert_id TEXT NOT NULL,
                    level TEXT NOT NULL,
                    category TEXT NOT NULL,
                    title TEXT NOT NULL,
                    message TEXT DEFAULT '',
                    context TEXT DEFAULT '{}',
                    sent INTEGER DEFAULT 0,
                    channel TEXT DEFAULT '',
                    response TEXT DEFAULT '',
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_alert_level ON alert_logs(level);
                CREATE INDEX IF NOT EXISTS idx_alert_category ON alert_logs(category);
                CREATE INDEX IF NOT EXISTS idx_alert_created ON alert_logs(created_at);
            """)
            db.commit()
            self._initialized = True
            logger.info("[AlertStore] 告警日志表已就绪")
        except Exception as e:
            logger.error("[AlertStore] 初始化失败: %s", e)

    def record(
        self,
        event: AlertEvent,
        sent: bool,
        channel: str = "",
        response: str = "",
    ) -> str:
        """
        记录一条告警日志。

        Returns: 记录 ID
        """
        self.init_tables()
        try:
            db = self._get_db()
            log_id = f"alog_{uuid.uuid4().hex[:16]}"
            now = datetime.now(timezone.utc).isoformat()
            db.execute(
                """
                INSERT INTO alert_logs
                    (id, alert_id, level, category, title, message, context,
                     sent, channel, response, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    log_id,
                    event.alert_id,
                    event.level,
                    event.category,
                    event.title,
                    event.message,
                    json.dumps(event.context, ensure_ascii=False),
                    1 if sent else 0,
                    channel,
                    response[:500],
                    now,
                ),
            )
            db.commit()
            return log_id
        except Exception as e:
            logger.error("[AlertStore] 记录失败: %s", e)
            return ""

    def list_alerts(
        self,
        level: Optional[str] = None,
        category: Optional[str] = None,
        limit: int = 50,
    ) -> List[dict]:
        """查询告警历史"""
        self.init_tables()
        try:
            db = self._get_db()
            query = "SELECT * FROM alert_logs WHERE 1=1"
            params: list = []

            if level:
                query += " AND level = ?"
                params.append(level)
            if category:
                query += " AND category = ?"
                params.append(category)

            query += " ORDER BY created_at DESC LIMIT ?"
            params.append(limit)

            rows = db.execute(query, params).fetchall()
            return [
                {
                    "id": row["id"],
                    "alert_id": row["alert_id"],
                    "level": row["level"],
                    "category": row["category"],
                    "title": row["title"],
                    "message": row["message"],
                    "context": json.loads(row["context"]) if row["context"] else {},
                    "sent": bool(row["sent"]),
                    "channel": row["channel"],
                    "response": row["response"],
                    "created_at": row["created_at"],
                }
                for row in rows
            ]
        except Exception as e:
            logger.error("[AlertStore] 查询失败: %s", e)
            return []

    def get_stats(self) -> dict:
        """告警统计"""
        self.init_tables()
        try:
            db = self._get_db()
            total = db.execute("SELECT COUNT(*) as c FROM alert_logs").fetchone()["c"]
            total_sent = db.execute("SELECT COUNT(*) as c FROM alert_logs WHERE sent = 1").fetchone()["c"]
            total_failed = total - total_sent

            # 按级别统计
            level_rows = db.execute(
                "SELECT level, COUNT(*) as c FROM alert_logs GROUP BY level"
            ).fetchall()
            by_level = {row["level"]: row["c"] for row in level_rows}

            # 按类别统计
            cat_rows = db.execute(
                "SELECT category, COUNT(*) as c FROM alert_logs GROUP BY category"
            ).fetchall()
            by_category = {row["category"]: row["c"] for row in cat_rows}

            # 最近 24h 告警数
            recent = db.execute(
                "SELECT COUNT(*) as c FROM alert_logs WHERE created_at > datetime('now', '-1 day')"
            ).fetchone()["c"]

            return {
                "total": total,
                "sent": total_sent,
                "failed": total_failed,
                "last_24h": recent,
                "by_level": by_level,
                "by_category": by_category,
            }
        except Exception as e:
            logger.error("[AlertStore] 统计失败: %s", e)
            return {
                "total": 0, "sent": 0, "failed": 0,
                "last_24h": 0, "by_level": {}, "by_category": {},
            }


# ==================== 全局单例 ====================

alert_store = AlertStore()
