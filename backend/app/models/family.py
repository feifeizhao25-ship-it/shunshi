"""
顺时 ShunShi - 家庭关系模型
包含 1 张表: FamilyRelation
"""
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, IDMixin


# ==================== 模型定义 ====================

class FamilyRelation(IDMixin, Base):
    """家庭关系表（家庭成员绑定）"""
    __tablename__ = "sa_family_relations"

    inviter_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="邀请人 ID"
    )
    invitee_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="被邀请人 ID"
    )
    relation_type: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="关系类型: parent/spouse/child/guardian"
    )
    invite_code: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, comment="邀请码"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending",
        comment="状态: pending/active/inactive"
    )
    bound_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="绑定时间"
    )
    can_view_status: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否可查看健康状态（默认 True）"
    )
    permissions: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="权限配置（JSON）"
    )

    def __repr__(self) -> str:
        return f"<FamilyRelation inviter={self.inviter_id!r} invitee={self.invitee_id!r} type={self.relation_type!r}>"
