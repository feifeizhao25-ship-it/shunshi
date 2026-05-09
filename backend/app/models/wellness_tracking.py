"""
顺时 — 健康追踪模型
Covers: water_tracker, menstrual, habit_builder, calorie_tracker,
        gratitude, weight_manage, dream_log, smart_alarm,
        community, expert_qa, feedback, coupon, gifting
"""
from __future__ import annotations

import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Date, TIMESTAMP,
    Text, JSON, ForeignKey, SmallInteger, BigInteger
)
from app.db.types import GUID
from sqlalchemy.orm import relationship
from app.models.base import Base


# ─────────────────────── Water Tracker ───────────────────────

class WaterLog(Base):
    __tablename__ = "sa_water_logs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    amount_ml = Column(Integer, nullable=False)
    type = Column(String(32), default="water")   # water / tea / juice …
    logged_at = Column(TIMESTAMP, default=datetime.now, nullable=False)
    date = Column(Date, nullable=False)


class WaterGoal(Base):
    __tablename__ = "sa_water_goals"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    goal_ml = Column(Integer, default=1700)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


# ─────────────────────── Menstrual ───────────────────────

class MenstrualCycle(Base):
    __tablename__ = "sa_menstrual_cycles"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date)
    cycle_length = Column(Integer, default=28)
    period_length = Column(Integer, default=5)
    flow_level = Column(String(16), default="normal")  # light / normal / heavy
    symptoms = Column(JSON, default=[])
    notes = Column(Text)
    logged_at = Column(TIMESTAMP, default=datetime.now)


class MenstrualSettings(Base):
    __tablename__ = "sa_menstrual_settings"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    avg_cycle_length = Column(Integer, default=28)
    avg_period_length = Column(Integer, default=5)
    reminder_enabled = Column(Boolean, default=True)
    reminder_days_before = Column(Integer, default=2)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


# ─────────────────────── Habit Builder ───────────────────────

class Habit(Base):
    __tablename__ = "sa_habits"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    category = Column(String(32))
    frequency = Column(String(16), default="daily")   # daily / weekly
    target_days = Column(Integer, default=21)
    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)
    total_checkins = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class HabitCheckin(Base):
    __tablename__ = "sa_habit_checkins"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    habit_id = Column(GUID(), ForeignKey("sa_habits.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String(64), nullable=False, index=True)
    check_date = Column(Date, nullable=False)
    note = Column(Text)
    logged_at = Column(TIMESTAMP, default=datetime.now)


# ─────────────────────── Calorie Tracker ───────────────────────

class MealLog(Base):
    __tablename__ = "sa_meal_logs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    meal_type = Column(String(16), nullable=False)   # breakfast / lunch / dinner / snack
    foods = Column(JSON, default=[])                  # [{food_id, amount_g, calories}, …]
    total_calories = Column(Float, default=0)
    total_protein_g = Column(Float, default=0)
    total_carbs_g = Column(Float, default=0)
    total_fat_g = Column(Float, default=0)
    date = Column(Date, nullable=False)
    logged_at = Column(TIMESTAMP, default=datetime.now)


class CalorieGoal(Base):
    __tablename__ = "sa_calorie_goals"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    daily_calories = Column(Integer, default=2000)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


# ─────────────────────── Gratitude Journal ───────────────────────

class GratitudeEntry(Base):
    __tablename__ = "sa_gratitude_entries"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    content = Column(Text, nullable=False)
    items = Column(JSON, default=[])
    mood = Column(String(16), default="neutral")
    date = Column(Date, nullable=False)
    logged_at = Column(TIMESTAMP, default=datetime.now)


# ─────────────────────── Weight Manager ───────────────────────

class WeightLog(Base):
    __tablename__ = "sa_weight_logs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    weight_kg = Column(Float, nullable=False)
    bmi = Column(Float)
    date = Column(Date, nullable=False)
    note = Column(Text)
    logged_at = Column(TIMESTAMP, default=datetime.now)


class WeightGoal(Base):
    __tablename__ = "sa_weight_goals"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    target_weight_kg = Column(Float)
    weeks = Column(Integer, default=12)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


# ─────────────────────── Dream Log ───────────────────────

class DreamLog(Base):
    __tablename__ = "sa_dream_logs"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    description = Column(Text, nullable=False)
    dream_quality = Column(String(32), default="vivid_dreams")
    emotions = Column(JSON, default=[])
    sleep_time = Column(String(5))
    wake_time = Column(String(5))
    body_symptoms = Column(JSON, default=[])
    tcm_analysis = Column(JSON)
    date = Column(Date, nullable=False)
    logged_at = Column(TIMESTAMP, default=datetime.now)


# ─────────────────────── Smart Alarm ───────────────────────

class SmartAlarm(Base):
    __tablename__ = "sa_smart_alarms"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    alarm_type = Column(String(32), nullable=False)
    time = Column(String(5), nullable=False)  # HH:MM
    days = Column(JSON, default=[])            # ["mon", "tue", …]
    sound = Column(String(64), default="morning_bell")
    enabled = Column(Boolean, default=True)
    shichen_aligned = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


# ─────────────────────── Community ───────────────────────

class CommunityPost(Base):
    __tablename__ = "sa_community_posts"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    content = Column(Text, nullable=False)
    category = Column(String(32), default="general")
    tags = Column(JSON, default=[])
    likes = Column(Integer, default=0)
    comment_count = Column(Integer, default=0)
    is_featured = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class CommunityComment(Base):
    __tablename__ = "sa_community_comments"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    post_id = Column(GUID(), ForeignKey("sa_community_posts.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String(64), nullable=False, index=True)
    content = Column(Text, nullable=False)
    likes = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, default=datetime.now)


# ─────────────────────── Expert Q&A ───────────────────────

class ExpertQuestion(Base):
    __tablename__ = "sa_expert_questions"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    question = Column(Text, nullable=False)
    category = Column(String(32), default="general")
    expert_id = Column(String(64))
    answer = Column(Text)
    answered_by = Column(String(64))
    status = Column(String(16), default="pending")  # pending / answered / closed
    created_at = Column(TIMESTAMP, default=datetime.now)
    answered_at = Column(TIMESTAMP)


# ─────────────────────── Feedback ───────────────────────

class UserFeedback(Base):
    __tablename__ = "sa_user_feedback"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    feedback_type = Column(String(32), nullable=False)  # bug / suggestion / complaint / praise
    title = Column(String(200))
    content = Column(Text, nullable=False)
    platform = Column(String(16))   # ios / android / web
    app_version = Column(String(16))
    status = Column(String(16), default="pending")  # pending / reviewing / resolved / closed
    admin_note = Column(Text)
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


# ─────────────────────── Coupon ───────────────────────

class Coupon(Base):
    __tablename__ = "sa_coupons"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    code = Column(String(16), nullable=False, unique=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    coupon_type = Column(String(32), nullable=False)
    value = Column(Float)           # discount amount or percentage
    is_redeemed = Column(Boolean, default=False)
    redeemed_at = Column(TIMESTAMP)
    expires_at = Column(TIMESTAMP)
    issued_at = Column(TIMESTAMP, default=datetime.now)


# ─────────────────────── Gifting ───────────────────────

class GiftOrder(Base):
    __tablename__ = "sa_gift_orders"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    buyer_id = Column(String(64), nullable=False, index=True)
    recipient_id = Column(String(64), index=True)
    product_id = Column(String(64), nullable=False)
    message = Column(Text)
    status = Column(String(16), default="pending")  # pending / sent / delivered
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class GiftCard(Base):
    __tablename__ = "sa_gift_cards"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    code = Column(String(16), nullable=False, unique=True, index=True)
    buyer_id = Column(String(64), nullable=False, index=True)
    denomination = Column(Float, nullable=False)
    message = Column(Text)
    is_redeemed = Column(Boolean, default=False)
    redeemed_by = Column(String(64))
    redeemed_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, default=datetime.now)


# ─────────────────────── Live Class Bookings ───────────────────────

class LiveClassBooking(Base):
    __tablename__ = "sa_live_class_bookings"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    class_id = Column(String(64), nullable=False, index=True)
    status = Column(String(16), default="booked")  # booked / attended / cancelled
    booked_at = Column(TIMESTAMP, default=datetime.now)
    attended_at = Column(TIMESTAMP)

