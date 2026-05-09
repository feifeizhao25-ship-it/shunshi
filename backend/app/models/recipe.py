from __future__ import annotations

"""食疗/食谱模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class Recipe(Base):
    __tablename__ = "sa_recipes"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False)
    title_en = Column(String(200))
    description = Column(Text)
    category = Column(String(50), default="general")  # tonic / medicinal / seasonal
    tags = Column(JSON, default=[])
    ingredients = Column(JSON, default=[])  # [{name, amount, unit}, ...]
    steps = Column(JSON, default=[])  # [{order, description, duration}, ...]
    nutrition = Column(JSON, default={})  # {calories, protein, fat, carbs}
    tcm_effect = Column(String(100))  # 中医功效，如 "滋阴润肺"
    suitable_constitutions = Column(JSON, default=[])
    unsuitable_constitutions = Column(JSON, default=[])
    season = Column(String(20))  # spring / summer / autumn / winter / all
    difficulty = Column(String(20), default="easy")  # easy / medium / hard
    prep_time_min = Column(Integer, default=0)
    cook_time_min = Column(Integer, default=0)
    servings = Column(Integer, default=1)
    image_url = Column(String(500))
    video_url = Column(String(500))
    author_id = Column(String(64))
    is_premium = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    view_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    status = Column(String(20), default="active")  # active / inactive / draft
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class RecipeFavorite(Base):
    __tablename__ = "sa_recipe_favorites"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    recipe_id = Column(GUID(), nullable=False, index=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
