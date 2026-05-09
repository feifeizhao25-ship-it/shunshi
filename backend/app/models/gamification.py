"""
顺时 ShunShi - 游戏化/成就/积分模型
Covers: badges, points, checkins, leaderboard
"""
from __future__ import annotations

import uuid
from datetime import datetime, date
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Date, TIMESTAMP,
    Text, JSON, UniqueConstraint
)
from app.db.types import GUID
from app.models.base import Base


class UserBadge(Base):
    """用户获得的徽章"""
    __tablename__ = "sa_user_badges"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    badge_id = Column(String(64), nullable=False)
    reason = Column(String(500))
    awarded_at = Column(TIMESTAMP, default=datetime.now)
    __table_args__ = (UniqueConstraint("user_id", "badge_id", name="uq_user_badge"),)


class UserPoints(Base):
    """用户积分与等级"""
    __tablename__ = "sa_user_points"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    total_points = Column(Integer, default=0)
    level = Column(Integer, default=1)
    title = Column(String(50), default="初学养生")
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class CheckinRecord(Base):
    """每日签到记录"""
    __tablename__ = "sa_checkin_records"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    checkin_date = Column(Date, nullable=False, default=date.today)
    consecutive_days = Column(Integer, default=1)
    points_earned = Column(Integer, default=10)
    created_at = Column(TIMESTAMP, default=datetime.now)
    __table_args__ = (UniqueConstraint("user_id", "checkin_date", name="uq_user_checkin"),)
