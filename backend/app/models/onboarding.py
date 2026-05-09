"""
顺时 ShunShi - 入职引导模型
Covers: onboarding progress, user preferences from onboarding
"""
from __future__ import annotations

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, JSON, TIMESTAMP, Boolean
from app.db.types import GUID
from app.models.base import Base


class OnboardingProgress(Base):
    """用户入职引导进度"""
    __tablename__ = "sa_onboarding_progress"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    current_step = Column(Integer, default=0)
    total_steps = Column(Integer, default=5)
    completed = Column(Boolean, default=False)
    answers = Column(JSON, default={})  # 存储每步的回答
    constitution_result = Column(String(30))  # 最终体质判断结果
    completed_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)
