from __future__ import annotations

"""穴位模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class Acupoint(Base):
    __tablename__ = "sa_acupoints"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    code = Column(String(20), unique=True, nullable=False, index=True)  # e.g. "LI4", "ST36"
    name = Column(String(100), nullable=False)
    name_en = Column(String(100))
    meridian = Column(String(50), nullable=False)  # 所属经络
    location = Column(Text, nullable=False)  # 定位方法
    location_image = Column(String(500))  # 定位图URL
    technique = Column(Text)  # 按压手法
    duration_sec = Column(Integer, default=180)  # 建议按压时长
    effect = Column(Text)  # 功效说明
    indications = Column(JSON, default=[])  # 适应症
    contraindications = Column(JSON, default=[])  # 禁忌
    suitable_constitutions = Column(JSON, default=[])
    season = Column(String(20), default="all")
    time_of_day = Column(String(50))  # 最佳按压时间
    video_url = Column(String(500))
    is_premium = Column(Boolean, default=False)
    view_count = Column(Integer, default=0)
    status = Column(String(20), default="active")
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class AcupointFavorite(Base):
    __tablename__ = "sa_acupoint_favorites"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    acupoint_id = Column(GUID(), nullable=False, index=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
