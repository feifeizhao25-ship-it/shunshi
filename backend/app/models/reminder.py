from __future__ import annotations

"""提醒/闹钟模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class Reminder(Base):
    __tablename__ = "sa_reminders"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    reminder_type = Column(String(50), default="custom")  # water / medicine / sleep / exercise / tea / custom
    schedule_type = Column(String(20), default="daily")  # once / daily / weekly / monthly / shichen
    time = Column(String(5), nullable=False)  # HH:MM
    days = Column(JSON, default=[])  # ["mon", "tue", ...] for weekly
    shichen = Column(String(20))  # 时辰名称，如 "卯时"
    message = Column(Text)
    sound = Column(String(50), default="default")
    vibration = Column(Boolean, default=True)
    enabled = Column(Boolean, default=True)
    snooze_min = Column(Integer, default=5)
    related_content_id = Column(String(64))  # 关联的食谱/功法/茶饮ID
    last_triggered_at = Column(TIMESTAMP)
    trigger_count = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class ReminderLog(Base):
    __tablename__ = "sa_reminder_logs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    reminder_id = Column(GUID(), nullable=False, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    triggered_at = Column(TIMESTAMP, default=datetime.now)
    acknowledged_at = Column(TIMESTAMP)
    snoozed = Column(Boolean, default=False)
    skipped = Column(Boolean, default=False)
