"""
安全审计日志
Safety Audit Log — 每次安全事件记录到数据库

作者: Claw 🦅
日期: 2026-03-18
"""

import json
import uuid
import logging
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from app.database.db import get_db

logger = logging.getLogger(__name__)


class SafetyAuditLog:
    """安全审计日志"""

    TABLE = "safety_audit_logs"

    def __init__(self):
        self._ensure_table()

    def _ensure_table(self):
        """确保审计日志表存在"""
        try:
            db = get_db()
            db.execute(f"""
                CREATE TABLE IF NOT EXISTS {self.TABLE} (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    level TEXT NOT NULL,
                    content_hash TEXT,
                    detection_rules TEXT,
                    action_taken TEXT,
                    model_used TEXT,
                    latency_ms REAL,
                    created_at TEXT NOT NULL
                )
            """)
            db.execute(f"""
                CREATE INDEX IF NOT EXISTS idx_safety_audit_user
                ON {self.TABLE}(user_id)
            """)
            db.execute(f"""
                CREATE INDEX IF NOT EXISTS idx_safety_audit_type
                ON {self.TABLE}(event_type)
            """)
            db.execute(f"""
                CREATE INDEX IF NOT EXISTS idx_safety_audit_time
                ON {self.TABLE}(created_at)
            """)
            db.commit()
        except Exception as e:
            logger.error("[SafetyAuditLog] 建表失败: %s", e)

    def log(
        self,
        user_id: str,
        event_type: str,
        level: str,
        content_hash: str = "",
        detection_rules: Optional[List[str]] = None,
        action_taken: str = "",
        model_used: str = None,
        latency_ms: float = None,
    ):
        """记录一条安全审计日志"""
        try:
            db = get_db()
            db.execute(
                f"INSERT INTO {self.TABLE} "
                "(id, user_id, event_type, level, content_hash, "
                "detection_rules, action_taken, model_used, latency_ms, created_at) "
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    str(uuid.uuid4()),
                    user_id,
                    event_type,
                    level,
                    content_hash,
                    json.dumps(detection_rules or [], ensure_ascii=False),
                    action_taken,
                    model_used,
                    latency_ms,
                    datetime.now().isoformat(),
                ),
            )
            db.commit()
        except Exception as e:
            logger.error("[SafetyAuditLog] 写入日志失败: %s", e)

    def get_logs(
        self,
        user_id: Optional[str] = None,
        event_type: Optional[str] = None,
        level: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """查询审计日志"""
        try:
            db = get_db()
            conditions = []
            params = []

            if user_id:
                conditions.append("user_id = ?")
                params.append(user_id)
            if event_type:
                conditions.append("event_type = ?")
                params.append(event_type)
            if level:
                conditions.append("level = ?")
                params.append(level)

            where = ""
            if conditions:
                where = "WHERE " + " AND ".join(conditions)

            query = (
                f"SELECT * FROM {self.TABLE} {where} "
                "ORDER BY created_at DESC LIMIT ? OFFSET ?"
            )
            rows = db.execute(query, params + [limit, offset]).fetchall()

            results = []
            for row in rows:
                r = dict(row)
                if r.get("detection_rules"):
                    try:
                        r["detection_rules"] = json.loads(r["detection_rules"])
                    except (json.JSONDecodeError, TypeError):
                        pass
                results.append(r)

            return results

        except Exception as e:
            logger.error("[SafetyAuditLog] 查询日志失败: %s", e)
            return []

    def get_stats(self, days: int = 7) -> Dict[str, Any]:
        """获取安全统计信息"""
        try:
            db = get_db()
            since = datetime.now().isoformat()[:10]  # 简化：按天统计

            # 按级别统计
            level_stats = db.execute(
                f"SELECT level, COUNT(*) as count FROM {self.TABLE} "
                "GROUP BY level"
            ).fetchall()

            # 按事件类型统计
            event_stats = db.execute(
                f"SELECT event_type, COUNT(*) as count FROM {self.TABLE} "
                "GROUP BY event_type"
            ).fetchall()

            # 总数
            total = db.execute(
                f"SELECT COUNT(*) as count FROM {self.TABLE}"
            ).fetchone()["count"]

            # 危机事件数
            crisis_count = db.execute(
                f"SELECT COUNT(*) as count FROM {self.TABLE} WHERE level = 'crisis'"
            ).fetchone()["count"]

            return {
                "total_events": total,
                "crisis_events": crisis_count,
                "by_level": {row["level"]: row["count"] for row in level_stats},
                "by_event_type": {row["event_type"]: row["count"] for row in event_stats},
            }

        except Exception as e:
            logger.error("[SafetyAuditLog] 获取统计失败: %s", e)
            return {
                "total_events": 0,
                "crisis_events": 0,
                "by_level": {},
                "by_event_type": {},
            }
