from __future__ import annotations

"""功法/运动模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class Exercise(Base):
    __tablename__ = "sa_exercises"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False)
    title_en = Column(String(200))
    category = Column(String(50), default="qigong")  # qigong / taichi / yoga / stretch / breath
    description = Column(Text)
    difficulty = Column(String(20), default="beginner")  # beginner / intermediate / advanced
    duration_min = Column(Integer, default=10)
    steps = Column(JSON, default=[])  # [{order, description, duration_sec}, ...]
    benefits = Column(JSON, default=[])  # 功效列表
    target_body_parts = Column(JSON, default=[])
    suitable_constitutions = Column(JSON, default=[])
    unsuitable_conditions = Column(JSON, default=[])
    season = Column(String(20), default="all")
    time_of_day = Column(String(50))
    equipment = Column(JSON, default=[])
    video_url = Column(String(500))
    thumbnail_url = Column(String(500))
    instructor = Column(String(100))
    calories_burned = Column(Integer)
    is_premium = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    view_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    status = Column(String(20), default="active")
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class ExerciseFavorite(Base):
    __tablename__ = "sa_exercise_favorites"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    exercise_id = Column(GUID(), nullable=False, index=True)
    created_at = Column(TIMESTAMP, default=datetime.now)


class ExerciseLog(Base):
    __tablename__ = "sa_exercise_logs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    exercise_id = Column(GUID(), nullable=False, index=True)
    duration_sec = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    mood_after = Column(String(20))
    note = Column(Text)
    date = Column(String(10), nullable=False)  # YYYY-MM-DD
    created_at = Column(TIMESTAMP, default=datetime.now)
