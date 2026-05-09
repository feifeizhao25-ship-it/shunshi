from __future__ import annotations

"""聊天/消息模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class ChatMessage(Base):
    __tablename__ = "sa_chat_messages"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(String(64), nullable=False, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    role = Column(String(20), nullable=False)  # user / assistant / system
    content = Column(Text, nullable=False)
    content_type = Column(String(20), default="text")  # text / image / audio / rich
    message_metadata = Column(JSON, default={})  # {model, tokens, latency_ms, etc.}
    feedback = Column(String(20))  # thumbs_up / thumbs_down / null
    feedback_reason = Column(Text)
    is_pinned = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, default=datetime.now)


class ChatConversation(Base):
    __tablename__ = "sa_chat_conversations"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(String(64), unique=True, nullable=False, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), default="新对话")
    context = Column(JSON, default={})  # {topic, constitution_hint, season}
    message_count = Column(Integer, default=0)
    last_message_at = Column(TIMESTAMP)
    is_archived = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class ChatMemory(Base):
    __tablename__ = "sa_chat_memories"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    key = Column(String(100), nullable=False)
    value = Column(Text, nullable=False)
    category = Column(String(50), default="general")  # health / preference / habit / goal
    importance = Column(Integer, default=1)  # 1-5
    source_message_id = Column(String(64))
    expires_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)
