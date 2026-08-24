from __future__ import annotations

"""会员/权益模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class MembershipPlan(Base):
    __tablename__ = "sa_membership_plans"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    code = Column(String(50), unique=True, nullable=False)  # monthly / quarterly / yearly / lifetime
    name = Column(String(100), nullable=False)
    name_en = Column(String(100))
    description = Column(Text)
    price_cny = Column(Float, default=0)
    price_usd = Column(Float, default=0)
    duration_days = Column(Integer, default=30)
    features = Column(JSON, default=[])  # [{feature, included}, ...]
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class UserMembership(Base):
    __tablename__ = "sa_user_memberships"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    # Product tiers use stable string codes (free/basic/premium/family), not UUIDs.
    plan_id = Column(String(50), nullable=False, default="free")
    started_at = Column(TIMESTAMP, nullable=False, default=datetime.now)
    expires_at = Column(TIMESTAMP, nullable=True)
    auto_renew = Column(Boolean, default=False)
    payment_method = Column(String(50))  # alipay / wechat / stripe / apple / google
    transaction_id = Column(String(200))
    status = Column(String(20), default="active")  # active / expired / cancelled / pending
    cancelled_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class MembershipBenefitUsage(Base):
    __tablename__ = "sa_membership_benefit_usage"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    benefit_type = Column(String(50), nullable=False)  # ai_chat / content / expert_qa / live_class
    period = Column(String(10), nullable=False)  # YYYY-MM
    used_count = Column(Integer, default=0)
    limit_count = Column(Integer, default=0)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)
