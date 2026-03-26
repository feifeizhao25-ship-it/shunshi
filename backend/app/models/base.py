"""
顺时 ShunShi - 数据库模型基础层
SQLAlchemy 2.0 声明式基类 + 通用 Mixin
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, Boolean, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """所有模型的声明式基类"""
    pass


class TimestampMixin:
    """时间戳 Mixin：自动填充 created_at / updated_at"""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        comment="创建时间",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
        comment="更新时间",
    )


class SoftDeleteMixin(TimestampMixin):
    """软删除 Mixin：在 TimestampMixin 基础上增加 is_deleted"""

    is_deleted: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default="0",
        comment="是否已软删除",
    )


class IDMixin(SoftDeleteMixin):
    """ID + 时间戳 + 软删除 通用 Mixin
    - id: UUID 主键（字符串存储，兼容 SQLite）
    - created_at: 创建时间
    - updated_at: 更新时间
    - is_deleted: 软删除标记
    """

    id: Mapped[str] = mapped_column(
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        comment="UUID 主键",
    )
