"""收藏（sa_favorites）。

``app/router/favorites.py`` 一直在读写 ``sa_favorites``，但仓库里从来没有这张表的模型或迁移：
全新数据库上 ``GET /api/v1/favorites`` 必然 500（``no such table: sa_favorites``，复测 B20）。
这里补上模型（随 ``create_all`` 建表）和迁移 ``20261101_favorites``（已有部署用 alembic 升级）。
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import TIMESTAMP, Column, String, UniqueConstraint

from app.db.types import GUID
from app.models.base import Base


class Favorite(Base):
    __tablename__ = "sa_favorites"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    content_id = Column(String(128), nullable=False)
    content_type = Column(String(50))
    created_at = Column(TIMESTAMP, default=datetime.now, nullable=False)
    __table_args__ = (UniqueConstraint("user_id", "content_id", name="uq_sa_favorites_user_content"),)
