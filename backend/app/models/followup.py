"""
顺时 ShunShi - 跟进提醒模型
包含 1 张表: FollowUp
"""
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Integer, Text, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, IDMixin


# ==================== 枚举（内联常量，避免重复定义） ====================

# FollowUp 状态 / 优先级使用字符串常量


# ==================== 模型定义 ====================

class FollowUp(IDMixin, Base):
    """跟进提醒表（AI 主动关怀 / 用户定时提醒）"""
    __tablename__ = "sa_follow_ups"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    intent: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="意图（如 sleep_check/emotion_check/water_remind）"
    )
    content: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="提醒内容"
    )
    due_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="到期时间"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending",
        comment="状态: pending/sent/dismissed/completed"
    )
    priority: Mapped[str] = mapped_column(
        String(20), nullable=False, default="normal",
        comment="优先级: high/normal/low"
    )
    source: Mapped[str] = mapped_column(
        String(20), nullable=False, default="chat",
        comment="来源: chat/schedule/manual"
    )
    snooze_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="贪睡次数（默认 0）"
    )
    last_reminded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="最后提醒时间"
    )

    def __repr__(self) -> str:
        return f"<FollowUp user_id={self.user_id!r} intent={self.intent!r} status={self.status!r}>"
