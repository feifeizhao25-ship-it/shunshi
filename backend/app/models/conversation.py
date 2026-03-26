"""
顺时 ShunShi - AI 对话相关模型
包含 3 张表: ConversationSession, ConversationMessage, CareStatus
"""
import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Integer, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, IDMixin


# ==================== 枚举定义 ====================

class SessionStatus(str, enum.Enum):
    """对话会话状态"""
    active = "active"
    archived = "archived"
    deleted = "deleted"


class MessageRole(str, enum.Enum):
    """消息角色"""
    user = "user"
    assistant = "assistant"
    system = "system"


class MessageType(str, enum.Enum):
    """消息类型"""
    text = "text"
    system_notice = "system_notice"
    content_card = "content_card"
    safe_mode_notice = "safe_mode_notice"
    follow_up_card = "follow_up_card"


class SafetyFlag(str, enum.Enum):
    """安全标记"""
    none = "none"
    medical = "medical"
    risk = "risk"
    crisis = "crisis"


class CareCurrentStatus(str, enum.Enum):
    """关怀状态"""
    stable = "stable"
    tired = "tired"
    needs_attention = "needs_attention"


class PresenceLevel(str, enum.Enum):
    """活跃程度"""
    present = "present"
    normal = "normal"
    retreating = "retreating"


class CareTrend(str, enum.Enum):
    """状态趋势"""
    improving = "improving"
    stable = "stable"
    declining = "declining"


# ==================== 模型定义 ====================

class ConversationSession(IDMixin, Base):
    """对话会话表"""
    __tablename__ = "sa_conversation_sessions"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    title: Mapped[Optional[str]] = mapped_column(
        String(200), nullable=True, comment="会话标题（可空，AI 生成）"
    )
    skill_chain: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="使用的 skill 链列表（JSON）"
    )
    model_used: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, comment="使用的模型名称"
    )
    message_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="消息数量"
    )
    last_message_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="最后消息时间"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=SessionStatus.active.value,
        comment="会话状态: active/archived/deleted"
    )

    # ---- 关系 ----
    messages: Mapped[list["ConversationMessage"]] = relationship(
        "ConversationMessage", back_populates="session", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<ConversationSession id={self.id!r} user_id={self.user_id!r}>"


class ConversationMessage(IDMixin, Base):
    """对话消息表"""
    __tablename__ = "sa_conversation_messages"

    session_id: Mapped[str] = mapped_column(
        ForeignKey("sa_conversation_sessions.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联会话 ID"
    )
    role: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="角色: user/assistant/system"
    )
    content: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="消息内容"
    )
    message_type: Mapped[str] = mapped_column(
        String(30), nullable=False, default=MessageType.text.value,
        comment="消息类型: text/system_notice/content_card/safe_mode_notice/follow_up_card"
    )
    content_cards: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="内容卡片数据（可空）"
    )
    safety_flag: Mapped[str] = mapped_column(
        String(20), nullable=False, default=SafetyFlag.none.value,
        comment="安全标记: none/medical/risk/crisis"
    )
    model_used: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, comment="使用的模型名称"
    )
    tokens_in: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="输入 token 数"
    )
    tokens_out: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="输出 token 数"
    )
    latency_ms: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="响应延迟（毫秒）"
    )

    # ---- 关系 ----
    session: Mapped["ConversationSession"] = relationship(
        "ConversationSession", back_populates="messages"
    )

    def __repr__(self) -> str:
        return f"<ConversationMessage id={self.id!r} role={self.role!r}>"


class CareStatus(IDMixin, Base):
    """用户关怀状态表（AI 对用户的综合判断）"""
    __tablename__ = "sa_care_status"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, unique=True, index=True, comment="关联用户 ID（唯一，一个用户一条记录）"
    )
    current_status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=CareCurrentStatus.stable.value,
        comment="当前状态: stable/tired/needs_attention"
    )
    presence_level: Mapped[str] = mapped_column(
        String(20), nullable=False, default=PresenceLevel.normal.value,
        comment="活跃程度: present/normal/retreating"
    )
    last_updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="最后更新时间"
    )
    trend: Mapped[str] = mapped_column(
        String(20), nullable=False, default=CareTrend.stable.value,
        comment="状态趋势: improving/stable/declining"
    )

    def __repr__(self) -> str:
        return f"<CareStatus user_id={self.user_id!r} status={self.current_status!r}>"
