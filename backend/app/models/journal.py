from __future__ import annotations

"""日记/记录模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class JournalEntry(Base):
    __tablename__ = "sa_journal_entries"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    date = Column(String(10), nullable=False, index=True)  # YYYY-MM-DD
    mood = Column(String(20))  # happy / calm / tired / anxious / angry / sad
    mood_score = Column(Integer)  # 1-10
    energy_level = Column(Integer)  # 1-10
    sleep_quality = Column(Integer)  # 1-10
    body_condition = Column(JSON, default=[])  # ["neck_pain", "headache", ...]
    weather = Column(String(50))
    content = Column(Text)
    ai_insight = Column(Text)  # AI 生成的当日养生建议
    tags = Column(JSON, default=[])
    is_favorite = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class JournalPhoto(Base):
    __tablename__ = "sa_journal_photos"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    journal_id = Column(GUID(), nullable=False, index=True)
    photo_url = Column(String(500), nullable=False)
    caption = Column(String(200))
    created_at = Column(TIMESTAMP, default=datetime.now)
