from __future__ import annotations

"""茶饮模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class Tea(Base):
    __tablename__ = "sa_teas"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    name_en = Column(String(100))
    category = Column(String(50), default="herbal")  # herbal / green / black / oolong / white
    description = Column(Text)
    ingredients = Column(JSON, default=[])  # [{name, amount, unit}, ...]
    brewing_method = Column(JSON, default={})  # {temp_c, time_sec, vessel}
    tcm_effect = Column(String(100))
    suitable_constitutions = Column(JSON, default=[])
    unsuitable_constitutions = Column(JSON, default=[])
    suitable_season = Column(String(20), default="all")
    suitable_time = Column(String(50))  # e.g. "morning", "afternoon"
    caffeine_level = Column(String(20), default="none")  # none / low / medium / high
    image_url = Column(String(500))
    is_premium = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    view_count = Column(Integer, default=0)
    status = Column(String(20), default="active")
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class TeaFavorite(Base):
    __tablename__ = "sa_tea_favorites"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    tea_id = Column(GUID(), nullable=False, index=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
