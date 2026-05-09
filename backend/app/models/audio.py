from __future__ import annotations

"""音频/冥想模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class AudioTrack(Base):
    __tablename__ = "sa_audio_tracks"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False)
    title_en = Column(String(200))
    description = Column(Text)
    category = Column(String(50), default="meditation")  # meditation / soundscape / story / guide
    tags = Column(JSON, default=[])
    duration_sec = Column(Integer, default=0)
    audio_url = Column(String(500), nullable=False)
    cover_image = Column(String(500))
    narrator = Column(String(100))
    tcm_concept = Column(String(100))  # 如 "养心", "疏肝"
    suitable_constitutions = Column(JSON, default=[])
    season = Column(String(20), default="all")
    time_of_day = Column(String(50))  # morning / noon / evening / night
    difficulty = Column(String(20), default="easy")  # easy / medium / hard
    is_premium = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    view_count = Column(Integer, default=0)
    play_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    status = Column(String(20), default="active")
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class AudioPlayHistory(Base):
    __tablename__ = "sa_audio_play_history"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    track_id = Column(GUID(), nullable=False, index=True)
    progress_sec = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    played_at = Column(TIMESTAMP, default=datetime.now)
