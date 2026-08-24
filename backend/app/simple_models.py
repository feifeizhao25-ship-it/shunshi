"""Unambiguous SQLAlchemy models for the production API skeleton."""

from __future__ import annotations

import time
import uuid
from typing import Optional

from sqlalchemy import Boolean, Integer, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


def new_id() -> str:
    return uuid.uuid4().hex


def now_ts() -> int:
    return int(time.time())


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    phone: Mapped[Optional[str]] = mapped_column(String(16), unique=True, nullable=True)
    password_hash: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    nickname: Mapped[str] = mapped_column(String(64), default="顺时用户")
    is_guest: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class SmsCode(Base):
    __tablename__ = "sms_codes"
    phone: Mapped[str] = mapped_column(String(16), primary_key=True)
    code_hash: Mapped[str] = mapped_column(String(128))
    expires_at: Mapped[int] = mapped_column(Integer)
    attempts: Mapped[int] = mapped_column(Integer, default=0)


class UserSetting(Base):
    __tablename__ = "user_settings"
    user_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    key: Mapped[str] = mapped_column(String(64), primary_key=True)
    value: Mapped[str] = mapped_column(Text)


class Message(Base):
    __tablename__ = "messages"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    role: Mapped[str] = mapped_column(String(16))
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class Reflection(Base):
    __tablename__ = "reflections"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    mood: Mapped[str] = mapped_column(String(32), default="")
    question: Mapped[str] = mapped_column(Text, default="")
    notes: Mapped[str] = mapped_column(Text)
    recorded_at: Mapped[str] = mapped_column(String(64), default="")
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class Feedback(Base):
    __tablename__ = "feedback"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    kind: Mapped[str] = mapped_column(String(16), default="feedback")
    payload: Mapped[str] = mapped_column(Text)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class AudioProgress(Base):
    __tablename__ = "audio_progress"
    user_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    audio_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    progress_seconds: Mapped[int] = mapped_column(Integer, default=0)
    completed: Mapped[bool] = mapped_column(Boolean, default=False)
    updated_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class Entitlement(Base):
    __tablename__ = "entitlements"
    user_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    product_id: Mapped[str] = mapped_column(String(64))
    store: Mapped[str] = mapped_column(String(32), default="unknown")
    expires_at: Mapped[int] = mapped_column(Integer)
    original_transaction_id: Mapped[str] = mapped_column(String(128), unique=True)
    updated_at: Mapped[int] = mapped_column(Integer, default=now_ts)
