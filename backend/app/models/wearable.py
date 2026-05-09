"""
顺时 ShunShi - 可穿戴设备数据模型
Covers: wearable sync records
"""
from __future__ import annotations

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, JSON, TIMESTAMP, Date, Text
from app.db.types import GUID
from app.models.base import Base


class WearableSync(Base):
    """可穿戴设备数据同步记录"""
    __tablename__ = "sa_wearable_syncs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    device_id = Column(String(64))  # apple_watch, fitbit, xiaomi, etc
    device_type = Column(String(30))
    sync_date = Column(Date, nullable=False)
    steps = Column(Integer, default=0)
    heart_rate_avg = Column(Float)
    heart_rate_resting = Column(Float)
    sleep_hours = Column(Float)
    sleep_deep_hours = Column(Float)
    calories_burned = Column(Float, default=0)
    spo2_avg = Column(Float)
    stress_level = Column(Integer)
    raw_data = Column(JSON, default={})
    tcm_insights = Column(JSON, default=[])  # TCM中医分析结果
    synced_at = Column(TIMESTAMP, default=datetime.now)
    created_at = Column(TIMESTAMP, default=datetime.now)
