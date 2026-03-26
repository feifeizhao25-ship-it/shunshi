"""User models."""
from sqlalchemy import Column, String, Integer, SmallInteger, Boolean, Date, Time, TIMESTAMP, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db.database import Base


class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone = Column(String(20), unique=True)
    email = Column(String(255), unique=True)
    nickname = Column(String(50))
    avatar_url = Column(String(500))
    gender = Column(SmallInteger, default=0)
    birth_date = Column(Date)
    province = Column(String(50))
    city = Column(String(50))
    constitution_type = Column(String(20))
    constitution_tested_at = Column(TIMESTAMP)
    constitution_scores = Column(JSON, default={})
    membership_level = Column(SmallInteger, default=0)
    membership_expires_at = Column(TIMESTAMP)
    membership_auto_renew = Column(Boolean, default=False)
    consecutive_days = Column(Integer, default=0)
    total_points = Column(Integer, default=0)
    user_level = Column(SmallInteger, default=1)
    notification_enabled = Column(Boolean, default=True)
    notification_settings = Column(JSON, default={})
    preferred_wake_time = Column(Time, default="07:00")
    preferred_sleep_time = Column(Time, default="22:30")
    created_at = Column(TIMESTAMP, default=lambda: __import__("datetime").datetime.now())
    updated_at = Column(TIMESTAMP, default=lambda: datetime.datetime.now(), onupdate=lambda: datetime.datetime.now())
    last_login_at = Column(TIMESTAMP)
    is_active = Column(Boolean, default=True)
    is_deleted = Column(Boolean, default=False)


class UserAuth(Base):
    __tablename__ = "user_auth"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True))
    auth_type = Column(String(20), nullable=False)
    auth_identifier = Column(String(255), nullable=False)
    auth_credential = Column(Text)
    created_at = Column(TIMESTAMP, default=lambda: datetime.datetime.now())


class FamilyMember(Base):
    __tablename__ = "family_members"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id = Column(UUID(as_uuid=True))
    member_id = Column(UUID(as_uuid=True))
    relationship = Column(String(20))
    nickname = Column(String(50))
    created_at = Column(TIMESTAMP, default=lambda: datetime.datetime.now())


class UserDevice(Base):
    __tablename__ = "user_devices"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True))
    device_id = Column(String(255), nullable=False)
    device_type = Column(String(20))
    device_model = Column(String(100))
    push_token = Column(String(500))
    app_version = Column(String(20))
    os_version = Column(String(20))
    last_active_at = Column(TIMESTAMP, default=lambda: datetime.datetime.now())
    created_at = Column(TIMESTAMP, default=lambda: datetime.datetime.now())


import datetime
