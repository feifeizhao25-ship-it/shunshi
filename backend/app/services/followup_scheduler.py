"""
顺时 - Follow-up 调度器
管理用户关怀跟进、签到提醒、情绪跟进等定时任务。

Follow-up 类型：
- daily_checkin: 每日签到提醒
- mood_followup: 情绪低落跟进
- sleep_followup: 睡眠质量跟进
- care_reminder: 关怀提醒
- subscription_expiring: 订阅到期提醒

注意：使用已有的follow_ups表，通过status字段管理调度状态。
status: pending -> scheduled -> sent / cancelled / expired

作者: Claw 🦅
日期: 2026-03-17
"""

import sqlite3
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List

from app.database.db import get_db

logger = logging.getLogger(__name__)


class FollowUpType:
    """Follow-up 类型常量"""
    DAILY_CHECKIN = "daily_checkin"
    MOOD_FOLLOWUP = "mood_followup"
    SLEEP_FOLLOWUP = "sleep_followup"
    CARE_REMINDER = "care_reminder"
    SUBSCRIPTION_EXPIRING = "subscription_expiring"


# 所有有效的 follow-up 类型
VALID_TYPES = [
    FollowUpType.DAILY_CHECKIN,
    FollowUpType.MOOD_FOLLOWUP,
    FollowUpType.SLEEP_FOLLOWUP,
    FollowUpType.CARE_REMINDER,
    FollowUpType.SUBSCRIPTION_EXPIRING,
]

# 类型描述
TYPE_DESCRIPTIONS = {
    FollowUpType.DAILY_CHECKIN: {
        "name": "每日签到提醒",
        "description": "每天提醒用户打卡记录今日状态",
        "default_content": "今天感觉怎么样？记得记录一下你的心情哦～",
    },
    FollowUpType.MOOD_FOLLOWUP: {
        "name": "情绪跟进",
        "description": "当用户情绪低落时，后续关怀跟进",
        "default_content": "最近心情好些了吗？有什么我能帮你的吗？",
    },
    FollowUpType.SLEEP_FOLLOWUP: {
        "name": "睡眠跟进",
        "description": "当用户睡眠质量不好时，后续关怀跟进",
        "default_content": "昨晚睡得怎么样？要不要试试助眠小技巧？",
    },
    FollowUpType.CARE_REMINDER: {
        "name": "关怀提醒",
        "description": "定期的关怀性提醒（如节气提醒、运动提醒）",
        "default_content": "记得照顾好自己哦！",
    },
    FollowUpType.SUBSCRIPTION_EXPIRING: {
        "name": "订阅到期提醒",
        "description": "用户订阅即将到期时提醒续费",
        "default_content": "您的订阅即将到期，续费可继续享受专属服务。",
    },
}

# 优先级配置
TYPE_PRIORITIES = {
    FollowUpType.MOOD_FOLLOWUP: "high",
    FollowUpType.SLEEP_FOLLOWUP: "high",
    FollowUpType.SUBSCRIPTION_EXPIRING: "high",
    FollowUpType.DAILY_CHECKIN: "normal",
    FollowUpType.CARE_REMINDER: "low",
}


class FollowUpScheduler:
    """Follow-up 调度器"""

    def _ensure_table(self):
        """确保follow_ups表和相关索引存在"""
        conn = get_db()
        try:
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_followups_status ON follow_ups(status)"
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_followups_scheduled ON follow_ups(scheduled_at)"
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_followups_user ON follow_ups(user_id, status)"
            )
            conn.commit()
        except Exception as e:
            logger.warning(f"创建索引失败（可能已存在）: {e}")

    def schedule_followup(
        self,
        user_id: str,
        followup_type: str,
        trigger_time: str,
        content: Optional[str] = None,
        title: Optional[str] = None,
        description: Optional[str] = None,
        conversation_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        创建一个 follow-up 调度任务

        Args:
            user_id: 用户ID
            followup_type: follow-up类型
            trigger_time: 触发时间 (ISO格式或 "HH:MM" 格式)
            content: 推送内容（可选，使用默认）
            title: 标题（可选）
            description: 描述（可选）
            conversation_id: 关联对话ID（可选）

        Returns:
            创建的 follow-up 记录
        """
        if followup_type not in VALID_TYPES:
            raise ValueError(
                f"无效的follow-up类型: {followup_type}，"
                f"有效类型: {VALID_TYPES}"
            )

        self._ensure_table()
        conn = get_db()

        # 解析触发时间
        if "T" in trigger_time or "-" in trigger_time:
            # ISO格式或日期格式，直接使用
            scheduled_at = trigger_time
        else:
            # "HH:MM" 格式，转换为今天的ISO时间
            try:
                hour, minute = map(int, trigger_time.split(":"))
                scheduled_at = datetime.now().replace(
                    hour=hour, minute=minute, second=0, microsecond=0
                ).isoformat()
            except (ValueError, IndexError):
                scheduled_at = trigger_time

        # 默认内容
        type_config = TYPE_DESCRIPTIONS.get(followup_type, {})
        if not content:
            content = type_config.get("default_content", "记得关注自己的健康哦～")
        if not title:
            title = type_config.get("name", "提醒")

        # 默认优先级
        priority = TYPE_PRIORITIES.get(followup_type, "normal")

        followup_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        conn.execute(
            """INSERT INTO follow_ups
               (id, user_id, conversation_id, title, description, type,
                status, priority, scheduled_at, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                followup_id, user_id, conversation_id, title,
                description or "", followup_type,
                "scheduled", priority, scheduled_at, now,
            ),
        )
        conn.commit()

        return self._get_followup_by_id(followup_id)

    def _get_followup_by_id(self, followup_id: str) -> Optional[Dict[str, Any]]:
        """根据ID获取follow-up"""
        conn = get_db()
        row = conn.execute(
            "SELECT * FROM follow_ups WHERE id = ?", (followup_id,)
        ).fetchone()
        if not row:
            return None
        return dict(row)

    def get_followup_list(
        self,
        user_id: Optional[str] = None,
        status: Optional[str] = None,
        followup_type: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """
        获取 follow-up 列表

        Args:
            user_id: 按用户过滤
            status: 按状态过滤
            followup_type: 按类型过滤
            limit: 返回数量限制

        Returns:
            follow-up 字典列表
        """
        conn = get_db()

        query = "SELECT * FROM follow_ups WHERE 1=1"
        params = []

        if user_id:
            query += " AND user_id = ?"
            params.append(user_id)
        if status:
            query += " AND status = ?"
            params.append(status)
        if followup_type:
            query += " AND type = ?"
            params.append(followup_type)

        query += " ORDER BY scheduled_at DESC LIMIT ?"
        params.append(limit)

        rows = conn.execute(query, params).fetchall()
        return [dict(r) for r in rows]

    def update_followup_status(
        self, followup_id: str, status: str
    ) -> Optional[Dict[str, Any]]:
        """
        更新 follow-up 状态

        Args:
            followup_id: follow-up ID
            status: 新状态 (scheduled/sent/cancelled/expired)

        Returns:
            更新后的记录
        """
        valid_statuses = ["scheduled", "sent", "cancelled", "expired", "pending"]
        if status not in valid_statuses:
            raise ValueError(f"无效的状态: {status}，有效值: {valid_statuses}")

        conn = get_db()

        if status == "sent":
            conn.execute(
                """UPDATE follow_ups
                   SET status = ?, completed_at = datetime('now')
                   WHERE id = ?""",
                (status, followup_id),
            )
        else:
            conn.execute(
                "UPDATE follow_ups SET status = ? WHERE id = ?",
                (status, followup_id),
            )
        conn.commit()

        return self._get_followup_by_id(followup_id)

    def cancel_followup(self, followup_id: str) -> bool:
        """
        取消 follow-up

        Args:
            followup_id: follow-up ID

        Returns:
            是否取消成功
        """
        conn = get_db()
        cursor = conn.execute(
            "UPDATE follow_ups SET status = 'cancelled' WHERE id = ? AND status != 'sent'",
            (followup_id,),
        )
        conn.commit()
        return cursor.rowcount > 0

    def check_due_followups(self) -> List[Dict[str, Any]]:
        """
        检查到期的 follow-up 任务

        返回所有已到 scheduled_at 时间且状态为 scheduled 的任务

        Returns:
            到期的 follow-up 列表
        """
        conn = get_db()
        now = datetime.now().isoformat()

        rows = conn.execute(
            """SELECT * FROM follow_ups
               WHERE status = 'scheduled' AND scheduled_at <= ?
               ORDER BY priority DESC, scheduled_at ASC""",
            (now,),
        ).fetchall()

        return [dict(r) for r in rows]

    def trigger_followup(self, followup_id: str) -> Dict[str, Any]:
        """
        执行 follow-up（标记为已发送）

        实际的推送逻辑（如APNs、WebSocket通知）由通知系统处理，
        这里只负责标记状态并返回任务详情供通知系统消费。

        Args:
            followup_id: follow-up ID

        Returns:
            包含发送详情的字典
        """
        conn = get_db()

        followup = self._get_followup_by_id(followup_id)
        if not followup:
            return {"success": False, "error": "follow-up not found"}

        if followup["status"] != "scheduled":
            return {
                "success": False,
                "error": f"follow-up status is '{followup['status']}', not 'scheduled'",
            }

        now = datetime.now().isoformat()

        # 标记为已发送
        conn.execute(
            """UPDATE follow_ups
               SET status = 'sent', completed_at = ?
               WHERE id = ?""",
            (now, followup_id),
        )
        conn.commit()

        return {
            "success": True,
            "followup_id": followup_id,
            "user_id": followup["user_id"],
            "type": followup["type"],
            "title": followup["title"],
            "description": followup["description"],
            "sent_at": now,
        }

    def check_and_trigger_due(self) -> List[Dict[str, Any]]:
        """
        检查到期任务并执行（批量处理）

        Returns:
            所有已触发的 follow-up 结果列表
        """
        due_followups = self.check_due_followups()
        results = []

        for fu in due_followups:
            result = self.trigger_followup(fu["id"])
            results.append(result)

        return results

    def create_daily_checkin(
        self, user_id: str, time: str = "20:00"
    ) -> Dict[str, Any]:
        """快捷创建每日签到提醒"""
        return self.schedule_followup(
            user_id=user_id,
            followup_type=FollowUpType.DAILY_CHECKIN,
            trigger_time=time,
            title="每日签到",
            content="今天过得怎么样？花一分钟记录一下心情吧～",
        )

    def create_mood_followup(
        self,
        user_id: str,
        trigger_hours: int = 24,
        conversation_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        快捷创建情绪跟进

        Args:
            user_id: 用户ID
            trigger_hours: 多少小时后触发（默认24小时）
            conversation_id: 关联对话ID
        """
        trigger_time = (
            datetime.now() + timedelta(hours=trigger_hours)
        ).isoformat()
        return self.schedule_followup(
            user_id=user_id,
            followup_type=FollowUpType.MOOD_FOLLOWUP,
            trigger_time=trigger_time,
            title="情绪跟进",
            content="最近感觉好些了吗？有什么想聊的都可以告诉我～",
            conversation_id=conversation_id,
        )

    def create_sleep_followup(
        self,
        user_id: str,
        trigger_hours: int = 12,
        conversation_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        快捷创建睡眠跟进

        Args:
            user_id: 用户ID
            trigger_hours: 多少小时后触发（默认12小时）
            conversation_id: 关联对话ID
        """
        trigger_time = (
            datetime.now() + timedelta(hours=trigger_hours)
        ).isoformat()
        return self.schedule_followup(
            user_id=user_id,
            followup_type=FollowUpType.SLEEP_FOLLOWUP,
            trigger_time=trigger_time,
            title="睡眠跟进",
            content="昨晚睡得好吗？要不要试试今天的助眠小技巧？",
            conversation_id=conversation_id,
        )

    def create_subscription_reminder(
        self, user_id: str, expires_at: str
    ) -> Dict[str, Any]:
        """
        创建订阅到期提醒（提前3天）

        Args:
            user_id: 用户ID
            expires_at: 订阅到期时间 (ISO格式)
        """
        try:
            expire_dt = datetime.fromisoformat(expires_at)
            remind_dt = expire_dt - timedelta(days=3)
            trigger_time = remind_dt.isoformat()
        except (ValueError, TypeError):
            trigger_time = expires_at

        return self.schedule_followup(
            user_id=user_id,
            followup_type=FollowUpType.SUBSCRIPTION_EXPIRING,
            trigger_time=trigger_time,
            title="订阅即将到期",
            content="您的顺时Pro订阅将于3天后到期，续费可继续享受专属养生服务。",
        )

    def get_stats(self, user_id: Optional[str] = None) -> Dict[str, Any]:
        """获取 follow-up 统计"""
        conn = get_db()

        if user_id:
            total = conn.execute(
                "SELECT COUNT(*) FROM follow_ups WHERE user_id = ?",
                (user_id,),
            ).fetchone()[0]
            by_status = {}
            for s in ["scheduled", "sent", "cancelled", "expired", "pending"]:
                count = conn.execute(
                    "SELECT COUNT(*) FROM follow_ups WHERE user_id = ? AND status = ?",
                    (user_id, s),
                ).fetchone()[0]
                by_status[s] = count
        else:
            total = conn.execute("SELECT COUNT(*) FROM follow_ups").fetchone()[0]
            by_status = {}
            for s in ["scheduled", "sent", "cancelled", "expired", "pending"]:
                count = conn.execute(
                    "SELECT COUNT(*) FROM follow_ups WHERE status = ?", (s,)
                ).fetchone()[0]
                by_status[s] = count

        return {
            "total": total,
            "by_status": by_status,
        }


# 全局实例
followup_scheduler = FollowUpScheduler()
