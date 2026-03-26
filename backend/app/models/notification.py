"""
顺时 ShunShi - 通知模型
包含 1 张表: Notification
"""
from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, IDMixin


# ==================== 模型定义 ====================

class Notification(IDMixin, Base):
    """通知表"""
    __tablename__ = "sa_notifications"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    type: Mapped[str] = mapped_column(
        String(30), nullable=False,
        comment="通知类型: solar_term/follow_up/sleep/water/exercise/family"
    )
    title: Mapped[str] = mapped_column(
        String(200), nullable=False, comment="通知标题"
    )
    body: Mapped[Optional[str]] = mapped_column(
        String(1000), nullable=True, comment="通知内容"
    )
    data: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="附加数据（JSON）"
    )
    sent_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="发送时间"
    )
    read_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="已读时间（可空，未读）"
    )
    channel: Mapped[str] = mapped_column(
        String(20), nullable=False, default="push",
        comment="通知渠道: push/local/in_app"
    )

    def __repr__(self) -> str:
        return f"<Notification user_id={self.user_id!r} type={self.type!r} title={self.title!r}>"
